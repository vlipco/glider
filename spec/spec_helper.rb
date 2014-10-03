require 'rubygems'
require 'bundler/setup'

Bundler.require :test
require 'rspec/autorun'

support_files_glob = File.expand_path("../spec/support**/*.rb",__FILE__)
Dir::glob(support_files_glob).each  {|x| require x }

RSpec.configure do |config|

	# Run specs in random order to surface order dependencies. If you find an
	# order dependency and want to debug it, you can fix the order by providing
	# the seed, which is printed after each run.e.g (...) --seed 1234
	config.order = "random"

	# so we can use :vcr rather than :vcr => true;
	# in RSpec 3 this will no longer be necessary.
	config.treat_symbols_as_metadata_keys_with_true_values = true
end