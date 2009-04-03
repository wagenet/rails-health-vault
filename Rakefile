require File.join(File.dirname(__FILE__), 'init')

require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'spec/rake/spectask'

load File.join(File.dirname(__FILE__), 'tasks', 'healthvault.rake')

CLOBBER.add("#{HEALTHVAULT_ROOT}/lib/health_vault/hv.log")
CLOBBER.add(*HealthVault::CodeGeneration::Generator::GENERATED_PATHS)

task :default => ['healthvault:get_things', :rdoc]

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
  s.files = %w(GPL LICENSE README Rakefile) + Dir.glob("{bin,lib,spec}/**/*")
  s.require_path = "lib"
  s.bindir = "bin"
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

Rake::RDocTask.new do |rdoc|
  files =['README', 'LICENSE', 'lib/**/*.rb']
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

