//
//  ZipStoreTests.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/31/26.
//

import Testing
import Foundation
import PythonKit
@testable import SwiftZarr

@Suite(.serialized)
struct ZipStoreTests {
    private let fileManager = FileManager.default
    
    private static var testsDirectory: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    }
    
    private var tempDirectory: URL {
        fileManager.temporaryDirectory.appendingPathComponent("SwiftZarrZipTests", isDirectory: true)
    }
    
    private static let setupPython: Void = {
        let sys = Python.import("sys")
        sys.path.append(testsDirectory.path)
    }()
    
    init() throws {
        _ = Self.setupPython
        if !fileManager.fileExists(atPath: tempDirectory.path) {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        }
    }
    
    @Test func readZipStore() throws {
        let zipPath = tempDirectory.appendingPathComponent("test.zarr.zip").path
        try? fileManager.removeItem(atPath: zipPath)
        
        let create_zarr = Python.import("create_zarr")
        create_zarr.create_zip_zarr(zipPath)
        
        let store = try ZipStore(path: URL(fileURLWithPath: zipPath))
        
        // Zarr v3 in ZIP usually has paths without leading slash
        #expect(store.exists(key: "zarr.json"))
        
        let array = try ZarrArray.open(store: store, path: "")
        #expect(array.metadata.shape == [50, 50])
        #expect(array.metadata.dataType == .int32)
        
        // Read some data
        let chunk00: [Int32] = try array.readChunk(at: [0, 0], as: Int32.self)
        #expect(chunk00[0] == 123)
        
        let chunk44: [Int32] = try array.readChunk(at: [4, 4], as: Int32.self)
        #expect(chunk44.last == 456)
    }
}
