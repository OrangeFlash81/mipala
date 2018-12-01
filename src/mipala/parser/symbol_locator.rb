module Mipala::Parser
  # Given a text string, locates any symbols which could be relevant to the
  # tokenizer. Note that this has no consideration for context whatsoever, and
  # as such could return objects such as full-stops which should in fact be
  # interpreted as text.
  class SymbolLocator
    attr_reader :text, :file

    def initialize text, file=nil
      @text = text
      @file = file
    end

    # Returns an array of arrays representing the locations of particular
    # symbols inside the string, in the form [[symbol, location], ...] where
    # symbol is a key of Mipala::Parser::Constants::SYMBOLS.
    def symbol_locations
      col = 1
      row = 1

      text.chars.map do |char|
        # Alter location
        if char == "\n"
          col = 1
          row += 1
        else
          col += 1
        end

        # Return according to whether this is a symbol
        val = Mipala::Parser::Constants::SYMBOLS.key_for_value char
        val.nil? ? nil : [val, Location.new(file, row, col)]
      end.reject(&:nil?)
    end
  end
end