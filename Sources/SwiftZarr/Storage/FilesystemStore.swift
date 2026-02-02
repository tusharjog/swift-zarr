//
//  FileSystemStore.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/30/25.
//
import Foundation

// MARK: - Filesystem Store

public class FilesystemStore: ZarrStore {
    private let basePath: URL
    private let fileManager = FileManager.default
    
    public init(path: URL) throws {
        self.basePath = path.standardized
        try fileManager.createDirectory(at: self.basePath, withIntermediateDirectories: true)
    }
    
    private func fullPath(for key: String) -> URL {
        if key.isEmpty { return basePath }
        return basePath.appendingPathComponent(key).standardized
    }
    
    public func get(key: String) throws -> Data? {
        let path = fullPath(for: key)
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDir), !isDir.boolValue else { 
            return nil 
        }
        return try Data(contentsOf: path)
    }
    
    public func set(key: String, value: Data) throws {
        let path = fullPath(for: key)
        let directory = path.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try value.write(to: path)
    }
    
    public func delete(key: String) throws {
        let path = fullPath(for: key)
        try fileManager.removeItem(at: path)
    }
    
    public func exists(key: String) -> Bool {
        return fileManager.fileExists(atPath: fullPath(for: key).path)
    }
    
    public func list(prefix: String?) throws -> [String] {
        let searchPath = (prefix == nil || prefix!.isEmpty) ? basePath : fullPath(for: prefix!)
        guard fileManager.fileExists(atPath: searchPath.path) else { return [] }
        
        let contents = try fileManager.contentsOfDirectory(
            at: searchPath,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        let baseString = basePath.path.hasSuffix("/") ? basePath.path : basePath.path + "/"
        
        return contents.map { url in
            let fullPath = url.path
            if fullPath.hasPrefix(baseString) {
                return String(fullPath.dropFirst(baseString.count))
            }
            return url.lastPathComponent
        }
    }
}
