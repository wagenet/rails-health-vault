# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'openssl'
require 'base64'

module HealthVault
  class CryptoUtils
    include OpenSSL
    def self.create_shared_secret
      unless File.exist?("/dev/urandom")
        Random.seed(rand(0).to_s + Time.now.usec.to_s)
      end
      data = BN.rand(2048, -1, false).to_s
      return OpenSSL::Digest::SHA1.new(data).digest
    end
    
    def self.encode64(text)
      return Base64.encode64(text).gsub(/\n/, "")
    end
    
    def self.hmac(key, text)
      return HMAC.digest(OpenSSL::Digest::Digest.new("SHA1"), key, text)
    end
    
    def self.digest(text)
      return OpenSSL::Digest::SHA1.new(text).digest
    end
  end
  
  class CryptoKey
    def initialize(pfx_filename)
      @pfx = OpenSSL::PKCS12::PKCS12.new(File.read(pfx_filename))
    end
    
    def sign(text)
      return @pfx.key.sign(OpenSSL::Digest::SHA1.new, text)
    end
    
    def fingerprint
      return OpenSSL::Digest::SHA1.hexdigest(@pfx.certificate.to_der)
    end
  end
end