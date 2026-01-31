//
//  ZarrGroup.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/30/25.
//

import Foundation

// MARK : ZarrGroup.swift

public class ZarrGroup : ZarrNode {
    public func isGroup() -> Bool {
        return true
    }
    
    public func isArray() -> Bool {
        return false
    }
    
    public var path: String
    public var store: ZarrStore
    public var nodeType: ZarrNodeType
    public var metadata: ZarrGroupMetaData
    
    // Private init - does not write metadata to store
    private init(store: ZarrStore, path: String, metadata:ZarrGroupMetaData) throws {
        self.path = path
        self.store = store
        self.metadata = metadata
        self.nodeType = .group
    }
    
    // Create group - writes metadata to store
    public static func create(store: ZarrStore, path : String, metadata : ZarrGroupMetaData) throws -> ZarrGroup {
        
        let metadataKey = path.isEmpty ? DEFAULT_META_KEY : "\(path)/\(DEFAULT_META_KEY)"
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let jsondata = try? encoder.encode(metadata) {
            try store.set(key: metadataKey, value: jsondata)
        }
        
        // Create instance
        return try ZarrGroup(store: store, path: path, metadata: metadata)
    }
    
    // Opens existing group - reads metadata from store
    public static func open(store: ZarrStore, path : String) throws -> ZarrGroup {
        let metadataKey = path.isEmpty ? DEFAULT_META_KEY : "\(path)/\(DEFAULT_META_KEY)"
        guard let jsonData = try store.get(key: metadataKey) else {
            throw ZarrError.invalidPath("Metadata not found at \(metadataKey)")
        }
        
        let decoder = JSONDecoder()
        let metadata = try decoder.decode(ZarrGroupMetaData.self, from: jsonData)
        
        // Create instance (no writing)
        return try ZarrGroup(store: store, path: path, metadata: metadata)
    }

    public func listChildren() throws -> [String] {
        let prefix = path.isEmpty ? "" : path + "/"
        let keys = try store.list(prefix: prefix)
        var children = Set<String>()
        
        for key in keys {
            guard key.hasPrefix(prefix) else { continue }
            let relative = String(key.dropFirst(prefix.count))
            let components = relative.split(separator: "/")
            if let first = components.first {
                let childName = String(first)
                // Filter out zarr.json itself if it's at the root of the search
                if childName != "zarr.json" {
                     children.insert(childName)
                }
            }
        }
        return Array(children).sorted()
    }
}

extension ZarrGroup : CustomStringConvertible {
    public var description : String {
        // metadata is a ZarrGroupMetaData, not Data. Try to encode to JSON for readability; otherwise, fall back.
        if let jsonData = try? JSONEncoder().encode(self.metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        } else {
            return String(describing: self.metadata)
        }
    }
}
