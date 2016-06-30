require File.dirname(__FILE__) + "/system_test"

class YelpTest < SystemTest
  def run
    # BCBSA's credentials
    credentials = {
      :consumer_key => "wt08Nwm4V73XaGnwYBc6ng",
      :consumer_secret => "ClgjsOrYXsiOr_sJ4kMzDhzO5io",
      :token => "H-DBCV_ycWOZrlKakTkxCg4-uI1Kxohr",
      :token_secret => "QMqQUZsyKRI4em6AJYEmkktyb-s"
    }

    client = Yelp::Client.new(credentials)

    response = client.find_business("katsura-japanese-restaurant-vancouver")
    assert_equal "Katsura Japanese Restaurant", response[:name]

    response = client.find_business("not-a-real-business")
    assert_equal nil, response
  end

end

YelpTest.new(ARGV).run
