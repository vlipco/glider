require_relative 'shared_boot'

def trigger
	execution = Glider.execute :glider_test, :say_hi, '1.0', "ALOHA"
	Glider.signal :glider_test, execution.workflow_id, :test
	return execution
end

$logger.info "call trigger to execute :say_hi"

pry

