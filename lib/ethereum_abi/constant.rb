# -*- encoding : ascii-8bit -*-
# frozen_string_literal: true

module EthereumAbi
  module Constant
    BYTE_EMPTY = ""
    BYTE_ZERO = "\x00"
    BYTE_ONE  = "\x01"

    TT32  = 2**32
    TT256 = 2**256
    TT64M1 = 2**64 - 1

    UINT_MAX = 2**256 - 1
    UINT_MIN = 0
    INT_MAX = 2**255 - 1
    INT_MIN = -2**255

    HASH_ZERO = ("\x00" * 32).freeze

    PUBKEY_ZERO = ("\x00" * 32).freeze
    PRIVKEY_ZERO = ("\x00" * 32).freeze
    PRIVKEY_ZERO_HEX = ("0" * 64).freeze
  end
end
