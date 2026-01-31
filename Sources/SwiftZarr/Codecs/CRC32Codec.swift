//
//  CRC32Codec.swift
//  SwiftZarr
//
//  Created by Tushar Jog on 1/3/26.
//

import Foundation

//
// https://zarr-specs.readthedocs.io/en/latest/v3/codecs/crc32c/index.html
//

// MARK: - CRC32C Implementation

public func crc32c(_ data: Data) -> UInt32 {
    let polynomial: UInt32 = 0x82F63B78
    var crc: UInt32 = 0xFFFFFFFF
    
    for byte in data {
        crc ^= UInt32(byte)
        for _ in 0..<8 {
            crc = (crc & 1) != 0 ? (crc >> 1) ^ polynomial : crc >> 1
        }
    }
    
    return ~crc
}

// MARK: - CRC32C Codec

public struct CRC32Codec : ZarrCodec {
    public var name: String = "crc32c"
    
    public func encode(_ data: Data) throws -> Data {
        var result = data
        let checksum = crc32c(data)
        withUnsafeBytes(of: checksum.littleEndian) {
            result.append(contentsOf: $0)
        }
        return result
    }
    
    public func decode(_ data: Data, expectedSize: Int) throws -> Data {
        // Verify checksum when reading
        guard data.count >= 4 else {
            throw ZarrError.codecError("Invalid CRC32C data")
        }
        let payload = data.dropLast(4)
        let storedChecksum = data.suffix(4).withUnsafeBytes {
            UInt32(littleEndian: $0.load(as: UInt32.self))
        }
        let computedChecksum = crc32c(payload)
        guard computedChecksum == storedChecksum else {
            throw ZarrError.codecError("CRC32C checksum mismatch")
        }
        return Data(payload)
    }

    
}
