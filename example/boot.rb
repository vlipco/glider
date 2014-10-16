require 'logger'
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
    
    severity == "NONE" ? "\n" : "#{Time.now.strftime('%I:%M%p')} pid=#{Process.pid} #{severity} #{msg.to_s.colorize color}\n"
end

Glider::logger = $logger


AWS.config({ :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
    :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'],
    :log_level => :debug })

