$LOAD_PATH << File.dirname(__FILE__)

require 'json'
require 'aws-sdk'
require 'active_support/inflector'
require 'active_support/core_ext/hash' # For hash with indifferent access
require 'spawnling'

require 'glider/aws_sdk_patch'
require 'glider/glider_globals'

require 'glider/component_class_helpers'
require 'glider/component_polling'
require 'glider/component_instance'