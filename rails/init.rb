require 'rubygems'
require 'active_support'

HEALTHVAULT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

$LOAD_PATH << File.join(HEALTHVAULT_ROOT, 'lib')
$LOAD_PATH << File.join(HEALTHVAULT_ROOT, 'lib', 'generated')
$LOAD_PATH.uniq!

Dependencies = ActiveSupport::Dependencies unless defined?(Dependencies)
Dependencies.load_paths << File.join(HEALTHVAULT_ROOT, 'lib')
Dependencies.load_paths << File.join(HEALTHVAULT_ROOT, 'lib', 'generated')

require 'rexml/formatters/pretty_fix'