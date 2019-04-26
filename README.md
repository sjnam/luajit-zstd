Name
====
luajit-zstd - facebook [zstandard](https://github.com/facebook/zstd) ffi binding


Installation
============
To install `luajit-zstd` you need to install
[Zstandard](https://github.com/facebook/zstd#build)
with shared libraries firtst.
Then you can install `luajit-zstd` by placing `lib/zstd.lua` to
your lua library path.

Example
=======
```` lua
local zstandard = require "zstd"
local zstd = zstandard:new()
local txt = string.rep("ABCD", 1000)
print("Uncompressed size:", #txt)
local c, err = zstd:compress(txt)
print("Compressed size:", #c)
local txt2, err = zstd:decompress(c)
assert(txt == txt2)
zstd:free()
````

Methods
=======

new
---
`syntax: zstd = zstandard:new()`

Create cstream and dstream.

free
----
`syntax: zstd:free()`

Free cstream and dstream.

compress
--------
`syntax: encoded_buffer, err = zstd:compress(input_buffer, clvl)`

Compresses the data in input_buffer into encoded_buffer.

decompress
----------
`syntax: decoded_buffer, err = zstd:decompress(encoded_buffer)`

Decompresses the data in encoded_buffer into decoded_buffer.

compressFile
--------------
`syntax: ok, err = zstd:compressFile(path, clvl?)`

Compresses the input file with clvl compression level.

decompressFile
--------------
`syntax: ok, err = zstd:decompressFile(fname, outname?)`

Decompress the input file fname.

compressFileUsingDictionary
--------------
`syntax: ok, err = zstd:compressFileUsingDictionary(path, dict, clvl?)`

Compresses the input file with clvl compression level using a digested Dictionary.

decompressFileUsingDictionary
--------------
`syntax: ok, err = zstd:decompressFileUsingDictionary(fname, dict, outname?)`

Decompress the input file fname using a digested Dictionary.

Author
======
Soojin Nam jsunam@gamil.com

License
=======
Public Domain
