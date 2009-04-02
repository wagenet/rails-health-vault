# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

module HealthVault
  module Utils
    module StringUtils    
      def hv_classify(string)
        string.tr('-','_').camelize
      end
      
      def to_filename(word)
        # Remove underscores before digits or our files will have the wrong names
        word.underscore.gsub(/_+(\d)/, '\1')
      end
    end
  end
end
