module Advertisers
	module VersionsHelper

		def changes_for_version(version)
			changes = []
			version.changes.each_pair do |key, value|
				unless "lock_version" == key
					changes.push( "#{key.humanize} was changed from '#{value.first}' to '#{value.last}'")
				end
			end
			changes.push("Looks like record was saved without any real changes.") unless changes.any?
			content_tag(:ul) do
				changes.each do |change| 
					content_tag(:li, change)
				end
			end
		end

		def render_entry(entry)
			content = []
			content.push( entry.description || "" )
			content.push( "at #{entry.time.strftime("%H:%M")}" )
			content.push( "by #{entry.username}" ) if entry.username.present?
			content.join(" ")
		end

	end
end