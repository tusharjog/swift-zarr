//
//  ZarrMetadata.swift
//  ZarrSwift
//
//  Created by Tushar Jog on 12/29/25.
//

import Foundation

// https://zarr-specs.readthedocs.io/en/latest/v3/core/index.html#metadata

// MARK : Group Metadata
//
//
public struct ZarrGroupMetaData: Codable {
    public let zarrFormat: Int
    public let nodeType: ZarrNodeType
    // Attributes are optional
    public let attributes: [String: ZarrDataType]?
    
    enum CodingKeys : String, CodingKey {
        case zarrFormat = "zarr_format"
        case nodeType = "node_type"
        case attributes
    }
    
    public init(attributes: [String : ZarrDataType]?) {
        self.zarrFormat = 3
        self.nodeType = ZarrNodeType.group
        self.attributes = attributes
    }
}

// MARK : Array Metadata

/*
 {
     "zarr_format": 3,
     "node_type": "array",
     "shape": [10000, 1000],
     "dimension_names": ["rows", "columns"],
     "data_type": "float64",
     "chunk_grid": {
         "name": "regular",
         "configuration": {
             "chunk_shape": [1000, 100]
         }
     },
     "chunk_key_encoding": {
         "name": "default",
         "configuration": {
             "separator": "/"
         }
     },
     "codecs": [{
         "name": "bytes",
         "configuration": {
             "endian": "little"
         }
     }],
     "fill_value": "NaN",
     "attributes": {
         "foo": 42,
         "bar": "apples",
         "baz": [1, 2, 3, 4]
     }
 }
 */

public struct ZarrArrayMetaData : Codable {
    public let zarrFormat: Int
    public let nodeType: ZarrNodeType
    // An array of integers providing the length of each dimension of the Zarr array. For example, a value [10, 20] indicates a two-dimensional Zarr array, where the first dimension has length 10 and the second dimension has length 20.
    public let shape : [Int]
    public let dataType : ZarrDataType
    public let chunkGrid : ZarrChunkGrid
    public let chunkKeyEncoding : ZarrChunkKeyEncoding
    public let fillValue : FillValue
    public let codecs : [ZarrCodecConfiguration]
    
    // Attributes are optional
    public let attributes: [String: ZarrDataType]?
    
    enum CodingKeys : String, CodingKey {
        case zarrFormat = "zarr_format"
        case nodeType = "node_type"
        case shape
        case dataType = "data_type"
        case chunkGrid = "chunk_grid"
        case chunkKeyEncoding = "chunk_key_encoding"
        case fillValue = "fill_value"
        case codecs
        case attributes
    }
    
    public init(shape: [Int], dataType: ZarrDataType, chunkGrid: ZarrChunkGrid, chunkKeyEncoding: ZarrChunkKeyEncoding, fillValue: FillValue, codecs: [ZarrCodecConfiguration], attributes: [String : ZarrDataType]?) {
        self.zarrFormat = 3
        self.nodeType = .array

        self.shape = shape
        self.dataType = dataType
        self.chunkGrid = chunkGrid
        self.chunkKeyEncoding = chunkKeyEncoding
        self.fillValue = fillValue
        self.codecs = codecs
        self.attributes = attributes
    }
}
