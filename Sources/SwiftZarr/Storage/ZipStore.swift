//
//  ZipStore.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/31/26.
//

import Foundation
@preconcurrency import ZIPFoundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A Zarr store that reads data from a ZIP archive.
/// This implementation uses cross-platform synchronization (NSLock) 
/// to ensure thread-safe access to the underlying archive.
public final class ZipStore: ZarrStore, @unchecked Sendable {
    private let archiveURL: URL
    private let archive: Archive
    private let lock = NSLock()
    
    public init(path: URL) throws {
        self.archiveURL = path
        // Initialize the archive. We open it once and keep it.
        do {
            self.archive = try Archive(url: path, accessMode: .read)
        } catch {
            throw ZarrError.invalidPath("Could not open ZIP archive at \(path.path): \(error)")
        }
    }
    
    public func get(key: String) throws -> Data? {
        lock.lock()
        defer { lock.unlock() }
        
        // ZIPFoundation's archive[key] might expect specific path format.
        // Let's try to find it explicitly to be sure.
        guard let entry = archive.first(where: { $0.path == key }) else {
            return nil
        }
        var data = Data()
        _ = try archive.extract(entry) { fragment in
            data.append(fragment)
        }
        return data
    }
    
    public func exists(key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return archive.contains(where: { $0.path == key })
    }
    
    public func list(prefix: String?) throws -> [String] {
        lock.lock()
        defer { lock.unlock() }
        
        // Archive is a Sequence of Entry
        let allKeys = archive.map { $0.path }
        
        if let prefix = prefix, !prefix.isEmpty {
            return allKeys.filter { $0.hasPrefix(prefix) }
        }
        return allKeys
    }
    
    // Read-only implementation for now
    public func set(key: String, value: Data) throws {
        throw ZarrError.unsupportedDataType("ZipStore is currently read-only")
    }
    
    public func delete(key: String) throws {
        throw ZarrError.unsupportedDataType("ZipStore is currently read-only")
    }
}
