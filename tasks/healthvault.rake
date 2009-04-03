require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init'))

namespace :healthvault do

  desc "Get HealthVault Things"
  task :get_things do |t|
    HealthVault::CodeGeneration::Generator.get_things
  end
  
end