//
//  ZstdCodec.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/31/26.
//

import Foundation
import libzstd

public struct ZstdCodec: ZarrCodec {
    public var name: String = "zstd"
    public let level: Int
    
    public init(level: Int = 3) {
        self.level = level
    }
    
    public func encode(_ data: Data) throws -> Data {
        let srcSize = data.count
        let dstCapacity = ZSTD_compressBound(srcSize)
        var dst = Data(count: dstCapacity)
        
        let result = dst.withUnsafeMutableBytes { dstPtr in
            data.withUnsafeBytes { srcPtr in
                ZSTD_compress(dstPtr.baseAddress!, dstCapacity, srcPtr.baseAddress!, srcSize, Int32(level))
            }
        }
        
        if ZSTD_isError(result) != 0 {
            let errorName = String(cString: ZSTD_getErrorName(result))
            throw ZarrError.codecError("Zstd compression failed: \(errorName)")
        }
        
        return dst.prefix(result)
    }
    
    public func decode(_ data: Data, expectedSize: Int) throws -> Data {
        var dst = Data(count: expectedSize)
        let srcSize = data.count
        
        let result = dst.withUnsafeMutableBytes { dstPtr in
            data.withUnsafeBytes { srcPtr in
                ZSTD_decompress(dstPtr.baseAddress!, expectedSize, srcPtr.baseAddress!, srcSize)
            }
        }
        
        if ZSTD_isError(result) != 0 {
            let errorName = String(cString: ZSTD_getErrorName(result))
            throw ZarrError.codecError("Zstd decompression failed: \(errorName)")
        }
        
        return dst.prefix(result)
    }
}
