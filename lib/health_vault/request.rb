# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'rexml/document'
require 'date'
require File.dirname(__FILE__) + '/utils/string_utils'

# HealtVault doesn't adhere to valid xml standards.
# Attribute values must be in double quotes to be parseable
# So we redefine REXML::Attribute.to_string to accommodate
REXML::Attribute.class_eval {def to_string() "#@expanded_name=\"#{to_s().gsub(/"/, '&quot;')}\"" end}

module HealthVault
  class Request < HealthVault::WCData::ComplexType
    include WCData
    include Utils::StringUtils
    
    child_element :auth, :class => 'HealthVault::WCData::Types::HMACFinalized', :min => 0, :max => 1, :order => 1
    child_element :header, :class => 'HealthVault::WCData::Request::Header', :min => 1, :max => 1, :order => 2
    child_element :info, :class => 'HealthVault::WCData::Request::Info', :min => 1, :max => 1, :order => 3
    
      
    def initialize(connection)
      super()
      @connection = connection  
    end
    
    def self.create(method_name, connection)
      returning(new(connection)) do |r|
        r.header.method = method_name
        r.header.method_version = "1"
        r.header.language = "en"
        r.header.country = "US"
        r.header.msg_time = DateTime.now.to_s
        r.header.msg_ttl = '29100'
        r.header.version = "0.0.0.1"
        r.set_request_info
      end
    end
    
    def set_request_info
      klass = begin
        "HealthVault::WCData::Methods::#{header.method}::Info".constantize
      rescue
        Configuration.instance.logger.error "No Info class for #{header.method}"
        HealthVault::WCData::RawInfoXml
      end      
      __send__(:info=, klass.new, true)
    end
    
    def element
      e = Element.new('wc-request:request')
      e.add_namespace("wc-request", "urn:com.microsoft.wc.request")
      super(e)
    end
    
    def send
      if @connection.authenticated?
        header.info_hash = Types::HashFinalized.new
        header.info_hash.hash_data = Types::HashFinalizedData.new
        header.info_hash.hash_data.alg_name = "SHA1"
        header.info_hash.hash_data.data = CryptoUtils.encode64(CryptoUtils.digest(info.element.to_s))
        header.auth_session = WCData::Request::AuthenticatedSessionInfo.new
        header.auth_session.auth_token = @connection.session_token
        header.auth_session.user_auth_token = @connection.user_auth_token #or offline_person_info
        #INFO: call the auth= method, not create an auth variable
        self.auth = Types::HMACFinalized.new
        auth.hmac_data = Types::HMACFinalizedData.new
        auth.hmac_data.alg_name = "HMACSHA1"
        auth.hmac_data.data = CryptoUtils.encode64(CryptoUtils.hmac(@connection.shared_secret, header.element.to_s)) 
      else
        header.app_id = @connection.application.id
      end
      #if self.valid?
      return @connection.send(self)
      #else
      #  raise StandardError.new("request is not valid")
      #end      
    end
  end
end