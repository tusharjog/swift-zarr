//
//  ZarrPythonTests.swift
//  SwiftZarr
//
//  Created by Tushar Jog on 1/3/26.
//

import Testing
import Foundation
import PythonKit
@testable import SwiftZarr

@Suite(.serialized)
struct ZarrPythonTests {
    private let fileManager = FileManager.default
    
    private static var testsDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }
    
    private var tempDirectory: URL {
        fileManager.temporaryDirectory.appendingPathComponent("SwiftZarrTests", isDirectory: true)
    }
    
    private static let setupPython: Void = {
        let sys = Python.import("sys")
        let testsPath = testsDirectory.path
        
        var found = false
        for path in sys.path {
            if String(path) == testsPath {
                found = true
                break
            }
        }
        if !found {
            sys.path.append(testsPath)
        }
    }()
    
    init() throws {
        _ = Self.setupPython
        // Ensure temp directory exists
        if !fileManager.fileExists(atPath: tempDirectory.path) {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }
    }
    
    @Test func pythonEnvironment() {
        let sys = Python.import("sys")
        print("Python Version: \(sys.version)")
        #expect(String(sys.version) != "")
    }
    
    @Test func createAndReadBasicArray() throws {
        let zarrPath = tempDirectory.appendingPathComponent("basic_array.zarr").path
        try? fileManager.removeItem(atPath: zarrPath)
        
        let create_zarr = Python.import("create_zarr")
        create_zarr.create_basic_array(zarrPath)
        
        let store = try FilesystemStore(path: URL(fileURLWithPath: zarrPath))
        let array = try ZarrArray.open(store: store, path: "")
        
        #expect(array.metadata.shape == [100, 100])
        #expect(array.metadata.dataType == .float32)
    }
    
    @Test func createAndReadCompressedArray() throws {
        let zarrPath = tempDirectory.appendingPathComponent("compressed_array.zarr").path
        try? fileManager.removeItem(atPath: zarrPath)
        
        let create_zarr = Python.import("create_zarr")
        create_zarr.create_array_with_compression(zarrPath)
        
        let store = try FilesystemStore(path: URL(fileURLWithPath: zarrPath))
        let array = try ZarrArray.open(store: store, path: "")
        
        #expect(array.metadata.shape == [100, 100])
        #expect(!array.metadata.codecs.isEmpty)
    }
    
    @Test func createAndReadHierarchy() throws {
        let zarrPath = tempDirectory.appendingPathComponent("hierarchy.zarr").path
        try? fileManager.removeItem(atPath: zarrPath)
        
        let create_zarr = Python.import("create_zarr")
        create_zarr.create_hierarchical_group(zarrPath)
        
        let store = try FilesystemStore(path: URL(fileURLWithPath: zarrPath))
        let root = try ZarrGroup.open(store: store, path: "")
        
        let children = try root.listChildren()
        print(children)
        #expect(children.contains("foo"))
        #expect(children.contains("bar"))
        
        let foo = try ZarrGroup.open(store: store, path: "foo")
        let fooChildren = try foo.listChildren()
        #expect(fooChildren.contains("spam"))
    }
}
