require_relative 'shared_boot'

def trigger
	Glider.execute :glider_test, :say_hi, '1.1', "ALOHA"
	#Glider.signal :glider_test, "workflow_id", :redireciton_completed
end

$logger.info "call trigger to execute :say_hi"

pry

