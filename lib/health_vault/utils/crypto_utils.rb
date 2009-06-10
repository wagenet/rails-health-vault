# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'openssl'
require 'base64'

module HealthVault
  module Utils
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
      def initialize(pfx_or_pem_filename, password = nil)
        case pfx_or_pem_filename
          when /.pfx$/
            # INFO: I can't get OpenSSL::PKCS12 working on windows.
            #   This call fails with 'mac verify failed'
            #   To work around this I created a pem on the command line like:
            #     openssl pkcs12 -in xxx.pfx -out xxx.pem -nodes
            pfx = OpenSSL::PKCS12::PKCS12.new(File.read(pfx_or_pem_filename), password)
            @pkey = pfx.key
            @cert = pfx.certificate
            # TODO: if pfx files are going to be a problem, maybe we just ought to remove
          when /.pem$/
            @pkey = OpenSSL::PKey::RSA.new(File.read(pfx_or_pem_filename),password)
            @cert = OpenSSL::X509::Certificate.new(File.read(pfx_or_pem_filename))
          else
            raise "Certificate must be a .pfx or .pem file"
        end
      end

      def sign(text)
        @pkey.sign(OpenSSL::Digest::SHA1.new, text)
      end

      def fingerprint
        OpenSSL::Digest::SHA1.hexdigest(@cert.to_der)
      end
    end
  end
end