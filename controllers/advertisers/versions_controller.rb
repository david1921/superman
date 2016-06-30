class Advertisers::VersionsController < Advertisers::AdminController


	def index
		@presenter = Presenters::Versions::Advertiser.new(@advertiser)
		publisher = @advertiser.publisher
		add_crumb publisher.name
		add_crumb "Advertisers", publisher_advertisers_path(publisher)
		add_crumb @advertiser.name, edit_advertiser_path(@advertiser)
		add_crumb "Changes"
	end

end
