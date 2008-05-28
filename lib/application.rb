# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'uri'
require File.dirname(__FILE__) + '/config'
require File.dirname(__FILE__) + '/connection'
require File.dirname(__FILE__) + '/utils/crypto_utils'

module HealthVault
  class Application
    attr_reader :id, :key, :uri
    
    def initialize(id, hv_uri, certificate_location)
      @id = id
      @uri = URI.parse(hv_uri)
      @key = CryptoKey.new(certificate_location)
    end
    
    def self.default
      return Application.new(APPLICATIONID, HEALTHVAULT_URL, File.dirname(__FILE__) + "/#{CERTFILE}")
    end
    
    def create_connection
      return Connection.new(self)
    end
  end
end