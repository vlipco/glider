require_relative 'shared_boot'

def trigger
	Glider.execute :glider_test, :say_hi, '1.0', "ALOHA"
end

$logger.info "call trigger to execute :say_hi"

pry

