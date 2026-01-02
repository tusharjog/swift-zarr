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
    func decode(_ data: Data, expectedSize : Int) throws -> Data
}


public struct ZarrCodecConfiguration : Codable, Sendable {
    var name : String
    var configuration : [String:String]
    
    public init(name: String, configuration: [String : String]) {
        self.name = name
        self.configuration = configuration
    }
}



//
// A pass through codec
//
public struct IdentityCodec : ZarrCodec {
    public var name: String = "identity"
    
    public func encode(_ data: Data) throws -> Data {
        return data
    }
    
    public func decode(_ data: Data, expectedSize : Int) throws -> Data {
        return data
    }
}
