# -*- encoding : ascii-8bit -*-
# frozen_string_literal: true

require './lib/ethereum_abi/constant'

module EthereumAbi
  module Utils

    extend self

    include EthereumAbi::Constant

    ##
    # Not the keccak in sha3, although it's underlying lib named SHA3
    #
    def keccak256(x)
      Digest::SHA3.new(256).digest(x)
    end

    def keccak512(x)
      Digest::SHA3.new(512).digest(x)
    end

    def keccak256_rlp(x)
      keccak256 ::RLP.encode(x)
    end

    def sha256(x)
      Digest::SHA256.digest x
    end

    def double_sha256(x)
      sha256 sha256(x)
    end

    def ripemd160(x)
      Digest::RMD160.digest x
    end

    def hash160(x)
      ripemd160 sha256(x)
    end

    def hash160_hex(x)
      encode_hex hash160(x)
    end

    def mod_exp(x, y, n)
      x.to_bn.mod_exp(y, n).to_i
    end

    def mod_mul(x, y, n)
      x.to_bn.mod_mul(y, n).to_i
    end

    def to_signed(i)
      i > Constant::INT_MAX ? (i-Constant::TT256) : i
    end

    def base58_check_to_bytes(s)
      leadingzbytes = s.match(/\A1*/)[0]
      data = Constant::BYTE_ZERO * leadingzbytes.size + BaseConvert.convert(s, 58, 256)

      raise ChecksumError, "double sha256 checksum doesn't match" unless double_sha256(data[0...-4])[0,4] == data[-4..-1]
      data[1...-4]
    end

    def bytes_to_base58_check(bytes, magicbyte=0)
      bs = "#{magicbyte.chr}#{bytes}"
      leadingzbytes = bs.match(/\A#{Constant::BYTE_ZERO}*/)[0]
      checksum = double_sha256(bs)[0,4]
      '1'*leadingzbytes.size + BaseConvert.convert("#{bs}#{checksum}", 256, 58)
    end

    def ceil32(x)
      x % 32 == 0 ? x : (x + 32 - x%32)
    end

    def encode_hex(b)
      ::RLP::Utils.encode_hex b
    end

    def decode_hex(s)
      ::RLP::Utils.decode_hex s
    end

    def big_endian_to_int(s)
      ::RLP::Sedes.big_endian_int.deserialize s.sub(/\A(\x00)+/, '')
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
      x.sub /\A\x00+/, ''
    end

    def zpad_int(n, l=32)
      zpad encode_int(n), l
    end

    def zpad_hex(s, l=32)
      zpad decode_hex(s), l
    end

    def int_to_addr(x)
      zpad_int x, 20
    end

    def encode_int(n)
      raise ArgumentError, "Integer invalid or out of range: #{n}" unless n.is_a?(Integer) && n >= 0 && n <= UINT_MAX
      int_to_big_endian n
    end

    def decode_int(v)
      raise ArgumentError, "No leading zero bytes allowed for integers" if v.size > 0 && (v[0] == Constant::BYTE_ZERO || v[0] == 0)
      big_endian_to_int v
    end

    def bytearray_to_int(arr)
      o = 0
      arr.each {|x| o = (o << 8) + x }
      o
    end

    def int_array_to_bytes(arr)
      arr.pack('C*')
    end

    def bytes_to_int_array(bytes)
      bytes.unpack('C*')
    end

    def coerce_to_int(x)
      if x.is_a?(Numeric)
        x
      elsif x.size == 40
        big_endian_to_int decode_hex(x)
      else
        big_endian_to_int x
      end
    end

    def coerce_to_bytes(x)
      if x.is_a?(Numeric)
        int_to_big_endian x
      elsif x.size == 40
        decode_hex(x)
      else
        x
      end
    end

    def coerce_addr_to_hex(x)
      if x.is_a?(Numeric)
        encode_hex zpad(int_to_big_endian(x), 20)
      elsif x.size == 40 || x.size == 0
        x
      else
        encode_hex zpad(x, 20)[-20..-1]
      end
    end

    def normalize_address(x, allow_blank: false)
      address = Address.new(x)
      raise ValueError, "address is blank" if !allow_blank && address.blank?
      address.to_bytes
    end

    def mk_contract_address(sender, nonce)
      keccak256_rlp([normalize_address(sender), nonce])[12..-1]
    end

    def mk_metropolis_contract_address(sender, initcode)
      keccak256(normalize_address(sender) + initcode)[12..-1]
    end

    def remove_0x_head(s)
      s[0,2] == '0x' ? s[2..-1] : s
    end

    def parse_int_or_hex(s)
      if s.is_a?(Numeric)
        s
      elsif s[0,2] == '0x'
        big_endian_to_int decode_hex(normalize_hex_without_prefix(s))
      else
        s.to_i
      end
    end

    def normalize_hex_without_prefix(s)
      if s[0,2] == '0x'
        (s.size % 2 == 1 ? '0' : '') + s[2..-1]
      else
        s
      end
    end

    def child_dao_list
      source = '0x4a574510c7014e4ae985403536074abe582adfc8'

      main = [
        '0xbb9bc244d798123fde783fcc1c72d3bb8c189413', # TheDAO
        '0x807640a13483f8ac783c557fcdf27be11ea4ac7a'  # TheDAO extrabalance
      ]

      child_daos = []
      child_extra_balances = []
      (1...58).each do |i|
        child_addr = "0x#{encode_hex mk_contract_address(source, i)}"
        child_daos.push child_addr
        child_extra_balances.push "0x#{encode_hex mk_contract_address(child_addr, 0)}"
      end

      main + child_daos + child_extra_balances
    end

    def debug_by_step(ext, msg, s, op, in_args, out_args, fee, opcode, pushval)
      indent = (msg.depth+1) * 5
      prefix1 = '-' * indent
      prefix2 = ' ' * indent
      prefix2[-1] = '|'

      puts "#{prefix1} ##{s.pc} 0x#{opcode.to_s(16)} #{s.gas} [#{msg.depth}]"
      puts "#{prefix2} MEM: #{s.memory.map {|byte| byte.to_s(16)}.join(' ')}"
      puts "#{prefix2} STACK: #{s.stack.map {|byte| '0x' + Utils.encode_hex(Utils.int_to_big_endian(byte)) }.join(' ')}"
      case op
      when /^PUSH/
        puts "#{prefix2} #{op} 0x#{Utils.encode_hex(Utils.int_to_big_endian(pushval))} (#{pushval})"
      when /^CREATE/
        sender = Utils.normalize_address(msg.to, allow_blank: true)
        msg_to_nonce = ext.get_nonce(msg.to)
        nonce = Utils.encode_int(ext.tx_origin == msg.to ? msg_to_nonce-1 : msg_to_nonce)
        puts "#{prefix2} #{op} 0x#{Utils.encode_hex(Utils.mk_contract_address(sender, nonce))}"
      when /^INVALID/
        # do nothing
      else
        puts "#{prefix2} #{op}"
      end
      STDIN.gets
    end

  end
end
