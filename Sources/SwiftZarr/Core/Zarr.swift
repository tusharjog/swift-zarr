//
//  Zarr.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/29/25.
//

import Foundation

public let DEFAULT_META_KEY : String = "zarr.json"

public enum Zarr {
    /*
    public static func open(store: ZarrStore, path: String = "") throws -> ZarrNode {
        let metaPath = path.isEmpty ? DEFAULT_META_KEY : "\(path)/\(DEFAULT_META_KEY)"
        guard let data = try store.get(key: metaPath) else { return ZarrGroup(store: store, path:"") }
        
        if let _ = try? JSONDecoder().decode(ZarrGroupMetaData.self, from: data) {
            return try ZarrGroup(store: store, path: path, metadata: <#ZarrGroupMetaData#>)
        }
    }
     */
}

// MARK : Fill Value

public enum FillValue : Codable, Equatable {
    case int(Int64)
    case uint(UInt64)
    case float(Double)
    case string(String)
    case null
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        }
        else if let intValue = try? container.decode(Int64.self) {
            self = .int(intValue)
        }
        else if let uintValue = try? container.decode(UInt64.self) {
            self = .uint(uintValue)
        }
        else if let floatValue = try? container.decode(Double.self) {
            self = .float(floatValue)
        }
        else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        }
        else {
            throw ZarrError.invalidFillValue("\(container)")
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch(self) {
        case .int(let v): try container.encode(v)
        case .uint(let v): try container.encode(v)
        case .float(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .null: try container.encodeNil()
            
        }
    }
}
