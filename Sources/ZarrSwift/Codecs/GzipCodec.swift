//
//  GzipCodec.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//

import Foundation
#if canImport(Compression)
import Compression
#endif

public struct GzipCodec : ZarrCodec {
    public var name: String = "gzip"
    public let level : Int
    
    public func encode(_ data: Data) throws -> Data {
        let destCapacity = data.count + 64
        let dest = UnsafeMutablePointer<UInt8>.allocate(capacity: destCapacity)
        defer { dest.deallocate() }
        return try data.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
            let srcPtr = src.baseAddress!.bindMemory(to: UInt8.self, capacity: data.count)
            let size = compression_encode_buffer(dest, destCapacity, srcPtr, data.count, nil, COMPRESSION_ZLIB)
            guard size > 0 else { throw NSError(domain: "Zarr", code: -1) }
            return Data(bytes: dest, count: size)
        }
    }
    

    public func decode(_ data: Data, expectedSize: Int) throws -> Data {
        let dest = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)
        defer { dest.deallocate() }
        return try data.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
            let srcPtr = src.baseAddress!.bindMemory(to: UInt8.self, capacity: data.count)
            let size = compression_decode_buffer(dest, expectedSize, srcPtr, data.count, nil, COMPRESSION_ZLIB)
            guard size == expectedSize else { throw NSError(domain: "Zarr", code: -1) }
            return Data(bytes: dest, count: size)
        }
    }

    
}
