# singleton class handling all children, useful for daemonization

module Glider

	module ProcessManager

		class ThreatExitSignal < StandardError

		end

		class << self

			attr_writer :use_forking

			def use_forking
				@use_forking.nil? ? true : @use_forking
			end

			# tracks forks/threads started as workers
			def children
				@children ||= []
			end

			def kill_forks
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

			def kill_threads
				children.each do |child|
					tr = child[0]
					if tr[:in_task]
						tr[:time_to_exit] = true
					else
						tr.raise ThreatExitSignal.new
					end
				end
			end

			def workers
				# stores arrays of workers and the key is the name of the class where they were defined (as string)
				# ej. workers["SettlementActivities"] = [wk1, wk2, ...]
				@workers ||= {} 
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
				Glider::ProcessManager.kill_forks
			end

			def register_worker(grouping_class_name, worker_proc)
				if workers[grouping_class_name]
					workers[grouping_class_name] << worker_proc
				else
					workers[grouping_class_name] = [worker_proc]
				end
			end

			def start_fork(worker_proc)
				pid = fork do
					worker_proc.call
				end
				children << [pid, worker_proc]
			end

			def start_thread(worker_proc)
				thread = Thread.new do
					worker_proc.call
				end
				thread[:in_task] = false
				children << [thread, worker_proc]
			end

			def start_workers(from_class: nil)
				mode = use_forking ? "forks" : "threads"
				if from_class
					Glider::logger.info "Loading workers defined in #{from_class} as #{mode}" 
					workers_to_boot = workers[from_class.to_s]
				else
					# select all workers
					Glider::logger.info "Loading workers from all classes as #{mode}"
					workers_to_boot = workers.values.flatten
				end
				if use_forking
					$leader_pid ||= Process.pid
					Signal.trap('TERM') {Glider::ProcessManager.kill_forks}
					Signal.trap('INT') {Glider::ProcessManager.kill_forks}
					# todo start workers as forks
					
					workers_to_boot.each do |worker_proc|
						start_fork worker_proc
					end
					
					Thread.new do
						monitor_children
					end
					Process.waitall
				else
					Signal.trap('TERM') {Glider::ProcessManager.kill_threads}
					Signal.trap('INT') {Glider::ProcessManager.kill_threads}
					
					workers_to_boot.each do |worker_proc|
						start_thread worker_proc
					end
					
					#binding.pry
					children.each {|ch| ch[0].join }
				end
			end

		end

	end

end