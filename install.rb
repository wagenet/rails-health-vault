require File.join(File.dirname(__FILE__), 'init')

RAILS_ROOT = "#{HEALTHVAULT_ROOT}/../../.." unless defined?(RAILS_ROOT)

puts "Copying config to config/healthvault.yml"
`cp #{HEALTHVAULT_ROOT}/templates/healthvault.yml #{RAILS_ROOT}/config/healthvault.yml`

puts "Generating Models"
HealthVault::CodeGeneration::Generator.get_things