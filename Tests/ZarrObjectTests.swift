//
//  ZarrObjectTests.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//


import Testing
import Foundation
import QuartzCore
@testable import SwiftZarr


struct ZarrObjectTests {

    
    @Test func createObjects() async throws {
        let url = URL(fileURLWithPath: "/tmp/test_createObjects.zarr")
        deleteFileOrFolderIfExists(at: url)
        
        //let store = MemoryStore()
        let store = try FilesystemStore(path: url)
        
        try store.set(key: "a", value: Data([1, 2, 3, 4, 5, 6]))
        
        let metadata = ZarrGroupMetaData(attributes: [:])
        let root = try ZarrGroup.create(store: store, path: "foo", metadata: metadata)
        let arrayMetadata = ZarrArrayMetaData(
            shape: [100, 10],
            dataType: ZarrDataType.float32,
            chunkGrid: ZarrChunkGrid.regular([10, 10]),
            chunkKeyEncoding: ZarrChunkKeyEncoding.default(separator: "/"),
            fillValue: .float(0),
            codecs: [],
            attributes: [:],
            dimensionNames: []
        )
        let bar = try ZarrArray.create(store: store, path: "bar", metadata: arrayMetadata)
        
        print(store)
        print(root)
        
    }
}



extension ZarrGroup : CustomTestStringConvertible {
    public var testDescription : String {
        // metadata is a ZarrGroupMetaData, not Data. Try to encode to JSON for readability; otherwise, fall back.
        if let jsonData = try? JSONEncoder().encode(self.metadata),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        } else {
            return String(describing: self.metadata)
        }
    }
}

