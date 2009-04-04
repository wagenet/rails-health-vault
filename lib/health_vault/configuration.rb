# -*- ruby -*-
#--
# Copyright 2008 Danny Coates, Ashkan Farhadtouski
# All rights reserved.
# See LICENSE for permissions.
#++

require 'logger'
require 'singleton'
require 'rexml/formatters/pretty'
require 'yaml'
require 'erb'

module HealthVault
  class Configuration
    include Singleton
    
    ATTRIBUTES = %w(app_id cert_file cert_pass shell_url hv_url logger)
    
    @@configurations = nil
    
    attr_accessor :app_id, :cert_file, :cert_pass, :shell_url, :hv_url
    attr_reader :logger

    class << self

      def configurations
        unless @@configurations
          path = "#{RAILS_ROOT}/config/healthvault.yml"
          @@configurations = YAML::load(ERB.new(File.read(path)).result) if File.file?(path)
        end
        @@configurations
      end
    
      def load(name)
        instance.load(name)
        instance
      end
    
    end
    
    #default values to the HelloWorld sample.
    #theses should be set by your application
    #using HealthVault::Configuration.instance accessor methods
    def initialize
      load
    end
    
    def load(name = 'default')
      config = self.class.configurations[name.to_s]
      raise ArgumentError.new("No configuration named: #{name}") unless config
      self.attributes = config
    end

    def attributes=(attrs = {})
      attrs = attrs.stringify_keys
      attrs.assert_valid_keys(ATTRIBUTES)
      
      attrs.each{|k,v| send("#{k}=", v) }
    end
    
    def attributes
      ATTRIBUTES.inject({}){|hsh, a| hsh[a] = send(a); hsh }
    end
    
    def logger=(value)
      unless @logger
        begin
          @logger = case value
            when :rails                                 then  RAILS_DEFAULT_LOGGER
            when Logger, ActiveSupport::BufferedLogger  then  @logger
            else                                              Logger.new(value.to_s)
          end
        rescue
          @logger = Logger.new($stdout)
          @logger.error("Couldn't load logger - using $stdout")
        end
      end
      @logger
    end
    
    def log_xml(doc, level = :debug)
      f = REXML::Formatters::Pretty.new
      result = ''
      f.write(doc, result)
      logger.send(level, result)
    end
  end
end
