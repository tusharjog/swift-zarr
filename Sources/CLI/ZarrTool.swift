//
//  ZarrTool.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//

import Foundation
import ZarrSwift

@main
struct ZarrTool {
    static func main() async {
        let args = ProcessInfo.processInfo.arguments
        
        guard args.count > 1 else {
            print("""
            📂 ZarrSwift CLI
            Usage:
              swift run zarr-tool convert <raw_file>
              swift run zarr-tool view
            """)
            return
        }
        
        do {
            switch args[1] {
            case "convert":
                try await runConversion()
            case "view":
                try await runViewer()
            default:
                print("❌ Unknown command: \(args[1])")
            }
        } catch {
            print("❌ Critical Error: \(error)")
        }
    }
    
    // MARK: - Conversion Logic
    static func runConversion() async throws {
        print("🏗 Starting Conversion...")
        let shape = [64, 64, 64]
        let chunkShape = [32, 32, 32]
        //let store = FilesystemStore(path: URL(fileURLWithPath: "output.zarr"))

        print("✅ Created Zarr structure in output.zarr")
    }
    
    // MARK: - Viewer Logic
    static func runViewer() async throws {
        //let store = FilesystemStore(path: URL(fileURLWithPath: "output.zarr"))
        print("🔍 Opening Zarr volume for viewing...")

    }
}
