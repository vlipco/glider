require 'rubygems'
require 'bundler/setup'
Bundler.require :default

$logger = Logger.new STDOUT
$logger.level = Logger::INFO

$logger.formatter = proc do |severity, datetime, progname, msg|
	color = case severity.to_s
			when "INFO"
				:blue
			when "WARN"
				:yellow
			when "ERROR"
				:red
			else
				:default
			end
	
  	severity == "NONE" ? "\n" : "#{Process.pid} #{severity} #{datetime.strftime '%H:%M:%S'} \t#{msg.to_s.colorize color}\n"
end

env_crendentials = (AWS::Core::CredentialProviders::ENVProvider.new "AWS").get_credentials

if env_crendentials[:access_key_id] && env_crendentials[:secret_access_key]

	AWS.config({ :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
		:secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
		:dynamo_db_endpoint => 'dynamodb.us-east-1.amazonaws.com',
		:log_level => :debug })
else

	AWS.config(:credential_provider => AWS::Core::CredentialProviders::EC2Provider.new, 
		:dynamo_db_endpoint => 'dynamodb.us-east-1.amazonaws.com',
		:log_level => :debug)

end

require_relative 'lib/glider'
