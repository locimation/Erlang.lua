require('./Erlang');

function TTB(term)
  term = term:gsub('"', '\\"');
  local cmd = 'elixir -e "import :erlang, only: [term_to_binary: 1]; IO.write term_to_binary(%s)"';
  return io.popen(cmd:format(term)):read('*all');
end;

---@diagnostic disable: undefined-global
describe('Erlang.lua', function()

  describe('Decoder', function()

    it('should return nil for empty string', function()
      assert.are.same(Erlang.decode(''), nil);
    end);

    it('should reject invalid version numbers', function()
      assert.has_error(function() Erlang.decode('\100') end, "Wrong Erlang version: 100");
    end);

    it('should decode an atom', function()
      local term = TTB(":apple");
      assert.are.equals(Erlang.atom('apple'), Erlang.decode(term));
    end);

    it('should decode a string', function()
      local term = TTB('"testing"');
      assert.are.same("testing", Erlang.decode(term));
    end);

    it('should decode a float', function()
      local term = TTB('2.0');
      assert.are.same(2.0, Erlang.decode(term));
    end);

    it('should decode a small integer', function()
      local term = TTB('2');
      assert.are.same(2, Erlang.decode(term));
    end);

    it('should decode a larger integer', function()
      local term = TTB('4000');
      assert.are.same(4000, Erlang.decode(term));
    end);

    -- it('should decode a PID', function()
    --   local term = TTB('self()');
    --   assert.are.equals(2, Erlang.decode(term));
    -- end);

    it('should decode a short tuple', function()
      local term = TTB('{:data, 8, "somedata"}');
      assert.are.same(
        Erlang.tuple(
          {Erlang.atom('data'), 8, "somedata"}
        ),
        Erlang.decode(term)
      );
    end);

    it('should decode a long tuple', function()
      local term = TTB('{' .. string.rep('0,', 1000) .. '}');
      local tbl = {}; for i=1,1000 do tbl[i] = 0; end;
      assert.are.same(
        Erlang.tuple(tbl),
        Erlang.decode(term)
      );
    end);

    it('should decode a map', function()
      local term = TTB('%{"a" => 1, :b => 2, "c" => "foo"}');
      assert.are.same(
        {a = 1, [Erlang.atom('b')] = 2, c = "foo"},
        Erlang.decode(term)
      );
    end);

    it('should decode a list', function()
      local term = TTB('[1, "two", 3]');
      assert.are.same(
        {1, "two", 3},
        Erlang.decode(term)
      );
    end);

    it('should decode a list of bytes', function()
      local term = TTB('[1,2]');
      assert.are.same(
        {1,2},
        Erlang.decode(term)
      );
    end);

    it('should decode an improper list', function()
      local term = TTB('[1 | "two"]');
      assert.are.same(
        {1, "two"},
        Erlang.decode(term)
      );
    end);

    it('should decode a small bignum', function()
      local term = TTB('0x100000000');
      assert.are.same(
        0x100000000,
        Erlang.decode(term)
      );
    end);

    -- it('should decode a large bignum', function()
    --   local term = (
    --     '836F000001010000000000000000000000000000000000000000000000000000000000000000' ..
    --     '0000000000000000000000000000000000000000000000000000000000000000000000000000' ..
    --     '0000000000000000000000000000000000000000000000000000000000000000000000000000' ..
    --     '0000000000000000000000000000000000000000000000000000000000000000000000000000' ..
    --     '0000000000000000000000000000000000000000000000000000000000000000000000000000' ..
    --     '0000000000000000000000000000000000000000000000000000000000000000000000000000' ..
    --     '000000000000000000000000000000000000000000000000000000000000000000000001'
    --   ):gsub('..', function(hex) return string.char(tonumber(hex, 16)) end)
    --   assert.are.same(
    --     1000 ^ 100,
    --     Erlang.decode(term)
    --   );
    -- end);

  end);

end);