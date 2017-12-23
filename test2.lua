local zstandard = require "lib.resty.zstd"

local zstd = zstandard:new()

local txt = string.rep("ABCDEFGH", 131072)

local fname = "input.txt"
local f = io.open(fname, "wb")
f:write(txt)
f:close()

assert(zstd:compressFile(fname))
print("Compress string and save to 'input.txt.zst'")

assert(zstd:decompressFile("input.txt.zst", "foo.txt"))
print("Decompress file 'input.txt.zst' to 'foo.txt'")

zstd:free()

local f1 = io.open("input.txt")
local f2 = io.open("foo.txt")

assert(f1:read("*a") == f2:read("*a"))
print("Compare 'input.txt' and 'foo.txt'")
print("OK")

f1:close()
f2:close()

os.remove("foo.txt")
os.remove("input.txt")
os.remove("input.txt.zst")
