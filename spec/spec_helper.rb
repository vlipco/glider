require 'bundler/setup'
Bundler.require :test

require File.expand_path('../../lib/glider.rb', __FILE__)

RSpec.configure do |config|

	# Run specs in random order to surface order dependencies. If you find an
	# order dependency and want to debug it, you can fix the order by providing
	# the seed, which is printed after each run.e.g (...) --seed 1234
	config.order = "random"
	
	config.raise_errors_for_deprecations!
	
	config.mock_with :rspec do |mocks|
        # This option should be set when all dependencies are being loaded
        # before a spec run, as is the case in a typical spec helper. It will
        # cause any verifying double instantiation for a class that does not
        # exist to raise, protecting against incorrectly spelt names.
        mocks.verify_doubled_constant_names = true
    end

end

support_files_glob = File.expand_path("../support/*.rb",__FILE__)
Dir::glob(support_files_glob).each  {|x| puts x; require x }