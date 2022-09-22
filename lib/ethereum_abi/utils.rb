# -*- encoding : ascii-8bit -*-
# frozen_string_literal: true

require "./lib/ethereum_abi/constant"

module EthereumAbi
  module Utils
    extend self

    include EthereumAbi::Constant

    def ceil32(x)
      (x % 32).zero? ? x : (x + 32 - x % 32)
    end

    def encode_hex(b)
      ::RLP::Utils.encode_hex b
    end

    def decode_hex(s)
      ::RLP::Utils.decode_hex s
    end

    def big_endian_to_int(s)
      ::RLP::Sedes.big_endian_int.deserialize s.sub(/\A(\x00)+/, "")
    end

    def int_to_big_endian(n)
      ::RLP::Sedes.big_endian_int.serialize n
    end

    def lpad(x, symbol, l)
      return x if x.size >= l

      symbol * (l - x.size) + x
    end

    def rpad(x, symbol, l)
      return x if x.size >= l

      x + symbol * (l - x.size)
    end

    def zpad(x, l)
      lpad x, BYTE_ZERO, l
    end

    def zunpad(x)
      x.sub(/\A\x00+/, "")
    end

    def zpad_int(n, l = 32)
      zpad encode_int(n), l
    end

    def zpad_hex(s, l = 32)
      zpad decode_hex(s), l
    end

    def encode_int(n)
      raise ArgumentError, "Integer invalid or out of range: #{n}" unless n.is_a?(Integer) && n >= 0 && n <= UINT_MAX

      int_to_big_endian n
    end

    def decode_int(v)
      if v.size.positive? && (v[0] == Constant::BYTE_ZERO || v[0].zero?)
        raise ArgumentError,
              "No leading zero bytes allowed for integers"
      end

      big_endian_to_int v
    end
  end
end
