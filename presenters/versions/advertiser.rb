module Presenters
	module Versions
		class Advertiser < Presenters::Versions::Base

			class MissingAdvertiserException < StandardError; end

			attr_reader :advertiser

			def initialize(advertiser)
				@advertiser = advertiser
				raise MissingAdvertiserException, "advertiser is needed for the advertiser version presenter" unless @advertiser
			end

			private


			def build_by_date
				by_date_for_advertiser_versions
				by_date_for_advertiser_translations_versions
				by_date_for_advertiser_stores_versions
				build_by_date_from_by_date_hash
			end

			def by_date_hash
				@by_date_hash ||= {}
			end

			def by_date_for_advertiser_versions
				advertiser.versions.each do |version|
					if version.changes.any?
						version.changes.each_pair do |attribute, values|
							unless attributes_to_exclude?(attribute)
								entry = Entry.new(version.created_at, extract_username_from_version(version), description_from_attribute_and_values(attribute, values))
								add_entry_to_by_date_hash(version.created_at, entry)
							end
						end
					else
						puts version.inspect
						entry = Entry.new(version.created_at, extract_username_from_version(version), "Advertiser was added")
						add_entry_to_by_date_hash(version.created_at, entry)
					end
				end
			end

			def by_date_for_advertiser_translations_versions
				advertiser.translations.each do |translation|
					translation.versions.each do |version|
						version.changes.each_pair do |attribute, values|
							unless attributes_to_exclude?(attribute)							
								entry = Entry.new(version.created_at, extract_username_from_version(version), description_from_attribute_and_values(attribute, values))
								add_entry_to_by_date_hash(version.created_at, entry)
							end
						end
					end
				end
			end

			def by_date_for_advertiser_stores_versions
				advertiser.stores.each do |store|
					if store.versions.any?
						store.versions.each do |version|
							version.changes.each_pair do |attribute, values|
								unless attributes_to_exclude?(attribute)
									entry = Entry.new(version.created_at, extract_username_from_version(version), "Store (#{store_address( find_store_by_id(version.versioned_id) )}) #{attribute.humanize} was changed from '#{values.first}' to '#{values.last}'")
									add_entry_to_by_date_hash(version.created_at, entry)
								end
							end
						end
					else
						# this handle the case where a create record didn't create a version record.
						entry = Entry.new(store.created_at, "", "Store (#{store_address(store)}) was added")
						add_entry_to_by_date_hash(store.created_at, entry)
					end
				end
			end

			def build_by_date_from_by_date_hash
				results = []
				sorted_keys = by_date_hash.keys.sort{|a,b| b <=> a}
				sorted_keys.each do |key|
					by_date = ByDate.new(key, by_date_hash[key])
					results.push( by_date )
				end
				results
			end

			def add_entry_to_by_date_hash(date, entry)
				date = date.to_date if Time === date
				by_date_hash[date] ||= []
				by_date_hash[date].push(entry) if entry
				by_date_hash
			end

			def store_address(store)
				return "" unless store
				store.address.join(" ")
			end

			def description_from_attribute_and_values(attribute, values)
				changed_from = values.first
				changed_to   = values.last
				if changed_from.blank?
					"#{attribute.humanize} was changed to '#{changed_to}'"	
				else
					"#{attribute.humanize} was changed from '#{changed_from}' to '#{changed_to}'"
				end
			end

			def find_store_by_id(id)
				Store.find(id)
			end

		end
	end
end