require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init'))
require 'rake/clean'

clobber = %w(wc_data/thing.rb xsd/requests xsd/responses xsd/things xsd/common hv.log).
            map{|f| "#{HEALTHVAULT_ROOT}/lib/health_vault/#{f}" }
clobber << "#{HEALTHVAULT_ROOT}/lib/generated"
CLOBBER.add(*clobber)

namespace :healthvault do
  desc "Bootstrap HealthVault"
  task :bootstrap => [:clobber] do |t|
    bootstrap_dir = "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/bootstrap"
    Dir.foreach(bootstrap_dir) do |filename|
      if filename.include?(".xsd")
        p = HealthVault::CodeGeneration::XSDParser.new("#{bootstrap_dir}/#{filename}")
        p.run
      end
    end
  end

  desc "Get HealthVault services"
  task :get_services => [:bootstrap] do |t|
    xsd_dir = "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd"
    app = HealthVault::Application.default
    connection = app.create_connection

    request_schemas = Array.new
    response_schemas = Array.new
    common_schemas = Array.new

    # get the common and method schemas from the server
    request = HealthVault::Request.create("GetServiceDefinition", connection)
    result = request.send
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
    run_parser(xsd_dir + "/common", common_schemas)
    run_parser(xsd_dir + "/requests", request_schemas)
    run_parser(xsd_dir + "/responses", response_schemas)
  end

  desc "Get HealthVault Things"
  task :get_things => [:get_services] do |t|
    app = HealthVault::Application.default
    connection = app.create_connection

    #get thing schemas
    request = HealthVault::Request.create("GetThingType", connection)
    request.info.add_section('xsd')
    puts "getting thing schemas..."
    result = request.send
    tdir = "#{HEALTHVAULT_ROOT}/lib/health_vault/xsd/things"
    unless File.exists?(tdir)
      Dir.mkdir(tdir)
    end
    result.info.thing_type.each do |type|
      File.open(tdir + "/#{type.name}.xsd", 'w') do |f|
        f << type.xsd
      end
    end

    #generate thing types
    x = HealthVault::CodeGeneration::XSDParser.new("")
    Dir.foreach(tdir) do |filename|
      if filename.include?(".xsd")
        puts "parsing: #{filename}"
        p = HealthVault::CodeGeneration::XSDParser.new(tdir +"/#{filename}")
        x.add_thing(tdir + "/#{filename}")
        p.run
      end
    end
    x.create_things
  end
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