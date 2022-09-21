# -*- encoding : ascii-8bit -*-
# frozen_string_literal: true

require "spec_helper"

RSpec.describe EthereumAbi do
  shared_examples "Encode ABI for type" do |type, values|
    it "encodes #{type} value" do
      values.each do |value|
        expect(
          EthereumAbi.encode_primitive_type(EthereumAbi::Type.parse(type), value)
        ).to eq(EthereumAbi.encode_abi([type], [value]))
      end
    end
  end

  describe ".encode_abi" do
    include_examples("Encode ABI for type", "int8", [1, -1, 127, -128])
    include_examples("Encode ABI for type", "int32", [1, -1, 127, -128, 2**31 - 1, -2**31])
    include_examples("Encode ABI for type", "int256", [1, -1, 127, -128, 2**31 - 1, -2**31, 2**255 - 1, -2**255])
  end

  describe ".encode_type" do
  end

  shared_examples "Encode ABI for primitive type" do |type, values|
    it "encodes #{type} value" do
      values.each do |value|
        expect(
          EthereumAbi.encode_primitive_type(EthereumAbi::Type.parse(type), value)
        ).to eq(EthereumAbi.encode_abi([type], [value]))
      end
    end
  end

  describe ".encode_primitive_type" do
    it "encodes bool type" do
      type = EthereumAbi::Type.parse "bool"
      expect(EthereumAbi.encode_primitive_type(type, true)).to eq(EthereumAbi::Utils.zpad_int(1))
      expect(EthereumAbi.encode_primitive_type(type, false)).to eq(EthereumAbi::Utils.zpad_int(0))
    end

    it "encodes uint8 type" do
      type = EthereumAbi::Type.parse "uint8"
      expect(EthereumAbi.encode_primitive_type(type, 255)).to eq(EthereumAbi::Utils.zpad_int(255))
      expect { EthereumAbi.encode_primitive_type(type, 256) }.to raise_error(EthereumAbi::ValueOutOfBounds)
    end

    it "encodes ufixed128x128 type" do
      type = EthereumAbi::Type.parse "ufixed128x128"
      # expect(EthereumAbi.encode_primitive_type(type, 0)).to eq("\x00"*32)
      # expect(EthereumAbi.encode_primitive_type(type, 1.125)).to eq("\x00"*15 + "\x01\x20" + "\x00"*15)
      expect(EthereumAbi.encode_primitive_type(type, 2**127 - 1)).to eq("\x7F#{"\xff" * 15}#{"\x00" * 16}")
    end

    it "encodes fixed128x128 type" do
      type = EthereumAbi::Type.parse "fixed128x128"
      expect(EthereumAbi.encode_primitive_type(type, -1)).to eq("\xff" * 16 + "\x00" * 16)
      expect(EthereumAbi.encode_primitive_type(type, -2**127)).to eq("\x80#{"\x00" * 31}")
      expect(EthereumAbi.encode_primitive_type(type, 2**127 - 1)).to eq("\x7F#{"\xff" * 15}#{"\x00" * 16}")
      expect(EthereumAbi.encode_primitive_type(type, 1.125)).to eq("#{EthereumAbi::Utils.zpad_int(1, 16)}\x20#{"\x00" * 15}")
      expect(EthereumAbi.encode_primitive_type(type, -1.125)).to eq("#{"\xff" * 15}\xfe\xe0#{"\x00" * 15}")
      expect { EthereumAbi.encode_primitive_type(type, -2**127 - 1) }.to raise_error(EthereumAbi::ValueOutOfBounds)
      expect { EthereumAbi.encode_primitive_type(type, 2**127) }.to raise_error(EthereumAbi::ValueOutOfBounds)
    end

    it "encodes byte type" do
      type = EthereumAbi::Type.parse "bytes"
      expect(
        EthereumAbi.encode_primitive_type(type, "\x01\x02\x03")
      ).to eq("#{EthereumAbi::Utils.zpad_int(3)}\x01\x02\x03#{"\x00" * 29}")
    end

    it "encodes fixed128x128 type" do
      type = EthereumAbi::Type.parse "bytes8"
      expect(
        EthereumAbi.encode_primitive_type(type, "\x01\x02\x03")
      ).to eq("\x01\x02\x03#{"\x00" * 29}")
    end

    it "encodes hash32 type" do
      type = EthereumAbi::Type.parse "hash32"
      expect(
        EthereumAbi.encode_primitive_type(type, "\xff" * 32)
      ).to eq("\xff" * 32)
      expect(
        EthereumAbi.encode_primitive_type(type, "ff" * 32)
      ).to eq("\xff" * 32)
    end

    it "encodes address type" do
      type = EthereumAbi::Type.parse "address"
      expect(
        EthereumAbi.encode_primitive_type(type, "\xff" * 20)
      ).to eq(EthereumAbi::Utils.zpad("\xff" * 20, 32))
      expect(
        EthereumAbi.encode_primitive_type(type, "ff" * 20)
      ).to eq(EthereumAbi::Utils.zpad("\xff" * 20, 32))
      expect(
        EthereumAbi.encode_primitive_type(type, "0x#{"ff" * 20}")
      ).to eq(EthereumAbi::Utils.zpad("\xff" * 20, 32))
    end
  end

  shared_examples "Decode ABI for type" do |type, values|
    it "encodes #{type} value" do
      values.each do |value|
        expect(
          EthereumAbi.decode_abi([type], EthereumAbi.encode_abi([type], [value]))[0]
        ).to eq(value)
      end
    end
  end

  describe ".decode_abi" do
    include_examples("Decode ABI for type", "int8", [1, -1, 127, -128])
    include_examples("Decode ABI for type", "int32", [1, -1, 127, -128, 2**31 - 1, -2**31])
    include_examples("Decode ABI for type", "int256", [1, -1, 127, -128, 2**31 - 1, -2**31, 2**255 - 1, -2**255])
  end

  describe ".decode_type" do
  end

  describe ".decode_primitive_type" do
    it "decodes address type" do
      type = EthereumAbi::Type.parse "address"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, "0x#{"ff" * 20}")
        )
      ).to eq("ff" * 20)
    end

    it "decodes bytes type" do
      type = EthereumAbi::Type.parse "bytes"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, "\x01\x02\x03")
        )
      ).to eq("\x01\x02\x03")
    end

    it "decodes bytes8 type" do
      type = EthereumAbi::Type.parse "bytes8"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, "\x01\x02\x03")
        )
      ).to eq("\x01\x02\x03#{"\x00" * 5}")
    end

    it "decodes hash20 type" do
      type = EthereumAbi::Type.parse "hash20"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, "ff" * 20)
        )
      ).to eq("\xff" * 20)
    end

    it "decodes uint8 type" do
      type = EthereumAbi::Type.parse "uint8"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 0)
        )
      ).to eq(0)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 255)
        )
      ).to eq(255)
    end

    it "decodes int8 type" do
      type = EthereumAbi::Type.parse "int8"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, -128)
        )
      ).to eq(-128)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 127)
        )
      ).to eq(127)
    end

    it "decodes ufixed128x128 type" do
      type = EthereumAbi::Type.parse "ufixed128x128"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 0)
        )
      ).to eq(0)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 125.125)
        )
      ).to eq(125.125)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 2**128 - 1)
        )
      ).to eq((2**128 - 1).to_f)
    end

    it "decodes fixed128x128 type" do
      type = EthereumAbi::Type.parse "fixed128x128"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 1)
        )
      ).to eq(1)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, -1)
        )
      ).to eq(-1)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 125.125)
        )
      ).to eq(125.125)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, -125.125)
        )
      ).to eq(-125.125)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, 2**127 - 1)
        )
      ).to eq((2**127-1).to_f)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, -2**127)
        )
      ).to eq(-2**127)
    end

    it "decodes bool type" do
      type = EthereumAbi::Type.parse "bool"
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, true)
        )
      ).to eq(true)
      expect(
        EthereumAbi.decode_primitive_type(
          type,
          EthereumAbi.encode_primitive_type(type, false)
        )
      ).to eq(false)
    end
  end
end
