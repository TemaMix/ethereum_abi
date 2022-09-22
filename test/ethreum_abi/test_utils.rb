# -*- encoding : ascii-8bit -*-
# frozen_string_literal: true

require "test_helper"

class TestUtils < Minitest::Test
  include EthereumAbi::Utils

  def test_ceil32
    assert_equal 0,   ceil32(0)
    assert_equal 32,  ceil32(1)
    assert_equal 256, ceil32(256)
    assert_equal 256, ceil32(250)
  end

  def test_big_endian_to_int
    assert_equal 255, big_endian_to_int("\xff")
    assert_equal 255, big_endian_to_int("\x00\x00\xff")
  end

  def test_decode_hex
    assert_raises(TypeError) { decode_hex("xxxx") }
    assert_raises(TypeError) { decode_hex("\x00\x00") }
  end
end
