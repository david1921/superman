module Presenters
	module Versions
		#
		# Helper class to organize changes by date.
		#
		class ByDate

			class InvalidDateException < StandardError; end

			attr_reader :date, :entries

			# Creates a new ByDate object, which is responsible for grouping
			# changes (entries) by a given date.
			#
			# Expects:
			#   date - the date for the related chagnes, can be a String, Date, or Time object, otherwise InvalidDateException is raised.
			#   entries - an array of Presenters::Versions::Entry, an empty or nil value is allowed but has little use.
			#
			def initialize(date, entries = [])
				@date 		= parse_date(date)
				raise InvalidDateException, "please supply a valid date -- we received: #{date}" unless @date
 				@entries 	= (entries || []).sort
			end

			private


			def parse_date(date)
				begin
					Date.parse(date.to_s)
				rescue
				end
			end

		end
	end
end