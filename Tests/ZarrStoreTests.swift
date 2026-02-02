//
//  ZarrStoreTests.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/30/25.
//

import Testing
import Foundation
@testable import SwiftZarr

@Suite struct ZarrStoreTests {
    private let fileManager = FileManager.default
    
    // Helper to get a unique temporary directory for a test
    private func makeTempDir() throws -> URL {
        let url = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    @Test func memoryStoreBasicOps() async throws {
        let store = MemoryStore()
        let key = "test/data"
        let value = Data([1, 2, 3, 4])
        
        // Test set and get
        try store.set(key: key, value: value)
        let retrieved = try store.get(key: key)
        #expect(retrieved == value)
        
        // Test exists
        #expect(store.exists(key: key))
        #expect(!store.exists(key: "nonexistent"))
        
        // Test list
        let list = try store.list(prefix: "test/")
        #expect(list.contains("test/data"))
        
        // Test delete
        try store.delete(key: key)
        #expect(!store.exists(key: key))
        #expect(try store.get(key: key) == nil)
    }
    
    @Test func filesystemStoreBasicOps() async throws {
        let tempDir = try makeTempDir()
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let store = try FilesystemStore(path: tempDir)
        let key = "chunk/0.0"
        let value = "hello zarr".data(using: .utf8)!
        
        // Test set and get
        try store.set(key: key, value: value)
        let retrieved = try store.get(key: key)
        #expect(retrieved == value)
        
        // Test exists
        #expect(store.exists(key: key))
        
        // Test list
        let list = try store.list(prefix: "chunk/")
        #expect(list.contains("chunk/0.0"))
        
        // Test delete
        try store.delete(key: key)
        #expect(!store.exists(key: key))
    }
    
    @Test func cachingStoreLRU() async throws {
        let mem = MemoryStore()
        // Capacity of 2
        let lru = CachingStore(inner: mem, capacity: 2)
        
        let dataA = Data([0xA])
        let dataB = Data([0xB])
        let dataC = Data([0xC])
        
        try lru.set(key: "a", value: dataA)
        try lru.set(key: "b", value: dataB)
        
        // Both should be in cache and mem
        #expect(try lru.get(key: "a") == dataA)
        #expect(try lru.get(key: "b") == dataB)
        
        // Set C, should evict one from cache (likely 'a' if not accessed, but CachingStore implementation detail matters)
        // Usually LRU evicts the least recently used.
        try lru.set(key: "c", value: dataC)
        
        // All should still be in the underlying MemoryStore
        #expect(mem.exists(key: "a"))
        #expect(mem.exists(key: "b"))
        #expect(mem.exists(key: "c"))
        
        // Verification of eviction is harder without exposing cache internals, 
        // but we can at least verify functional correctness.
        #expect(try lru.get(key: "a") == dataA)
        #expect(try lru.get(key: "c") == dataC)
    }
    
    @Test func fileSystemStoreReadExisting() async throws {
        let currentFileURL = URL(fileURLWithPath: #filePath)
        let testFilesDir = currentFileURL.deletingLastPathComponent().appendingPathComponent("files")
        let path = testFilesDir.appendingPathComponent("example-2.zarr")
        
        // Only run if the test data actually exists
        guard fileManager.fileExists(atPath: path.path) else {
            print("Skipping fileSystemStoreReadExisting: test data not found at \(path.path)")
            return
        }
        
        let store = try FilesystemStore(path: path)
        let array = try ZarrArray.open(store: store, path: "")
        
        #expect(array.metadata.shape.count > 0)
        // Try reading a known chunk if possible, or just verify metadata
        #expect(array.metadata.zarrFormat == 3)
    }
}