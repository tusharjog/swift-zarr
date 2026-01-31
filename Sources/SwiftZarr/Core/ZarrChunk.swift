//
//  ZarrChunk.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/29/25.
//

import Foundation

/*
 "chunk_grid": {
     "name": "regular",
     "configuration": {
         "chunk_shape": [1000, 100]
     }
 },
 */
public enum ZarrChunkGrid : Codable {
    case regular([Int])
    
    enum CodingKeys : String, CodingKey {
        case name
        case configuration
    }
    
    struct Configuration : Codable {
        public let chunkShape: [Int]
        enum CodingKeys : String, CodingKey {
            case chunkShape = "chunk_shape"
        }
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        if name == "regular" {
            let configuration = try container.decode(Configuration.self, forKey: .configuration)
            self = .regular(configuration.chunkShape)
        } else {
            throw ZarrError.invalidMetadata("Unsupported chunk grid \(name)")
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .regular(let shape):
            try container.encode("regular", forKey: .name)
            var configContainer = container.nestedContainer(keyedBy: Configuration.CodingKeys.self, forKey: .configuration)
            try configContainer.encode(shape, forKey: .chunkShape)
        }
    }
    
    public var chunkShape: [Int] {
        switch self {
        case .regular(let shape):
            return shape
        }
    }
}

// MARK : Chunk Key Encoding
/*
 "chunk_key_encoding": {
     "name": "default",
     "configuration": {
         "separator": "/"
     }
 },
 */

public enum ZarrChunkKeyEncoding : Codable {
    case `default`(separator:String)
    //case v2(separator:String)
    
    enum CodingKeys : String, CodingKey {
        case name
        case configuration
    }
    
    struct Configuration : Codable {
        public let separator: String
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let configuration = try container.decode(Configuration.self, forKey: .configuration)
        
        switch(name) {
        case "default":
            self = .default(separator: configuration.separator)
        default: throw ZarrError.invalidMetadata("Unsupported chunk key encoding \(name)")
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .default(let sep):
            try container.encode("default", forKey: .name)
            try container.encode(Configuration(separator: sep), forKey: .configuration)
        }
    }
    
    func encodeKey(_ indices: [Int]) -> String {
        switch self {
        case .default(let sep):
            return "c" + sep + indices.map(String.init).joined(separator: sep)
        }
    }
}
