# Erlang.lua

**Erlang.lua** is a Lua library for parsing Erlang's [External Term Format](https://www.erlang.org/doc/apps/erts/erl_ext_dist.html).

## Usage

```lua

  require('Erlang');

  local my_atom = Erlang.decode('\x83\x64\x00\x04\x74\x65\x73\x74');
  print(my_atom);
  -- prints:
  -- Erlang Atom :test

  local my_list = Erlang.decode('\x83\x6b\x00\x02\x01\x02');
  print(my_list[1], my_list[2]);
  -- prints:
  -- 1    2

```

## Erlang To Lua

The Erlang/Lua data type mapping is as follows:

| Erlang Type | Lua Type                                |
| ----------- | -------------                           |
| List        | Table                                   |
| Map         | Table                                   |
| Atom        | `Erlang.atom()` *(table)*                 |
| Integer     | Integer (5.3) or Number (5.2 & earlier) |
| Tuple       | Table                                   |
| Binary      | String                                  |

## Erlang types in Lua tables

Most complex Erlang data types (lists, maps, tuples, etc) can be represented as Lua tables.
In order to preserve the information about the underlying Erlang data type, the data type is recorded in a `__type` key in the table's *metatable*.

This library includes helper functions that set this type field:
 - `Erlang.map(tbl)`
 - `Erlang.list(tbl)` - also removes non-numeric keys
 - `Erlang.tuple(tbl)`
 - `Erlang.atom(name)`

It also includes a function to get the Erlang type: `Erlang.type(obj)`.