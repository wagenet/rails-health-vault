module HealthVault
  module CodeGeneration
    class Generator
      
      GENERATED_PATHS = [
        "#{HEALTHVAULT_ROOT}/lib/health_vault/wc_data/thing.rb",
        "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/requests",
        "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/responses",
        "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/things",
        "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/common",
        "#{HEALTHVAULT_ROOT}/lib/generated"
      ]
      
      BOOTSTRAP_DIR = "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/bootstrap"
      XSD_DIR       = "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd"
      THINGS_DIR    = "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/things"

      
      def self.get_things
        new.get_things
      end
      
      
      def remove_generated
        # TODO: Log this
        GENERATED_PATHS.each{|fn| FileUtils.rm_r fn rescue nil }
      end
      
      # TODO: Is there a way to tell what's been run?
      
      def bootstrap
        remove_generated
        
        Dir.foreach(BOOTSTRAP_DIR) do |filename|
          if filename.ends_with?(".xsd")
            HealthVault::CodeGeneration::XSDParser.new("#{BOOTSTRAP_DIR}/#{filename}").run
          end
        end
      end
      
      def get_services
        bootstrap
        
        request_schemas   = []
        response_schemas  = []
        common_schemas    = []

        # get the common and method schemas from the server
        result = connection.send_request("GetServiceDefinition")
        
        result.info.xml_method.each do |xm|
          xm.version.each do |v|
            q = v.request_schema_url.to_s
            p = v.response_schema_url.to_s
            request_schemas << q unless q.empty?
            response_schemas << p unless p.empty?
          end
        end
        result.info.common_schema.each do |cs|
          common_schemas << cs.to_s unless cs.to_s.empty?
        end
        run_parser("#{XSD_DIR}/common", common_schemas)
        run_parser("#{XSD_DIR}/requests", request_schemas)
        run_parser("#{XSD_DIR}/responses", response_schemas)
      end
      
      def get_things
        get_services
        
        puts "getting thing schemas..."        
        result = connection.send_request("GetThingType") {|r| r.info.add_section('xsd') }

        Dir.mkdir(THINGS_DIR) unless File.exists?(THINGS_DIR)            
        result.info.thing_type.each do |type|
          File.open("#{THINGS_DIR}/#{type.name}.xsd", 'w'){|f| f << type.xsd }
        end

        #generate thing types
        x = HealthVault::CodeGeneration::XSDParser.new("")
        Dir.foreach(THINGS_DIR) do |filename|
          if filename.ends_with?(".xsd")
            puts "parsing: #{filename}"
            p = HealthVault::CodeGeneration::XSDParser.new("#{THINGS_DIR}/#{filename}")
            x.add_thing("#{THINGS_DIR}/#{filename}")
            p.run
          end
        end
        x.create_things
      end
      
      private
      
        def connection
          unless @connection
            app = HealthVault::Application.default
            @connection = app.create_connection
          end
          @connection
        end

        def run_parser(wdir, schemas)
          unless File.exists?(wdir)
            Dir.mkdir(wdir)
          end 
          schemas.each do |s|
            name = s.split(/\//)
            uri = URI.parse(s)
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            File.open("#{wdir}/#{name[name.length - 1]}" , 'w') { |f|
              f.write(http.get(uri.path).body)
            }  
          end
          Dir.foreach(wdir) do |filename|
            if filename.include?(".xsd")
              puts "parsing: #{filename}"
              p = HealthVault::CodeGeneration::XSDParser.new(wdir + "/#{filename}")
              p.run
            end
          end  
        end
      
    end
  end
end