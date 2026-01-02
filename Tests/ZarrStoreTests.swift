//
//  ZarrObjectTests.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/30/25.
//

import Testing
import Foundation
import QuartzCore
@testable import ZarrSwift

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
    
}



