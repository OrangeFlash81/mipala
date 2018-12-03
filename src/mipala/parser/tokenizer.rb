module Mipala::Parser
  # Converts a list of symbol locations into Token structs.
  class Tokenizer
    include Mipala::Mixins::Contracts

    attr_reader :text, :symbol_locations

    def initialize(text, symbol_locations)
      @text = is_a! text, 'text', String
      @symbol_locations = is_array! symbol_locations, 'symbol_locations',
        SymbolLocator::LocatedSymbol
    end

    # Given a text index, returns a boolean indicating whether there is a symbol
    # at that index.
    def is_symbol?(index)
      symbol_locations.any? do |sym_loc|
        sym_loc.location.character_index(text) == index
      end
    end

    # Returns an array of Token objects for this text and symbol locations.
    def tokenize
      # This is implemented by splitting the text on symbols and inserting
      # tokens on the splits

      # Slice each character if there's a symbol there; this leaves the symbol
      # at the end of the character array
      # Get text characters as array with index
      chars_with_index = text.chars.each_with_index

      # Slice on symbols into 2D array of chars and indeces
      sliced_chars_with_index = chars_with_index.slice_when do |(_, i)|
        is_symbol? i
      end
      
      # Remove indexes and join nested arrays into strings
      sliced_strings = sliced_chars_with_index.map do |str_with_index|
        str_with_index.map(&:first).join
      end

      # Convert the final character of each string into a :symbol token, and
      # the rest into a :text token
      tokens = sliced_strings.zip(symbol_locations).flat_map do |text, sym_loc|
        if sym_loc.nil?
          # If the document doesn't end with a symbol...
          Token.new(:text, text) 
        else
          # If it does...
          [
            Token.new(:text, text[0...-1]),
            Token.new(:symbol, sym_loc.symbol)
          ]
        end
      end

      # Convert spaces at the beginning of lines to :space_count tokens
      tokens.flat_map do |token|
        # We're only looking for :text tokens with newlines
        next token unless token.type == :text && token.value.include?("\n")

        # Split on the newlines, retaining them in the output
        line_segments = token.value.split("\n").map { |x| x + "\n" }
        line_segments[-1] = line_segments[-1][0...-1] # The last element shouldn't have a newline

        # Create tokens from these segments
        line_segments.flat_map do |seg|
          p seg
          # Count the number of spaces at the beginning of the string
          spaces_at_start = seg.scan(/^ */).first.length

          # Return a space count and a text token
          [
            Token.new(:space_count, spaces_at_start),
            Token.new(:text, seg.gsub(/^ +/, ''))
          ]
        end
      end
    end
  end
end