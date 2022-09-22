# -*- encoding : ascii-8bit -*-
# frozen_string_literal: true

module EthereumAbi
  class Type
    class ParseError < StandardError; end

    class << self
      ##
      # Crazy regexp to seperate out base type component (eg. uint), size (eg.
      # 256, 128x128, nil), array component (eg. [], [45], nil)
      #
      def parse(type)
        _, base, sub, dimension = /([a-z]*)([0-9]*x?[0-9]*)((\[[0-9]*\])*)/.match(type).to_a

        dims = dimension.scan(/\[[0-9]*\]/)
        raise ParseError, "Unknown characters found in array declaration" if dims.join != dimension

        case base
        when "string"
          raise ParseError, "String type must have no suffix or numerical suffix" unless sub.empty?
        when "bytes"
          raise ParseError, "Maximum 32 bytes for fixed-length string or bytes" unless sub.empty? || sub.to_i <= 32
        when "uint", "int"
          raise ParseError, "Integer type must have numerical suffix" unless sub =~ /\A[0-9]+\z/

          size = sub.to_i
          raise ParseError, "Integer size out of bounds" unless size >= 8 && size <= 256
          raise ParseError, "Integer size must be multiple of 8" unless (size % 8).zero?
        when "ureal", "real", "fixed", "ufixed"
          unless sub =~ /\A[0-9]+x[0-9]+\z/
            raise ParseError,
                  "Real type must have suffix of form <high>x<low>, e.g. 128x128"
          end

          high, low = sub.split("x").map(&:to_i)
          total = high + low

          raise ParseError, "Real size out of bounds (max 32 bytes)" unless total >= 8 && total <= 256
          raise ParseError, "Real high/low sizes must be multiples of 8" unless (high % 8).zero? && (low % 8).zero?
        when "hash"
          raise ParseError, "Hash type must have numerical suffix" unless sub =~ /\A[0-9]+\z/
        when "address"
          raise ParseError, "Address cannot have suffix" unless sub.empty?
        when "bool"
          raise ParseError, "Bool cannot have suffix" unless sub.empty?
        else
          raise ParseError, "Unrecognized type base: #{base}"
        end

        new(base, sub, dims.map { |x| x[1...-1].to_i })
      end

      def size_type
        @size_type ||= new("uint", 256, [])
      end
    end

    attr :base, :sub, :dims

    ##
    # @param base [String] base name of type, e.g. uint for uint256[4]
    # @param sub  [String] subscript of type, e.g. 256 for uint256[4]
    # @param dims [Array[Integer]] dimensions of array type, e.g. [1,2,0]
    #   for uint256[1][2][], [] for non-array type
    #
    def initialize(base, sub, dims)
      @base = base
      @sub  = sub
      @dims = dims
    end

    def ==(other)
      base == other.base &&
        sub == other.sub &&
        dims == other.dims
    end

    ##
    # Get the static size of a type, or nil if dynamic.
    #
    # @return [Integer, NilClass]  size of static type, or nil for dynamic
    #   type
    #
    def size
      @size ||= if dims.empty?
                  if %w[string bytes].include?(base) && sub.empty?
                    nil
                  else
                    32
                  end
                elsif dims.last.zero?
                  nil # 0 for dynamic array []
                else
                  subtype.dynamic? ? nil : dims.last * subtype.size
                end
    end

    def dynamic?
      size.nil?
    end

    ##
    # Type with one dimension lesser.
    #
    # @example
    #   Type.parse("uint256[2][]").subtype # => Type.new('uint', 256, [2])
    #
    # @return [EthereumAbi::Type]
    #
    def subtype
      @subtype ||= self.class.new(base, sub, dims[0...-1])
    end
  end
end
