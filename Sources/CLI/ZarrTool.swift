//
//  ZarrTool.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//

import ArgumentParser
import Foundation
import SwiftZarr

@main
struct ZarrTool: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A comprehensive CLI for managing Zarr v3 data.",
        version: "0.1.0",
        subcommands: [
            CreateGroup.self,
            CreateArray.self,
            List.self,
            Info.self,
            ReadChunk.self,
            WriteChunk.self
        ],
        defaultSubcommand: List.self
    )
}

// MARK: - Helpers

extension ZarrDataType: ExpressibleByArgument {
    public init?(argument: String) {
        let json = "\"\(argument)\"".data(using: .utf8)!
        do {
            self = try JSONDecoder().decode(ZarrDataType.self, from: json)
        } catch {
            return nil
        }
    }
}

func getStore(for path: String) throws -> (ZarrStore, String) {
    let url = URL(fileURLWithPath: path)
    let store = try FilesystemStore(path: url)
    return (store, "")
}


// MARK: - Subcommands

struct CreateGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Create a new Zarr group.")
    
    @Argument(help: "Path to the new group")
    var path: String
    
    func run() async throws {
        let (store, internalPath) = try getStore(for: path)
        let metadata = ZarrGroupMetaData(attributes: nil)
        _ = try ZarrGroup.create(store: store, path: internalPath, metadata: metadata)
        print("✅ Created group at \(path)")
    }
}

struct CreateArray: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Create a new Zarr array.")
    
    @Argument(help: "Path to the new array")
    var path: String
    
    @Option(help: "Shape of the array (comma-separated, e.g. 100,100)")
    var shape: String
    
    @Option(help: "Chunk shape (comma-separated, e.g. 10,10)")
    var chunkShape: String
    
    @Option(help: "Data type (e.g. float32, int64)")
    var dtype: ZarrDataType
    
    @Option(help: "Fill value (default: null)")
    var fillValue: String?
    
    func run() async throws {
        let (store, internalPath) = try getStore(for: path)
        
        let shapeDims = shape.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        let chunkDims = chunkShape.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        guard shapeDims.count > 0, chunkDims.count == shapeDims.count else {
            print("❌ Error: Shape and chunk shape must have the same non-zero dimensionality.")
            return
        }
        
        // Parse fill value
        let fv: FillValue
        if let val = fillValue {
            if let f = Double(val) {
                fv = .float(f)
            } else if let i = Int64(val) {
                fv = .int(i)
            } else {
                fv = .null
            }
        } else {
            fv = .null
        }

        // Defaults for CLI
        let chunkGrid = ZarrChunkGrid.regular(chunkDims)
        let chunkKeyEncoding = ZarrChunkKeyEncoding.default(separator: "/")
        // Default codec: bytes (little endian)
        let bytesCodecConfig = ZarrCodecConfiguration(name: "bytes", configuration: ["endian": .string("little")])
        let codecs = [bytesCodecConfig]
        
        _ = try ZarrArray.create(
            store: store,
            path: internalPath,
            shape: shapeDims,
            dataType: dtype,
            chunkGrid: chunkGrid,
            chunkKeyEncoding: chunkKeyEncoding,
            fillValue: fv,
            codecs: codecs,
            attributes: nil,
            dimensionNames: nil
        )
        print("✅ Created array at \(path) with shape \(shapeDims) and type \(dtype)")
    }
}

struct List: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "List children of a Zarr group.")
    
    @Argument(help: "Path to the group")
    var path: String = "."
    
    func run() async throws {
        let (store, internalPath) = try getStore(for: path)
        // Try opening as group
        do {
            let group = try ZarrGroup.open(store: store, path: internalPath)
            let children = try group.listChildren()
            if children.isEmpty {
                print("(empty)")
            } else {
                for child in children {
                    print(child)
                }
            }
        } catch {
            print("❌ Failed to open group at \(path): \(error)")
        }
    }
}

struct Info: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Show metadata for a Zarr node.")
    
    @Argument(help: "Path to the node")
    var path: String
    
    func run() async throws {
        let (store, internalPath) = try getStore(for: path)
        
        // Try to open as array first, then group
        if let array = try? ZarrArray.open(store: store, path: internalPath) {
            print("📊 Array: \(path)") // internal name inaccessible
            print("  Shape: \(array.metadata.shape)")
            print("  Chunk Shape: \(array.metadata.chunkGrid.chunkShape)")
            print("  Data Type: \(array.metadata.dataType)")
            let codecNames = array.metadata.codecs.map { $0.name }.joined(separator: " -> ")
            print("  Compressor: \(codecNames)")
            if let attrs = array.metadata.attributes, !attrs.isEmpty {
                print("  Attributes: \(attrs)")
            }
        } else if let group = try? ZarrGroup.open(store: store, path: internalPath) {
            print("📁 Group: \(path)")
            if let attrs = group.metadata.attributes, !attrs.isEmpty {
                print("  Attributes: \(attrs)")
            }
            let children = try group.listChildren()
            print("  Children: \(children.count)")
        } else {
            print("❌ No Zarr node found at \(path)")
        }
    }
}

struct ReadChunk: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Read a chunk from a Zarr array.")
    
    @Argument(help: "Path to the array")
    var path: String
    
    @Option(help: "Chunk indices (comma-separated, e.g. 0,0)")
    var index: String
    
    func run() async throws {
        let (store, internalPath) = try getStore(for: path)
        let array = try ZarrArray.open(store: store, path: internalPath)
        
        let indices = index.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        guard indices.count == array.metadata.shape.count else {
            print("❌ Error: Index dimensionality (\(indices.count)) does not match array dimensionality (\(array.metadata.shape.count)).")
            return
        }
        
        switch array.metadata.dataType {
        case .float32:
            let data = try array.readChunk(at: indices, as: Float.self)
            print(data)
        case .float64:
            let data = try array.readChunk(at: indices, as: Double.self)
            print(data)
        case .int32:
            let data = try array.readChunk(at: indices, as: Int32.self)
            print(data)
        case .int64:
            let data = try array.readChunk(at: indices, as: Int64.self)
            print(data)
        // Boolean not yet supported in CLI read (implementation needed in library)
        default:
             print("⚠️ Viewing data for \(array.metadata.dataType) is not yet fully supported in CLI.")
        }
    }
}

struct WriteChunk: AsyncParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Write a filled chunk to a Zarr array.")
    
    @Argument(help: "Path to the array")
    var path: String
    
    @Option(help: "Chunk indices (comma-separated, e.g. 0,0)")
    var index: String
    
    @Option(help: "Value to fill the chunk with")
    var value: String
    
    func run() async throws {
        let (store, internalPath) = try getStore(for: path)
        let array = try ZarrArray.open(store: store, path: internalPath)
        
        let indices = index.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        
        guard indices.count == array.metadata.shape.count else {
            print("❌ Error: Index dimensionality (\(indices.count)) does not match array dimensionality (\(array.metadata.shape.count)).")
            return
        }
        
        let chunkShape = array.metadata.chunkGrid.chunkShape
        let count = chunkShape.reduce(1, *)
        
        switch array.metadata.dataType {
        case .float32:
            guard let v = Float(value) else { print("Invalid value"); return }
            let data: [Float] = Array(repeating: v, count: count)
            try array.writeChunk(at: indices, data: data)
        case .float64:
            guard let v = Double(value) else { print("Invalid value"); return }
            let data: [Double] = Array(repeating: v, count: count)
            try array.writeChunk(at: indices, data: data)
        case .int32:
            guard let v = Int32(value) else { print("Invalid value"); return }
            let data: [Int32] = Array(repeating: v, count: count)
            try array.writeChunk(at: indices, data: data)
        case .int64:
            guard let v = Int64(value) else { print("Invalid value"); return }
            let data: [Int64] = Array(repeating: v, count: count)
            try array.writeChunk(at: indices, data: data)
        default:
             print("⚠️ Writing data for \(array.metadata.dataType) is not yet fully supported in CLI.")
             return
        }
        
        print("✅ Written chunk at \(indices) with value \(value)")
    }
}
