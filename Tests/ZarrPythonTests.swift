//
//  ZarrPython.swift
//  SwiftZarr
//
//  Created by Tushar Jog on 1/3/26.
//

import Testing
import Foundation
import QuartzCore
import PythonKit
@testable import SwiftZarr


struct ZarrPythonTests {
    @Test func createZarrFiles() async throws {

        let sys = Python.import("sys")
        print(Python.version, Python.versionInfo)
        print("Python Version: \(sys.version)")
        print("Python Encoding: \(sys.getdefaultencoding().upper())")

        let zarr = Python.import("zarr")
        
        let np = Python.import("numpy")
        let array = np.array([1, 2, 3, 4, 5])
        // Standard indexing and slicing
        print(array[0..<3]) // Output: [1, 2, 3]

        // Converting back to a Swift array
        let swiftArray = Array(array)
        
        let currentFileURL = URL(fileURLWithPath: #filePath)
        let testsDir = currentFileURL.deletingLastPathComponent()
        sys.path.append(testsDir.path)
        
        let create_zarr = Python.import("create_zarr")
        let tempZarr = testsDir.appendingPathComponent("files/temp_python.zarr").path
        // Delete if exists
        try? FileManager.default.removeItem(atPath: tempZarr)
        create_zarr.example_2(tempZarr)
    }
    @Test func readArray() async throws {
        let currentFileURL = URL(fileURLWithPath: #filePath)
        let testsDir = currentFileURL.deletingLastPathComponent()
        let externalPath = testsDir.appendingPathComponent("files/example-2.zarr").path
        let url = URL(fileURLWithPath: externalPath)
        // Check if path exists
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        guard exists && isDir.boolValue else {
            print("⚠️ External Zarr not found at \(externalPath) or is not a directory, skipping test.")
            return
        }
        let store = try FilesystemStore(path: url)
        try store.get(key:"")
        let array = try ZarrArray.open(store:store, path:"")
        print(array)
    }

}

