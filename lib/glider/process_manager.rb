# singleton class handling all children, useful for daemonization

module Glider

	module ProcessManager

		class << self

			# tracks forks/threads started as workers
			def children
				@children ||= []
			end

			def kill_children
				if $leader_pid == Process.pid
					@end_monit = true
					children.each do |child|
						begin 
							pid, worker_proc = child
							Process.kill('USR1', pid)
						rescue Errno::ESRCH => e
							# process already killed
						end
					end
				end
			end

			def workers
				@workers ||= []
			end


			def monitor_children
				loop do
					break if @end_monit
					children.each_with_index do |child, index|
						pid, worker_proc = child
						begin
							Process.kill 0, pid
						rescue Errno::ESRCH
							children.delete_at index
							$logger.info "Restarting worker...."
							start worker_proc
						end
					end
					sleep 1
				end
				Glider::ProcessManager.kill_children
			end

			def register_worker(worker_proc)
				workers << worker_proc
			end

			def start(worker_proc)
				pid = fork do
					worker_proc.call
				end
				children << [pid, worker_proc]
			end

			def start_workers
				$leader_pid ||= Process.pid
				Signal.trap('TERM') {Glider::ProcessManager.kill_children}
				Signal.trap('INT') {Glider::ProcessManager.kill_children}
				# todo start workers as forks
				@workers.each do |worker_proc|
					start worker_proc
				end
				Thread.new do
					monitor_children
				end
				Process.waitall
			end

		end

	end

end