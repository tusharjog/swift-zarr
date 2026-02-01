//
//  ZarrObjectTests.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/30/25.
//

import Testing
import Foundation
import QuartzCore
@testable import SwiftZarr

struct ZarrStoreTests {
    @Test func lruEviction() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        let mem = MemoryStore()
        let lru = CachingStore(inner: mem, capacity:1)
        
        try lru.set(key: "a", value: Data([1]))
        try lru.set(key: "b", value: Data([2]))

        #expect(mem.exists(key: "b"))
    }
    
    @Test func fileSystemStore() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let path = URL(fileURLWithPath: "/tmp/example.zarr")
        
        let store = try FilesystemStore(path: path)
        
        try store.set(key: "a", value: Data([1, 2, 3, 4, 5, 6]))
    }
    
    @Test func fileSystemStoreRead() async throws {
        let currentFileURL = URL(fileURLWithPath: #filePath)
        let testFilesDir = currentFileURL.deletingLastPathComponent().appendingPathComponent("files")
        let path = testFilesDir.appendingPathComponent("example-2.zarr")
        print("Test path: \(path.path)")
        print("Exists: \(FileManager.default.fileExists(atPath: path.path))")
        
        let store = try FilesystemStore(path: path)
        //let list = try store.list(prefix:"example-2")
        //print("List : ", list)
        
        let array = try ZarrArray.open(store:store, path:"")
        print("Array : ", array)
        
        //try store.set(key: "a", value: Data([1, 2, 3, 4, 5, 6]))
        //let val = try store.get(key: "")
        //print(val)
    }
}



