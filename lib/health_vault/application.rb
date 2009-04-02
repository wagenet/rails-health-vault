# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'uri'
require 'utils/crypto_utils' # for CryptoKey

module HealthVault
  class Application
    attr_reader :id, :uri
    
    def initialize(id, hv_uri, certificate_location, certificate_password)
      @id = id
      @uri = URI.parse(hv_uri)
      @cert_file = certificate_location
      @cert_pass = certificate_password
    end
    
    def key
      return Utils::CryptoKey.new(@cert_file, @cert_pass)
    end
    
    def self.default
      config = Configuration.instance
      return Application.new(config.app_id, config.hv_url, config.cert_file, config.cert_pass)
    end
    
    def create_connection
      return Connection.new(self)
    end
  end
end