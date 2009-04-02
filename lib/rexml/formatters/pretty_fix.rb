require 'rexml/formatters/pretty'
module REXML
  module Formatters
    class Pretty
      
      private
      
        # Fix to avoid a place of nil
        def wrap(string, width)
          # Recursivly wrap string at width.
          return string if string.length <= width
          place = string.rindex(' ', width) # Position in string with last ' ' before cutoff
          return string if place.nil?
          return string[0,place] + "\n" + wrap(string[place+1..-1], width)
        end
    
    end
  end
end