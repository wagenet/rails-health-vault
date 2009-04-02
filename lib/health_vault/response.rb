# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'rexml/document'
require File.dirname(__FILE__) + '/utils/string_utils'

module HealthVault
  class Response
    include REXML
    include Utils::StringUtils
    include WCData
    
    attr_reader :xml, :info
    
    def initialize(http_response)
      #@http_response = http_response
      @xml = Document.new(http_response.body)
      code = XPath.first(@xml, "//code").text
      if code.to_i > 0
        msg = XPath.first(@xml, "//error/message").text
        Configuration.instance.logger.error "ERRORCODE: #{code.to_s} MESSAGE: #{msg}"
        raise StandardError.new(msg)
      end
      Configuration.instance.log_xml(@xml)
      begin
        info_node = XPath.first(@xml, '//wc:info')
        response_namespace = info_node.attribute('xmlns:wc').to_s
        m = response_namespace.match(/urn\:com\.microsoft\.wc\.(.*)/)
      rescue => e
        Configuration.instance.log_xml(@xml, :warn)
        Configuration.instance.logger.warn e
        m = nil
      end
      if m.nil?
        @info = nil
      else
        begin
          mod = (m[1].split('.').collect {|s| hv_classify(s)}).join('::') + "::Info.new"
          # eval may as well be called evil
          nfo = eval mod
          @info = nfo
          @info.parse_element(info_node)
        rescue => e
          Configuration.instance.logger.error e
          @info = nil
        end
      end
    end
    
  end
end