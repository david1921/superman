require File.dirname(__FILE__) + "/../../../test_helper"

class GolfonBlogArticleTagTest < ActiveSupport::TestCase
  setup do
    @registers = { :controller => ApplicationController.new }
  end
  
  test "render with valid json" do
    expected = %Q{
<h2 id="blog_article_title">Welcome to GolfOn!</h2>
<div id='blog_article_excerpt'>Welcome to the GolfOn Blog, your spot to find the best deals on greens, tees and all things golf! Featured on our blog will be information about us of course, but in addition, you'll find the latest golf goings on, the best courses to crush, the latest golf gadgets, swing n' sand tips and more!  <a href="http://www.golfon.com/blog/2011/03/22/welcome-to-golfon/">Continue reading <span class="meta-nav">&rarr;</span></a></div>
}.lstrip
    Liquid::Tags::GolfonBlogArticle.any_instance.stubs(:get_url!).returns(blog_feed_as_json)
    assert_equal expected, Liquid::Template.parse("{% golfon_blog_article %}").render({}, :registers => @registers)
  end
  
  test "render with invalid json" do
    Liquid::Tags::GolfonBlogArticle.any_instance.stubs(:get_url!).returns(%Q{[{\"id\":1,\"title\":\"Welcome to GolfOn!\"}})
    assert_equal "No new articles.", Liquid::Template.parse("{% golfon_blog_article %}").render({}, :registers => @registers)
  end
  
  private
  
  def blog_feed_as_json
    %Q{
[{\"id\":1,\"title\":\"Welcome to GolfOn!\",\"permalink\":\"http:\\/\\/www.golfon.com\\/blog\\/2011\\/03\\/22\\/welcome-to-golfon\\/\",\"content\":\"<span style=\\\"font-family: Helvetica; font-size: small;\\\">Hey Golf Fans!\\r\\nWelcome to the GolfOn Blog, your spot to find the best deals on greens, tees and all things golf! Featured on our blog will be information about us of course, but in addition, you'll find the latest golf goings on, the best courses to crush, the latest golf gadgets, swing n' sand tips and more!\\r\\n\\r\\nKeep an eagle eye out for our posts and be sure to join our social networks:\\r\\nFollow us on Twitter <a href=\\\"http:\\/\\/twitter.com\\/getyour_golfon\\\">@getyour_golfon <\\/a>\\r\\nFan us on Facebook <\\/span><span style=\\\"font-family: Helvetica; color: #0037a3; font-size: small;\\\"><span style=\\\"text-decoration: underline;\\\"><a title=\\\"http:\\/\\/www.facebook.com\\/getyourgolfon\\\" href=\\\"http:\\/\\/www.facebook.com\\/getyourgolfon\\\">www.facebook.com\\/getyourgolfon<\\/a><\\/span><\\/span><span style=\\\"font-family: Helvetica; font-size: small;\\\">\\r\\n\\r\\nAnd never forget to Get Your Golf On.\\r\\nThe GolfOn Team<\\/span>\",\"excerpt\":\"Welcome to the GolfOn Blog, your spot to find the best deals on greens, tees and all things golf! Featured on our blog will be information about us of course, but in addition, you'll find the latest golf goings on, the best courses to crush, the latest golf gadgets, swing n' sand tips and more!  <a href=\\\"http:\\/\\/www.golfon.com\\/blog\\/2011\\/03\\/22\\/welcome-to-golfon\\/\\\">Continue reading <span class=\\\"meta-nav\\\">&rarr;<\\/span><\\/a>\",\"date\":\"2011-03-22 15:09:58\",\"author\":\"golfon\",\"categories\":[\"Fairway Blog\"],\"tags\":[]}]
}.strip
  end
  
end
