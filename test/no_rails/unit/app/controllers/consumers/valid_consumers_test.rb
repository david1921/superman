require File.dirname(__FILE__) + "/../../controllers_helper"

class ValidConsumersTest < Test::Unit::TestCase

  context "PublisherGroup#enable_force_valid_consumers" do

    setup do
      @flashes = {}
      @controller = stub("controller", :flash => @flashes, :edit_publisher_consumer_path => 'go_there').extend(::Consumers::ValidConsumers)
      @publishing_group = stub(:enable_force_valid_consumers? => true, :label => 'pork')
      @publisher = stub(:publishing_group => @publishing_group, :label => 'beef')
      @consumer = stub(:publisher => @publisher)
      @controller.stubs(:current_consumer).returns( @consumer)
      Analog::Themes::I18n.stubs(:t).returns('some translation test: beef')
    end

    context "invalid consumers" do
      setup do
        @consumer.stubs(:valid? => false)
      end

      should "redirect to the user edit page" do
        @controller.expects(:redirect_to).with('go_there')
        assert !@controller.ensure_valid_consumer
        assert_equal({:notice=>"some translation test: beef"}, @flashes)
      end

      should "not redirect to the edit page because the publishing group doesn't enforce valid consumers" do
        @publishing_group.stubs(:enable_force_valid_consumers?).returns(false)
        @controller.expects(:redirect_to).never
        assert @controller.ensure_valid_consumer
        assert_equal({}, @flashes)
      end
    end

    context "valid consumers" do
      should "not redirect to the edit page because the user is valid" do
        @consumer.stubs(:valid?).returns(true)
        @controller.expects(:redirect_to).never
        assert @controller.ensure_valid_consumer
        assert_equal({}, @flashes)
      end
    end
  end
end

