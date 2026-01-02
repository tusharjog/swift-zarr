//
//  ZarrCodec.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/29/25.
//
import Foundation


public protocol ZarrCodec : Codable, Equatable {
    var name: String { get }
    
    func encode(_ data: Data) throws -> Data
    func decode(_ data: Data) throws -> Data
}


public struct ZarrCodecConfiguration : Codable, Sendable {
    var name : String
    var configuration : [String:String]
    
    public init(name: String, configuration: [String : String]) {
        self.name = name
        self.configuration = configuration
    }
}

public enum CodecFactory {
    public static func create(from config: ZarrCodecConfiguration) throws -> any ZarrCodec {
        switch config.name {
        case "identity":
            return IdentityCodec()
        default:
            throw ZarrError.codecError("Unknown codec: \(config.name)")
        }
    }
}

//
// A pass through codec
//
public struct IdentityCodec : ZarrCodec {
    public var name: String = "identity"
    
    public func encode(_ data: Data) throws -> Data {
        data
    }
    
    public func decode(_ data: Data) throws -> Data {
        data
    }
}
