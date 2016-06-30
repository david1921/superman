require "test/system/system_test"

class FacebookAuthTest < SystemTest

  def run
    publisher_or_group = find_publisher_or_group("villagevoicemedia")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "a2f96a736109115591b8fa389932a987", client.id
    assert_equal "f2d759aa0d79950ad86da339a58c6f04", client.secret
    publisher_or_group = find_publisher_or_group("newsday")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "69011d29a21b51c15479b0b3d299cb16", client.id
    assert_equal "35df97c13686f72b27bf607110335fae", client.secret
    publisher_or_group = find_publisher_or_group("entercom")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "7b2e988c98f5efaa2c3f90cc1bea10a2", client.id
    assert_equal "26e9e08c6c86ac0e1fcc7620b05f7af7", client.secret
    publisher_or_group = find_publisher_or_group("clickondetroit")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "ce14395cb7316fd27734d6e876f95cd3", client.id
    assert_equal "5d9f562f29515bc054481ba6f710aa77", client.secret
    publisher_or_group = find_publisher_or_group("shelbystar")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "ab920e3c30c3744205f66fc5368654a5", client.id
    assert_equal "ea5865cfbecde178aecc5631fc510114", client.secret
    publisher_or_group = find_publisher_or_group("gastongazette")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "c10fdd6f4f2c4db15e65820641aa2a67", client.id
    assert_equal "f7ddfb22120609501abf2cfcf8cf7b6d", client.secret
    publisher_or_group = find_publisher_or_group("oaoa")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "6f47773698b5404a8dcd0fdfdda14a23", client.id
    assert_equal "514229dbd3f22ee068a05c9a9bf86843", client.secret
    publisher_or_group = find_publisher_or_group("gazette")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "ce5cf9da173657a7410bf70191ea5955", client.id
    assert_equal "55a24d94e36ca6fcdc084e73246874c2", client.secret
    publisher_or_group = find_publisher_or_group("ocregister")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "c317772e3eb73c9e98fb1520aeac6630", client.id
    assert_equal "75757b52e80dc51c5d4001e8881e51af", client.secret
    publisher_or_group = find_publisher_or_group("themonitor")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "3681b46d198329d4e634f5ed82b22a5f", client.id
    assert_equal "b3b58aaf1066a6c30a2fda689220c982", client.secret
    publisher_or_group = find_publisher_or_group("rsvp")
    client = FacebookAuth.oauth2_client(publisher_or_group, "production")
    assert_equal "ede5d1ac74d134e014a5c094475b8124", client.id
    assert_equal "b1ff1348ee3a5c884fb7aa0262f450b9", client.secret
  end

  def find_publisher_or_group(label)
    puts "#{label}..."
    result = PublishingGroup.find_by_label(label)
    result ||= Publisher.find_by_label(label)
  end

end


FacebookAuthTest.new(ARGV).run
