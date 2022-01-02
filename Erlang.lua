Erlang = (function()

  TAG = {
    VERSION = 131,
    COMPRESSED_ZLIB = 80,
    NEW_FLOAT_EXT = 70,
    BIT_BINARY_EXT = 77,
    ATOM_CACHE_REF = 78,
    NEW_PID_EXT = 88,
    NEW_PORT_EXT = 89,
    NEWER_REFERENCE_EXT = 90,
    SMALL_INTEGER_EXT = 97,
    INTEGER_EXT = 98,
    FLOAT_EXT = 99,
    ATOM_EXT = 100,
    REFERENCE_EXT = 101,
    PORT_EXT = 102,
    PID_EXT = 103,
    SMALL_TUPLE_EXT = 104,
    LARGE_TUPLE_EXT = 105,
    NIL_EXT = 106,
    STRING_EXT = 107,
    LIST_EXT = 108,
    BINARY_EXT = 109,
    SMALL_BIG_EXT = 110,
    LARGE_BIG_EXT = 111,
    NEW_FUN_EXT = 112,
    EXPORT_EXT = 113,
    NEW_REFERENCE_EXT = 114,
    SMALL_ATOM_EXT = 115,
    MAP_EXT = 116,
    FUN_EXT = 117,
    ATOM_UTF8_EXT = 118,
    SMALL_ATOM_UTF8_EXT = 119
  };

  local function unpack(fmt, s)
    local value, next = string.unpack('>' .. fmt, s);
    local rest = s:sub(next);
    return value, rest;
  end;

  local atoms = {};
  function atom(str)
    if(#str == 0 or str == nil) then error('Invalid atom'); end;
    if(not atoms[str]) then
      atoms[str] = setmetatable(
        { ATOM = str },
        { __tostring = function() return 'Erlang Atom :' .. str; end}
      );
    end;
    return atoms[str];
  end

  function tuple(t)
    local tbl = { __type = 'tuple'; };
    for k,v in pairs(t) do tbl[k] = v; end;
    return tbl;
  end;

  local function hex(s)
    return s:gsub('.', function(c) return ('%02x'):format(string.byte(c)) end);
  end;

  local Decoders = {
    [TAG.BINARY_EXT] = 's4',
    [TAG.NEW_FLOAT_EXT] = 'd',
    [TAG.SMALL_INTEGER_EXT] = 'B',
    [TAG.INTEGER_EXT] = 'I4'
  };

  local function decodeTag(s)
    local tag, s = unpack('B', s);
    if(Decoders[tag]) then
      if(type(Decoders[tag]) == 'function') then
        return Decoders[tag](s);
      elseif(type(Decoders[tag]) == 'string') then
        return unpack(Decoders[tag], s);
      end;
    else
      for k,v in pairs(TAG) do
        if(v == tag) then
          error('Unimplemented tag: ' .. k);
        end;
      end;
      error('Unrecognised tag: ' .. tag);
    end;
  end;

  Decoders[TAG.ATOM_EXT] = function(s)
    local str, s = unpack('s2', s);
    return atom(str), s;
  end;

  -- Decoders[TAG.NEW_PID_EXT] = function(s)
  --   local node, id, serial, creation = string.unpack('>xs2I4I4I4', s);
  --   print(node, id, serial, creation);
  -- end;

  local function decodeTuple(s, sizeFmt)
    local elements, s = unpack(sizeFmt, s);
    local t, elem = {};
    for i=1, elements do
      elem, s = decodeTag(s);
      table.insert(t, elem);
    end;
    return Erlang.tuple(t), s;
  end;

  Decoders[TAG.NIL_EXT] = function(s)
    return {}, s;
  end;

  Decoders[TAG.SMALL_TUPLE_EXT] = function(s)
    return decodeTuple(s, 'B');
  end;

  Decoders[TAG.LARGE_TUPLE_EXT] = function(s)
    return decodeTuple(s, 'I4');
  end;

  Decoders[TAG.MAP_EXT] = function(s)
    local elements, s = unpack('I4', s);
    local t,k,v = {};
    for i=1, elements do
      k, s = decodeTag(s);
      v, s = decodeTag(s);
      t[k] = v;
    end;
    return t, s;
  end;

  Decoders[TAG.LIST_EXT] = function(s)
    local elements, s = unpack('I4', s);
    local t, elem = {};
    for i=1, elements do
      elem, s = decodeTag(s);
      table.insert(t, elem);
    end;
    local tail, s = decodeTag(s);
    if(type(tail) ~= 'table' or next(tail) ~= nil) then
      table.insert(t, tail);
    end;
    return t, s;
  end;

  Decoders[TAG.STRING_EXT] = function(s)
    local length, s = unpack('I2', s);
    local list = {string.unpack(string.rep('B', length), s)};
    s = s:sub(table.remove(list));
    return list, s;
  end;

  Decoders[TAG.SMALL_BIG_EXT] = function(s)
    local length, s = unpack('B', s);
    local sign, s = unpack('B', s);
    local num, byte = 0 - sign;
    for i=0, length-1 do
      byte, s = unpack('B', s);
      num = num + byte << (i*8);
    end;
    return num, s;
  end;

  -- [[ Unsupported due to lack of bignum support ]]
  -- Decoders[TAG.LARGE_BIG_EXT] = function(s)
  --   local length, s = unpack('I4', s);
  --   print('bignum length', length);
  --   local sign, s = unpack('B', s);
  --   local num, byte = 0 - sign;
  --   for i=0, length-1 do
  --     byte, s = unpack('B', s);
  --     num = num + byte << (i*8);
  --     print(num)
  --   end;
  --   return num, s;
  -- end;

  function decode(s)

    if(#s == 0) then return nil; end;

    local version, s = unpack('B', s);
    if(version ~= TAG.VERSION) then
      error(("Wrong Erlang version: %d"):format(version));
    end;

    return (decodeTag(s));

  end

  return {
    decode = decode,
    atom = atom,
    tuple = tuple
  };

end)();