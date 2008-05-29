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
    attr_reader :id, :uri
    
    def initialize(id, hv_uri, certificate_location)
      @id = id
      @uri = URI.parse(hv_uri)
      @key_file = certificate_location
    end
    
    def key
      return CryptoKey.new(@key_file)
    end
    
    def self.default
      config = Configuration.instance
      return Application.new(config.app_id, config.hv_url, config.cert_file)
    end
    
    def create_connection
      return Connection.new(self)
    end
  end
end