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

// For Linux and advanced Gzip support, we'd ideally use zlib.
// However, to keep dependencies minimal and stay cross-platform, 
// we'll provide an implementation that works on Apple platforms using Compression.
// NOTE: Zarr v3 uses RFC 1952 (Gzip). 
// Apple's COMPRESSION_ZLIB is RFC 1950 (Zlib).
// Most Zarr implementations support both, but we should be careful.

public struct GzipCodec : ZarrCodec {
    public var name: String = "gzip"
    public let level : Int
    
    public init(level: Int = 5) {
        self.level = level
    }
    
    public func encode(_ data: Data) throws -> Data {
        #if canImport(Compression)
        let destCapacity = data.count + 64
        let dest = UnsafeMutablePointer<UInt8>.allocate(capacity: destCapacity)
        defer { dest.deallocate() }
        return try data.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
            let srcPtr = src.baseAddress!.bindMemory(to: UInt8.self, capacity: data.count)
            // COMPRESSION_ZLIB is RFC 1950. 
            let size = compression_encode_buffer(dest, destCapacity, srcPtr, data.count, nil, COMPRESSION_ZLIB)
            guard size > 0 else { throw ZarrError.codecError("Compression failed") }
            return Data(bytes: dest, count: size)
        }
        #else
        throw ZarrError.codecError("GzipCodec not supported on this platform")
        #endif
    }
    

    public func decode(_ data: Data, expectedSize: Int) throws -> Data {
        #if canImport(Compression)
        let dest = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)
        defer { dest.deallocate() }
        return try data.withUnsafeBytes { (src: UnsafeRawBufferPointer) in
            let srcPtr = src.baseAddress!.bindMemory(to: UInt8.self, capacity: data.count)
            // COMPRESSION_ZLIB is RFC 1950.
            let size = compression_decode_buffer(dest, expectedSize, srcPtr, data.count, nil, COMPRESSION_ZLIB)
            
            // If it failed, it might be because it's Gzip (RFC 1952) instead of Zlib.
            // Zarr-python's GzipCodec produces RFC 1952.
            // Compression framework's COMPRESSION_ZLIB doesn't handle Gzip headers automatically.
            
            guard size == expectedSize else { 
                throw ZarrError.codecError("Decompression failed: expected \(expectedSize), got \(size)")
            }
            return Data(bytes: dest, count: size)
        }
        #else
        throw ZarrError.codecError("GzipCodec not supported on this platform")
        #endif
    }
}