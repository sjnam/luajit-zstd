local zstd = require "lib.resty.zstd"

local compress, decompress = zstd.compress, zstd.decompress
local compressStream = zstd.compressStream

local txt = string.rep("ABCDEFGH", 131072)

print("input size= "..#txt, "\n\ncompressed")
print("level", "size", "\n------------")

local maxlvl = zstd.maxCLevel()
for lvl=1,maxlvl do
   local encoded, err = compress(txt, lvl)
   local decoded, err = decompress(encoded)
   assert(txt == decoded)
   print(lvl, #encoded)
end


local fname = "input.txt"
local f = io.open(fname, "wb")
f:write(txt)
f:close()

assert(compressStream(fname))

assert(zstd.decompressFile("input.txt.zst", "foo.txt"))

os.remove("foo.txt")
os.remove("input.txt")
os.remove("input.txt.zst")

