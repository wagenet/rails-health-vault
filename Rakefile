require 'rubygems'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'
require 'lib/code_generation/xsd_parser'

CLOBBER.add('lib/wc_data/generated', 'lib/wc_data/thing.rb', 'lib/xsd/requests',
  'lib/xsd/responses', 'lib/xsd/things', 'lib/xsd/common', 'lib/hv.log')

task :default => [:get_things, :rdoc]

task :bootstrap => [:clobber] do |t|
  bootstrap_dir = "lib/xsd/bootstrap/"
  Dir.foreach(bootstrap_dir) do |filename|
    if filename.include?(".xsd")
      p = HealthVault::CodeGeneration::XSDParser.new("#{bootstrap_dir}/#{filename}")
      p.run
    end
  end
end

task :get_services => [:bootstrap] do |t|
  xsd_dir = 'lib/xsd'
  load 'lib/application.rb'
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

task :get_things => [:get_services] do |t|
  load 'lib/wc_data/init.rb'
  
  app = HealthVault::Application.default
  connection = app.create_connection
  
  #get thing schemas
  request = HealthVault::Request.create("GetThingType", connection)
  request.info.add_section('xsd')
  puts "getting thing schemas..."
  result = request.send
  tdir = "lib/xsd/things"
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

spec = Gem::Specification.new do |s|
  s.name = 'rubyhealthvault'
  s.version = '0.0.1'
  s.has_rdoc = true
  s.extra_rdoc_files = ['README', 'LICENSE']
  s.summary = 'Connect your Ruby code to the Microsoft HealthVault'
  s.description = s.summary
  s.homepage = 'http://rubyhealthvault.rubyforge.org/'
  s.rubyforge_project = 'rubyhealthvault'
  s.author = 'Danny Coates'
  s.email = 'dcoates@podfitness.com'
  # s.executables = ['your_executable_here']
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb', 'lib/wc_data/generated/**']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "rubyhealthvault Docs"
  rdoc.rdoc_dir = 'doc/rdoc' # rdoc output folder
  rdoc.options << '--line-numbers'
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*.rb']
end

Spec::Rake::SpecTask.new('testspec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

