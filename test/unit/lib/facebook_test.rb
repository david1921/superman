require File.dirname(__FILE__) + "/../../test_helper"
#  # += ":vendor/rails/"
# require 'actionpack/lib/action_view'
#require 'lib/facebook.rb'

class GenericView
  include Facebook::Tagger
  include Facebook::UI
end

class FacebookTest < ActiveSupport::TestCase
  def setup
    @view = GenericView.new
  end
  test "meta tags" do
      #the tagger will output attributes alphabetically (by attr_name) inside the tag
    assert_equal '<meta content="elmer fuds wild hunting trips" property="og:title" />',
      @view.title("elmer fuds wild hunting trips")
    assert_equal '<meta content="sport" property="og:type" />', 
      @view.type("sport")
    assert_nil @view.type("shoes"), "Invalid open graph type"
    assert_equal '<meta content="http://rabbit-hunter.com/" property="og:url" />',
      @view.url("http://rabbit-hunter.com/")
    assert_equal '<meta content="http://ia.media-imdb.com/rock.jpg" property="og:image" />',
      @view.image("http://ia.media-imdb.com/rock.jpg")
    assert_equal '<meta content="Elmer Fuds Rabbit Hunting" property="og:site_name" />', 
      @view.site_name("Elmer Fuds Rabbit Hunting")
    assert_equal '<meta content="A group of hunters under the supreme direction of the master himself, Mr. Elmer J Fud." property="og:description" />', 
      @view.description("A group of hunters under the supreme direction of the master himself, Mr. Elmer J Fud.")
  end
  test "facebook-specific tags" do
    assert_equal '<meta content="98763456" property="fb:admins" />', 
      @view.admins(98763456)
    assert_equal '<meta content="ea2ffae4f24f" property="fb:app_id" />', 
      @view.app_id("ea2ffae4f24f")    
  end
  test "ui elements: like button, login button" do
    assert_equal '<fb:like href="http://hunting.elmerfud.com/" send="false">',
      @view.like_button("http://hunting.elmerfud.com/")
    assert_equal '<fb:like href="http://hunting.elmerfud.com/" send="true">',
      @view.like_button("http://hunting.elmerfud.com/", {:send => true})
    assert_equal '<fb:login-button>', @view.login_button
    assert_equal '<fb:login-button show-faces="true">', @view.login_button({'show-faces' => true})
      
  end
  # test "facebook javascript SDK include block" do
  #   example_block = <<-END
  #   <div id="fb-root"></div>
  #   <script src="http://connect.facebook.net/en_US/all.js"></script>
  #   <script>
  #     FB.init({ appId  : 'YOUR APP ID', status : true, cookie : true, xfbml: true, 
  #       channelURL : 'http://WWW.MYDOMAIN.COM/channel.html', oauth  : true });
  #   </script>
  #       END
  #   assert_equal example_block, 
  #     @view.init_fb_sdk_block
  # end
end