require 'pry' 
x = Thread.new do
	y = 2
	begin
		loop do
			puts y
			sleep 3
		end
	rescue RuntimeError => e
		puts "!! #{e}"
	end
end

x.abort_on_exception = false
#x.raise "Aloha"

pry