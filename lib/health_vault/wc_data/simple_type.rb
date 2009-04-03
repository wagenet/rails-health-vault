# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

module HealthVault
  module WCData
    class SimpleType
      
      attr_accessor :value
      
      class << self
      
        def valid?(value)
          return true
        end
        
        def is_string?
          name.split('::').last =~ /^Stringn?z?\d+$/
        end
        
      end
      
      def initialize(val = nil)
        self.value = val
      end
      
      def to_s
        value.to_s
      end
      
      def valid?
        return true
      end
      
      def is_string?
        self.class.is_string?
      end
      
      # Hack for strings
      def is_a?(klass)
        return true if klass == String && self.is_string?
        super
      end
      
    end
  end
end
