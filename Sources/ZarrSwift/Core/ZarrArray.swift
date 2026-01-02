//
//  ZarrArray.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/29/25.
//

import Foundation

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
    
    public init(path: String, store: ZarrStore, metadata: ZarrArrayMetaData) throws {
        self.path = path
        self.store = store
        self.nodeType = .array
        self.metadata = metadata
        
        let metadataKey = path.isEmpty ? DEFAULT_META_KEY : "\(path)/\(DEFAULT_META_KEY)"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsondata = try? encoder.encode(metadata) {
            try self.store.set(key: metadataKey, value: jsondata)
            print(metadataKey)
            print(String(data: jsondata, encoding: .utf8)!)
        }
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
