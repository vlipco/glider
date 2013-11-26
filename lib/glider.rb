#$LOAD_PATH << File.dirname(__FILE__)

#require 'active_support/all'
require 'json'
require 'aws-sdk'
require 'active_support/inflector'
# For hash with indifferent access
require 'active_support/core_ext/hash'


require 'glider/utils'

require 'glider/component'
require 'glider/process_manager'

require 'glider/workflows'
require 'glider/activities'
