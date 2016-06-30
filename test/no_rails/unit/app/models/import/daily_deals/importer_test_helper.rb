require File.dirname(__FILE__) + "/../../../models_helper"

def setup_import_daily_deals_via_http_for_publisher!(label)
  pub_group = stub('Publishing Group')
  pub_group.stubs(:try).with(:label).returns(label)
  (api_config = {}).stubs(:present? => nil)
  @publisher = stub('Publisher', :label => label, :publishing_group => pub_group, :third_party_deals_api_config => api_config)
  Time.stubs(:zone).returns(stub(:now => Time.new))
  Import::DailyDealImport::HTTP.stubs(:download_to_file => stub('GET Response', :code => '200'))
  Import::DailyDeals::DailyDealsImporter.stubs(:daily_deals_import => nil)
end
