local zstandard = require "zstd"

local zstd = zstandard:new()

local txt = string.rep("ABCDEFGH", 131072)

local fname = "input.txt"
local f = io.open(fname, "wb")
f:write(txt)
f:close()

assert(zstd:compressFileUsingCDict(fname, "dictionary"))
print("Compress string and save to 'input.txt.zst'")

assert(zstd:decompressFileUsingDDict("input.txt.zst", "foo.txt", "dictionary"))
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
