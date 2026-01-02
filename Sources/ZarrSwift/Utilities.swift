//
//  Utilities.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 1/1/26.
//

import Foundation

func deleteFileOrFolderIfExists(at url: URL) {
    let fileManager = FileManager.default
    
    // Check if the file/folder exists at the provided path
    if fileManager.fileExists(atPath: url.path) {
        do {
            try fileManager.removeItem(at: url)
            print("File/Folder \(url) deleted successfully.")
        } catch {
            print("Error deleting folder: \(error.localizedDescription)")
        }
    } else {
        print("File/Folder \(url) does not exist.")
    }
}
