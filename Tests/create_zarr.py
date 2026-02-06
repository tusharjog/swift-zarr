#
#  create_zarr.py
#  SwiftZarr
#
#  Created by Tushar Jog on 1/3/26.
#

import zarr
import numpy as np
import io
import shutil
from pprint import pprint

def create_array_with_compression(path="files/example-2.zarr"):
    print(f"Creating : {path}")
    # Create a 2D Zarr array with Gzip compression
    z = zarr.create_array(
        store=path,
        shape=(100, 100),
        chunks=(10, 10),
        dtype="f4",
        compressors=zarr.codecs.GzipCodec(level=5)
    )

    # Assign data to the array
    z[:, :] = np.random.random((100, 100))
    print(z.info)
    
def create_basic_array(path="/tmp/files/example-1.zarr"):
    # Create a 2D Zarr array
    z = zarr.create_array(
        store=path,
        shape=(100, 100),
        chunks=(10, 10),
        dtype="f4"
    )

    # Assign data to the array
    z[:, :] = np.random.random((100, 100))
    print(z.info)
    
def create_hierarchical_group(path="/tmp/files/example-3.zarr"):
    # Create nested groups and add arrays
    root = zarr.group(path)
    foo = root.create_group(name="foo")
    bar = root.create_array(
        name="bar", shape=(100, 10), chunks=(10, 10), dtype="f4"
    )
    spam = foo.create_array(name="spam", shape=(10,), dtype="i4")

    # Assign values
    bar[:, :] = np.random.random((100, 10))
    spam[:] = np.arange(10)

    # print(root.tree())
    print(root.info)
    
def create_nested_groups(path="/tmp/files/example-4.zarr"):
    # Create nested groups and add arrays
    root = zarr.group(path, attributes={'name': 'root'})
    foo = root.create_group(name="foo")
    bar = root.create_array(
        name="bar", shape=(100, 10), chunks=(10, 10), dtype="f4"
    )
    nodes = {'': root.metadata} | {k: v.metadata for k,v in root.members()}
    # Report nodes
    output = io.StringIO()
    pprint(nodes, stream=output, width=60, depth=3)
    result = output.getvalue()
    print(result)
    # Create new hierarchy from nodes
    new_nodes = dict(zarr.create_hierarchy(store=zarr.storage.MemoryStore(), nodes=nodes))
    new_root = new_nodes['']
    assert new_root.attrs == root.attrs
    print(root.info)
    
def create_single_file_store(path="/tmp/files/example-5.zip"):
    # Store the array in a ZIP file
    store = zarr.storage.ZipStore(path, mode="w")

    z = zarr.create_array(
        store=store,
        shape=(100, 100),
        chunks=(10, 10),
        dtype="f4"
    )

    # write to the array
    z[:, :] = np.random.random((100, 100))

    # the ZipStore must be explicitly closed
    store.close()
    
    # Open the ZipStore in read-only mode
    store = zarr.storage.ZipStore(path, read_only=True)

    z = zarr.open_array(store, mode='r')

    # read the data as a NumPy Array
    print(z[:])

def create_zip_zarr(path="files/example.zarr.zip"):
    # Store the array in a ZIP file
    # Ensure parent directory exists
    import os
    os.makedirs(os.path.dirname(path), exist_ok=True)
    
    store = zarr.storage.ZipStore(path, mode="w")

    z = zarr.create_array(
        store=store,
        shape=(50, 50),
        chunks=(10, 10),
        dtype="i4",
        fill_value=0,
        compressors=None
    )

    # write some data
    z[0, 0] = 123
    z[49, 49] = 456

    # the ZipStore must be explicitly closed
    store.close()

if __name__ == "__main__":
    create_basic_array()
    create_array_with_compression()
    create_hierarchical_group()
    create_single_file_store()
    create_nested_groups()
