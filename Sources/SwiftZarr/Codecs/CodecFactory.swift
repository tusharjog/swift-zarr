//
//  CodecFactory.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//

import Foundation

public enum CodecFactory {
    public static func create(from config: ZarrCodecConfiguration) throws -> any ZarrCodec {
        switch config.name {
        case "identity":
            return IdentityCodec()
        case "gzip":
            return GzipCodec(level:5)
        case "bytes":
            let endian = config.configuration["endian"]?.stringValue ?? "little"
            return BytesCodec(endian: endian)
        default:
            throw ZarrError.codecError("Unknown codec: \(config.name)")
        }
    }
}
