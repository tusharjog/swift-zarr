//
//  ZarrArray.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/29/25.
//

import Foundation


//
// Data -> Codecs -> Storage Transfer -> Store
//
public class ZarrArray : ZarrNode {
    public func isGroup() -> Bool {
        return false
    }
    
    public func isArray() -> Bool {
        return true
    }
    
    public var path: String
    public var store: ZarrStore
    public var nodeType: ZarrNodeType
    public var metadata: ZarrArrayMetaData
    
    private init(store: ZarrStore, path: String, metadata: ZarrArrayMetaData) throws {
        self.path = path
        self.store = store
        self.metadata = metadata
        self.nodeType = .array
    }
    
    public static func create(store: ZarrStore, path: String, metadata: ZarrArrayMetaData) throws -> ZarrArray {
        let metadataKey = path.isEmpty ? DEFAULT_META_KEY : "\(path)/\(DEFAULT_META_KEY)"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if #available(macOS 10.15, iOS 13.0, *) {
            encoder.outputFormatting.insert(.withoutEscapingSlashes)
        }
        do {
            let jsondata = try encoder.encode(metadata)
            try store.set(key: metadataKey, value: jsondata)
        } catch {
            throw error
        }
        
        return try ZarrArray(store: store, path: path, metadata: metadata)
    }
    
    public static func create(store: ZarrStore, path: String,
                              shape: [Int], dataType: ZarrDataType, chunkGrid: ZarrChunkGrid, chunkKeyEncoding: ZarrChunkKeyEncoding, fillValue: FillValue, codecs: [ZarrCodecConfiguration], attributes: [String : JSONValue]?, dimensionNames: [String]?) throws -> ZarrArray {
        let metadata = ZarrArrayMetaData(shape:shape, dataType: dataType, chunkGrid: chunkGrid, chunkKeyEncoding: chunkKeyEncoding, fillValue: fillValue, codecs: codecs, attributes: attributes, dimensionNames: dimensionNames)
        
        return try create(store: store, path: path, metadata: metadata)
    }
    
    // Opens existing group - reads metadata from store
    public static func open(store: ZarrStore, path: String) throws -> ZarrArray
    {
        let metadataKey =
            path.isEmpty ? DEFAULT_META_KEY : "\(path)/\(DEFAULT_META_KEY)"
        guard let jsonData = try store.get(key: metadataKey) else {
            throw ZarrError.invalidPath("Metadata not found at \(metadataKey)")
        }

        let decoder = JSONDecoder()
        do {
            let metadata = try decoder.decode(
                ZarrArrayMetaData.self,
                from: jsonData
            )
            // Create instance (no writing)
            return try ZarrArray(store: store, path: path, metadata: metadata)
        } catch {
            //print("Decoding error \(error)")
            // Handle potential decoding errors
            fatalError("Failed to decode JSON: \(error.localizedDescription)")
        }
    }
    
    private func chunkKey(for indices: [Int]) -> String {
        let key = metadata.chunkKeyEncoding.encodeKey(indices)
        return path.isEmpty ? key : "\(path)/\(key)"
    }
    
    private func applyCodecs(_ data: Data, encoding: Bool) throws -> Data {
            var result = data
            let codecConfigurations = encoding ? metadata.codecs : metadata.codecs.reversed()
            
            for config in codecConfigurations {
                let codec = try CodecFactory.create(from: config)
                if encoding {
                    result = try codec.encode(result)
                }
                else {
                    result = try codec.decode(result,expectedSize: metadata.shape.reduce(1, *))
                }
                
            }
            
            return result
        }
    
    // MARK: - Numeric Chunk Operations
    
    public func writeChunk<T: BinaryInteger>(at indices: [Int], data: [T])
        throws
    {
        guard indices.count == metadata.chunkGrid.chunkShape.count else {
            throw ZarrError.dimensionMismatch(
                "Chunk indices must match number of dimensions"
            )
        }

        let expectedSize = metadata.chunkGrid.chunkShape.reduce(1, *)
        guard data.count == expectedSize else {
            throw ZarrError.dimensionMismatch(
                "Data size \(data.count) doesn't match chunk shape"
            )
        }

        var bytes = Data()
        for value in data {
            // Append bytes in native endianness; Zarr typically uses little-endian for numeric storage.
            // If needed, convert explicitly to little-endian for fixed-width integers.
            if let v = value as? any FixedWidthInteger {
                var le = v.littleEndian
                withUnsafeBytes(of: &le) {
                    bytes.append($0.bindMemory(to: UInt8.self))
                }
            } else {
                // Fallback for non-FixedWidthInteger BinaryInteger types: bridge through Int64
                var le = Int64(value).littleEndian
                withUnsafeBytes(of: &le) {
                    bytes.append($0.bindMemory(to: UInt8.self))
                }
            }
        }

        let encoded = try applyCodecs(bytes, encoding: true)
        let key = chunkKey(for: indices)
        try store.set(key: key, value: encoded)
    }

    public func writeChunk<T: BinaryFloatingPoint>(at indices: [Int], data: [T])
        throws
    {
        guard indices.count == metadata.chunkGrid.chunkShape.count else {
            throw ZarrError.dimensionMismatch(
                "Chunk indices must match number of dimensions"
            )
        }

        let expectedSize = metadata.chunkGrid.chunkShape.reduce(1, *)
        guard data.count == expectedSize else {
            throw ZarrError.dimensionMismatch(
                "Data size \(data.count) doesn't match chunk shape"
            )
        }

        var bytes = Data()
        for value in data {
            if T.self == Float.self {
                let bits = (value as! Float).bitPattern.littleEndian
                withUnsafeBytes(of: bits) { bytes.append(contentsOf: $0) }
            } else if T.self == Double.self {
                let bits = (value as! Double).bitPattern.littleEndian
                withUnsafeBytes(of: bits) { bytes.append(contentsOf: $0) }
            }
        }

        let encoded = try applyCodecs(bytes, encoding: true)
        let key = chunkKey(for: indices)
        try store.set(key: key, value: encoded)
    }

    public func readChunk<T: FixedWidthInteger>(at indices: [Int], as type: T.Type) throws -> [T] {
        let key = chunkKey(for: indices)
        guard let data = try store.get(key: key) else {
            // TODO: Return fill value
            return []
        }
        let decompressed = try decompress(data)
        
        var result = [T]()
        // Assuming tight packing and little endian
        let typeSize = MemoryLayout<T>.size
        let count = decompressed.count / typeSize
        
        decompressed.withUnsafeBytes { buffer in
            let typedBuffer = buffer.bindMemory(to: T.self)
            for i in 0..<count {
                result.append(T(littleEndian: typedBuffer[i]))
            }
        }
        return result
    }

    public func readChunk<T: BinaryFloatingPoint>(at indices: [Int], as type: T.Type) throws -> [T] {
        let key = chunkKey(for: indices)
        guard let data = try store.get(key: key) else {
            // TODO: Return fill value
            return []
        }
        let decompressed = try decompress(data)
        
        var result = [T]()
        let typeSize = MemoryLayout<T>.size
        let count = decompressed.count / typeSize
        
        decompressed.withUnsafeBytes { buffer in
            if T.self == Float.self {
                let typedBuffer = buffer.bindMemory(to: UInt32.self)
                for i in 0..<count {
                    let val = Float(bitPattern: UInt32(littleEndian: typedBuffer[i]))
                    result.append(val as! T)
                }
            } else if T.self == Double.self {
                let typedBuffer = buffer.bindMemory(to: UInt64.self)
                for i in 0..<count {
                    let val = Double(bitPattern: UInt64(littleEndian: typedBuffer[i]))
                    result.append(val as! T)
                }
            }
        }
        return result
    }
}

extension ZarrArray {
    internal func decompress(_ data: Data) throws -> Data {
        let chunkShape = metadata.chunkGrid.chunkShape
        let elementCount = chunkShape.reduce(1, *)
        let expectedSize = elementCount * MemoryLayout<UInt8>.size // TODO Change this to use ZarrDataType
        var processedData = data
        
        // 🛠️ Map the JSON configurations to executable Codec objects
        // If metadata stores [CodecConfiguration], convert them now:
        let executableCodecs = try metadata.codecs.map {
            try CodecFactory.create(from: $0)
        }
        
        // Apply in reverse for decoding
        for codec in executableCodecs.reversed() {
            processedData = try codec.decode(processedData, expectedSize: expectedSize)
        }
        
        return processedData
    }
    
}

extension ZarrArray : CustomStringConvertible {
    public var description: String {
        return ""
    }
}
