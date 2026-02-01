#
#  create_zarr.py
#  SwiftZarr
#
#  Created by Tushar Jog on 1/3/26.
#

import zarr
import numpy as np


def example_2(path="files/example-2.zarr"):
    # Create a 2D Zarr array with Blosc compression
    z = zarr.create_array(
        store=path,
        shape=(100, 100),
        chunks=(10, 10),
        dtype="f4",
        compressors=zarr.codecs.BloscCodec(
            cname="zstd",
            clevel=3,
            shuffle=zarr.codecs.BloscShuffle.shuffle
        )
    )

    # Assign data to the array
    z[:, :] = np.random.random((100, 100))
    print(z.info)

if __name__ == "__main__":
    example_2()
