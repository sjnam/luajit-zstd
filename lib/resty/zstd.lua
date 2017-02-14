local ffi = require "ffi"

local ffi_new = ffi.new
local ffi_str = ffi.string
local ffi_load = ffi.load
local ffi_copy = ffi.copy
local ffi_gc = ffi.gc
local C = ffi.C

local assert = assert
local tonumber = tonumber
local tab_insert = table.insert
local tab_concat = table.concat


local _M = { _VERSION = '0.01' }


ffi.cdef[[
unsigned ZSTD_versionNumber(void);

size_t ZSTD_compress( void* dst, size_t dstCapacity,
                      const void* src, size_t srcSize,
                      int compressionLevel);
size_t ZSTD_decompress( void* dst, size_t dstCapacity,
                        const void* src, size_t compressedSize);

int    ZSTD_maxCLevel(void);
size_t    ZSTD_compressBound(size_t srcSize);
unsigned    ZSTD_isError(size_t code);
const char* ZSTD_getErrorName(size_t code);

size_t ZSTD_getFrameCompressedSize(const void* src, size_t srcSize);
unsigned long long ZSTD_getFrameContentSize(const void *src, size_t srcSize);
unsigned long long ZSTD_findDecompressedSize(const void* src, size_t srcSize);

typedef struct ZSTD_inBuffer_s {
  const void* src;
  size_t size;
  size_t pos;
} ZSTD_inBuffer;

typedef struct ZSTD_outBuffer_s {
  void*  dst;
  size_t size;
  size_t pos;
} ZSTD_outBuffer;

typedef struct ZSTD_CStream_s ZSTD_CStream;
ZSTD_CStream* ZSTD_createCStream(void);
size_t ZSTD_freeCStream(ZSTD_CStream* zcs);
size_t ZSTD_initCStream(ZSTD_CStream* zcs, int compressionLevel);
size_t ZSTD_compressStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output, ZSTD_inBuffer* input);
size_t ZSTD_flushStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output);
size_t ZSTD_endStream(ZSTD_CStream* zcs, ZSTD_outBuffer* output);
size_t ZSTD_CStreamInSize(void);
size_t ZSTD_CStreamOutSize(void);

typedef struct ZSTD_DStream_s ZSTD_DStream;
ZSTD_DStream* ZSTD_createDStream(void);
size_t ZSTD_freeDStream(ZSTD_DStream* zds);
size_t ZSTD_initDStream(ZSTD_DStream* zds);
size_t ZSTD_decompressStream(ZSTD_DStream* zds, ZSTD_outBuffer* output, ZSTD_inBuffer* input);
size_t ZSTD_DStreamInSize(void);
size_t ZSTD_DStreamOutSize(void);
]]


local zstd = ffi_load("zstd")


local function _ZSTD_maxCLevel ()
   return tonumber(zstd.ZSTD_maxCLevel())
end
_M.maxCLevel = _ZSTD_maxCLevel


local function _ZSTD_compress (fBuff, clvl)
   local fSize = #fBuff
   local cBuffSize = zstd.ZSTD_compressBound(fSize);
   local cBuff = ffi_new("uint8_t[?]", cBuffSize)
   local cSize = zstd.ZSTD_compress(cBuff, cBuffSize, fBuff, fSize, clvl or 1)
   if zstd.ZSTD_isError(cSize) ~= 0 then
      local errStr = zstd.ZSTD_getErrorName(cSize)
      return nil, "error compressing: " .. errStr
   end

   ffi_gc(cBuff, free)
   return ffi_str(cBuff, cSize)
end
_M.compress = _ZSTD_compress


local function _ZSTD_decompress (cBuff)
   local cSize = #cBuff
   local rSize = zstd.ZSTD_findDecompressedSize(cBuff, cSize);
   if rSize == 0 then
      return nil, "original size unknown. Use streaming decompression instead"
   end
   local rBuff = ffi_new("uint8_t[?]", rSize)
   local dSize = zstd.ZSTD_decompress(rBuff, rSize, cBuff, cSize)
   if dSize ~= rSize then
      local errStr = zstd.ZSTD_getErrorName(dSize)
      return nil, "error decoding: " .. errStr
   end

   ffi_gc(rBuff, free)
   return ffi_str(rBuff, dSize)
end
_M.decompress = _ZSTD_decompress


local function _ZSTD_compressStream (src, cLevel)
   local buffInSize = zstd.ZSTD_CStreamInSize();
   local buffIn = ffi_new("uint8_t[?]", buffInSize);
   local buffOutSize = zstd.ZSTD_CStreamOutSize();
   local buffOut = ffi_new("uint8_t[?]", buffOutSize);

   local cstream = zstd.ZSTD_createCStream();
   if not cstream then
      return nil, "ZSTD_createCStream() error"
   end
   local initResult = zstd.ZSTD_initCStream(cstream, cLevel);
   if zstd.ZSTD_isError(initResult) ~= 0 then
      return nil, "ZSTD_initCStream() error: " .. zstd.ZSTD_getErrorName(initResult)
   end

   local inputLen = #src
   local buff = ffi_new("uint8_t[?]", inputLen, src)
   local p = buff

   local toRead = buffInSize;
   local result = {}
   while inputLen > 0 do
      if inputLen <= buffInSize then
         toRead = inputLen
      end
      ffi_copy(buffIn, ffi_str(p, toRead))
      local input = ffi_new("ZSTD_inBuffer[1]")
      input[0] = {buffIn, toRead, 0}
      while input[0].pos < input[0].size do
         local output = ffi_new("ZSTD_outBuffer[1]")
         output[0] = {buffOut, buffOutSize, 0}
         toRead = zstd.ZSTD_compressStream(cstream, output, input);
         if zstd.ZSTD_isError(toRead) ~= 0 then
            local errStr = ZSTD_getErrorName(toRead)
            return nil, "ZSTD_compressStream() error: "..errStr 
         end
         if toRead > buffInSize then
            toRead = buffInSize
         end
         tab_insert(result, ffi_str(buffOut, output[0].pos))
      end
      inputLen = inputLen - toRead
      p = p + toRead
   end

   zstd.ZSTD_freeCStream(cstream);
   return tab_concat(result)
end
_M.compressStream = _ZSTD_compressStream


return _M

