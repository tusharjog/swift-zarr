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

extension Encodable {
    func prettyPrintJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let encodedData = try? encoder.encode(self) else {
            print("Failed to encode data")
            return
        }
        
        let prettyJSONString = String(decoding: encodedData, as: UTF8.self)
        print(prettyJSONString)
    }
}



// MARK: - JSON Value type

public enum JSONValue: Codable, Equatable, Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case dictionary([String: JSONValue])
    case null
    
    public var isNumeric : Bool {
        switch self {
        case .number:
            return true
        default: return false
        }
    }
    


    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        }
        else if let x = try? container.decode(String.self)   {
            self = .string(x)
        }
        else if let x = try? container.decode(Bool.self)   {
            self = .bool(x)
        }
        else if let x = try? container.decode(Double.self)   {
            self = .number(x)
        }
        else if let x = try? container.decode([JSONValue].self)   {
            self = .array(x)
        }
        else if let x = try? container.decode([String: JSONValue].self)   {
            self = .dictionary(x)
        }
        else {
            //throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSON value")
            throw ZarrError.unsupportedDataType("Unknown data type: \(container)")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null:
            try container.encodeNil()
        case .string(let x):
            try container.encode(x)
        case .number(let x):
            try container.encode(x)
        case .bool(let x):
            try container.encode(x)
        case .array(let x):
            try container.encode(x)
        case .dictionary(let x):
            try container.encode(x)
        }
    }
}

//
// Convenience initializers for ZarrDataType
//
extension JSONValue : ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}

extension JSONValue : ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        //self = value ? .customMirror("b") : .null
        self = .bool(value)
    }
}

// TODO add more


// Convenience accessors
extension JSONValue {
    public var boolValue: Bool? {
        if case .bool(let v) = self {
            return v
        } else {
            return nil
        }
    }
    
    public var stringValue: String? {
        if case .string(let v) = self {
            return v
        } else {
            return nil
        }
    }

    public var doubleValue: Double? {
        if case .number(let v) = self {
            return v
        } else {
            return nil
        }
    }
    
    public var intValue: Int? {
        if case .number(let v) = self {
            return Int(v)
        } else {
            return nil
        }
    }
}

// TODO add more

extension JSONValue {
    public var isNull: Bool {
        self == .null
    }
}



