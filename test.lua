local zstandard = require "lib.resty.zstd"

local zstd = zstandard:new()

local txt = string.rep("ABCDEFGH", 131072)

print("input size= "..#txt, "\n\ncompressed")
print("level", "size", "\n------------")

local maxlvl = zstd:maxCLevel()
for lvl=1,maxlvl do
   local encoded, err = zstd:compress(txt, lvl)
   print(lvl, #encoded)
   local decoded, err = zstd:decompress(encoded)
   assert(txt == decoded)
end

--

local fname = "input.txt"
local f = io.open(fname, "wb")
f:write(txt)
f:close()

assert(zstd:compressFile(fname))

assert(zstd:decompressFile("input.txt.zst", "foo.txt"))

zstd:free()

local f1 = io.open("input.txt")
local f2 = io.open("foo.txt")
assert(f1:read("*a") == f2:read("*a"))
f1:close()
f2:close()

os.remove("foo.txt")
os.remove("input.txt")
os.remove("input.txt.zst")

print("\nOK")
