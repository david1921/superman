module Presenters
	module Versions
		class Entry

			attr_reader :time, :username, :description

			def initialize(time, username, description)
				@time 				= time
				@username 		= username
				@description 	= description
			end

			def <=>(other)
				other.time <=> time
			end

		end
	end
end