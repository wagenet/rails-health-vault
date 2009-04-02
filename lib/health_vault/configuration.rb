# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'logger'
require 'singleton'
require 'rexml/formatters/pretty'

module HealthVault
  class Configuration
    include Singleton
    attr_accessor :app_id, :cert_file, :cert_pass, :shell_url, :hv_url, :logger
    
    #default values to the HelloWorld sample.
    #theses should be set by your application
    #using HealthVault::Configuration.instance accessor methods
    def initialize
      @app_id = "05a059c9-c309-46af-9b86-b06d42510550"
      @cert_file = "#{HEALTHVAULT_ROOT}/bin/certs/helloWorld.pem"
      @cert_pass = ""
      @shell_url = "https://account.healthvault-ppe.com"
      @hv_url = "https://platform.healthvault-ppe.com/platform/wildcat.ashx"
      @logger = Logger.new("#{HEALTHVAULT_ROOT}/hv.log")
    end
    
    def log_xml(doc, level = :debug)
      f = REXML::Formatters::Pretty.new
      result = ''
      f.write(doc, result)
      logger.send(level, result)
    end
  end
end
