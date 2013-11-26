require_relative 'shared_boot'

def trigger
	puts "TRIGGER!"
	execution = Glider.execute :gt3, :say_hi, '1.5', input: {message: "ALOHA"}.to_json
	#Glider.signal :glider_test, execution.workflow_id, :test
	return execution
end

def massive_trigger
	threads = []
	4.times do
		threads << Thread.new do
			#begin
				50.times do
					trigger
				end
			#ensure
				#exit 0
			#end
		end
	end
	threads.map &:join
end
$logger.info "call trigger to execute :say_hi"

pry

