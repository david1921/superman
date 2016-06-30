require File.dirname(__FILE__) + "/../../test_helper"
require File.expand_path( File.dirname(__FILE__) + "/../../../../app/presenters/versions/base" )
require File.expand_path( File.dirname(__FILE__) + "/../../../../app/presenters/versions/by_date" )
require File.expand_path( File.dirname(__FILE__) + "/../../../../app/presenters/versions/entry" )
require File.expand_path( File.dirname(__FILE__) + "/../../../../app/presenters/versions/advertiser" )

def build_version(time, changes = {})
	OpenStruct.new( :created_at => Time.parse(time), :changes => changes )
end