require 'strscan'

# Represents a search. It's a hash of key value pairs plus a search string.
#
# Examples:
#   Search.new('hello') => search = 'hello', {}
#   Search.new('key:value') => search = nil, {:key => 'value'}
#   Search.new('key:"many words"') => search = nil, {:key => 'many words'}
#   Search.new('something key:"many words"') => search = 'something', {:key => 'many words'}
#
class Search < Hash
  attr_reader :search

  def initialize(str)
    return if str.nil?
  
    s = StringScanner.new(str)
    
    until s.eos?
      # Skip whitespace
      s.scan(/\s+/)
    
      # Get next work
      key = s.scan(/\w+/)
      
      # Check if there's a colon so we have key:...
      colon = s.scan(/:/)
      if !colon.nil?
        # Check key:"value"
        value = s.scan(/".+?"/)
        if value.nil?
          value = s.scan(/(\S)+/)
        else
          value = value[1...-1]
        end
        self[key.to_sym] = value
        next
      end
      
      key = s.scan(/"(\w|\s)+"/) if key.nil?
      key = s.scan(/\W+/) if key.nil?

      # Just a word to add to the search
      if @search.nil?
        @search = key
      else
        @search += ' ' + key
      end
    end
  end
end