//
//  ZarrObjectTests.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//

import Testing
import Foundation
@testable import SwiftZarr

@Suite struct ZarrObjectTests {
    private let fileManager = FileManager.default
    
    private func makeTempDir() throws -> URL {
        let url = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private func setupBasicStore() throws -> (ZarrStore, URL) {
        let tempDir = try makeTempDir()
        let store = try FilesystemStore(path: tempDir)
        return (store, tempDir)
    }

    @Test func groupCreationAndMetadata() async throws {
        let (store, tempDir) = try setupBasicStore()
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let attrs: [String: JSONValue] = ["version": .string("1.0"), "priority": .number(1)]
        let metadata = ZarrGroupMetaData(attributes: attrs)
        let group = try ZarrGroup.create(store: store, path: "my_group", metadata: metadata)
        
        #expect(group.path == "my_group")
        #expect(group.name == "my_group")
        #expect(group.nodeType == .group)
        #expect(group.metadata.attributes?["version"]?.stringValue == "1.0")
        #expect(group.metadata.attributes?["priority"]?.doubleValue == 1.0)
        
        // Re-open and verify
        let openedGroup = try ZarrGroup.open(store: store, path: "my_group")
        #expect(openedGroup.metadata.attributes?.count == 2)
    }
    
    @Test func arrayCreationAndMetadata() async throws {
        let (store, tempDir) = try setupBasicStore()
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let arrayMetadata = ZarrArrayMetaData(
            shape: [10, 20],
            dataType: .int32,
            chunkGrid: .regular([5, 5]),
            chunkKeyEncoding: .default(separator: "/"),
            fillValue: .int(42),
            codecs: [ZarrCodecConfiguration(name: "bytes", configuration: ["endian": .string("little")])],
            attributes: ["units": .string("K")],
            dimensionNames: ["lat", "lon"]
        )
        
        let array = try ZarrArray.create(store: store, path: "data/temperature", metadata: arrayMetadata)
        
        #expect(array.path == "data/temperature")
        #expect(array.name == "temperature")
        #expect(array.nodeType == .array)
        #expect(array.metadata.shape == [10, 20])
        #expect(array.metadata.dataType == .int32)
        #expect(array.metadata.fillValue == .int(42))
        #expect(array.metadata.dimensionNames == ["lat", "lon"])
        
        // Re-open and verify
        let openedArray = try ZarrArray.open(store: store, path: "data/temperature")
        #expect(openedArray.metadata.shape == [10, 20])
    }
    
    @Test func hierarchyTraversal() async throws {
        let (store, tempDir) = try setupBasicStore()
        defer { try? fileManager.removeItem(at: tempDir) }
        
        // Create: / (root) -> level1 (group) -> data (array)
        _ = try ZarrGroup.create(store: store, path: "", metadata: ZarrGroupMetaData(attributes: nil))
        _ = try ZarrGroup.create(store: store, path: "level1", metadata: ZarrGroupMetaData(attributes: nil))
        
        let arrayMetadata = ZarrArrayMetaData(
            shape: [10], dataType: .uint8, chunkGrid: .regular([10]),
            chunkKeyEncoding: .default(separator: "/"), fillValue: .null,
            codecs: [ZarrCodecConfiguration(name: "bytes", configuration: ["endian": .string("little")])],
            attributes: nil, dimensionNames: nil
        )
        _ = try ZarrArray.create(store: store, path: "level1/data", metadata: arrayMetadata)
        
        // Verify root children
        let root = try ZarrGroup.open(store: store, path: "")
        let rootChildren = try root.listChildren()
        #expect(rootChildren.count == 1)
        #expect(rootChildren.contains("level1"))
        
        // Verify level1 children
        let level1 = try ZarrGroup.open(store: store, path: "level1")
        let level1Children = try level1.listChildren()
        #expect(level1Children.count == 1)
        #expect(level1Children.contains("data"))
    }
    
    @Test func nodeIdentity() async throws {
        let (store, tempDir) = try setupBasicStore()
        defer { try? fileManager.removeItem(at: tempDir) }
        
        let group = try ZarrGroup.create(store: store, path: "g", metadata: ZarrGroupMetaData(attributes: nil))
        #expect(group.isGroup())
        #expect(!group.isArray())
        #expect(group.asGroup() != nil)
        #expect(group.asArray() == nil)
        
        let arrayMetadata = ZarrArrayMetaData(
            shape: [1], dataType: .bool, chunkGrid: .regular([1]),
            chunkKeyEncoding: .default(separator: "/"), fillValue: .null,
            codecs: [ZarrCodecConfiguration(name: "bytes", configuration: ["endian": .string("little")])],
            attributes: nil, dimensionNames: nil
        )
        let array = try ZarrArray.create(store: store, path: "a", metadata: arrayMetadata)
        #expect(!array.isGroup())
        #expect(array.isArray())
        #expect(array.asGroup() == nil)
        #expect(array.asArray() != nil)
    }
}