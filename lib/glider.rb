$LOAD_PATH << File.dirname(__FILE__)

require 'json'
require 'aws-sdk'
require 'active_support/inflector'
require 'active_support/core_ext/hash' # For hash with indifferent access

require 'glider/sdk_patch'
require 'glider/utils'

require 'glider/component'
require 'glider/process_manager'

require 'glider/workflows'
require 'glider/activities'
