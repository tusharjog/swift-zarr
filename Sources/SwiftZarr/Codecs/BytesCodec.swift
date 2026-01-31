//
//  BytesCodec.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/31/26.
//

import Foundation

public struct BytesCodec: ZarrCodec {
    public var name: String = "bytes"
    public var endian: String
    
    public init(endian: String = "little") {
        self.endian = endian
    }
    
    public func encode(_ data: Data) throws -> Data {
        // Since our writeChunk already handles littleEndian, and Zarr v3 bytes codec
        // is mostly about specifying how it was written, we can return data as is
        // if it's already in the target endianness.
        return data
    }
    
    public func decode(_ data: Data, expectedSize: Int) throws -> Data {
        // Similarly for decoding
        return data
    }
}
