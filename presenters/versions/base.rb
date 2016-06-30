module Presenters
	module Versions
		class Base

			EXCLUDED_ATTRIBUTES = %w( lock_version )

			def by_date
				@by_date ||= build_by_date
			end


			private

			# expects an array of Presenters::Versions::ByDate
			# from most recent to oldest.
			def build_by_date
				raise NotImplementedError, "subclasses must implement this method."
			end

			def attributes_to_exclude?(attribute)
				EXCLUDED_ATTRIBUTES.include?(attribute)
			end

			def extract_username_from_version(version)
				return "" unless version
				version.user ? version.user.login : version.user_name
			end

		end
	end
end