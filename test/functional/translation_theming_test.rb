require File.dirname(__FILE__) + "/../test_helper"

class ThemedTranslationsController < ApplicationController
  include Publishers::Themes

  def test_with_publisher
    @publisher = Publisher.find(params[:publisher_id])
    flash[:test] = translate_with_theme(:message)
    render :text => ""
  end

  def test_with_publishlishing_group
    @publishing_group = PublishingGroup.find(params[:publishing_group_id])
    flash[:test] = translate_with_theme(:message)
    render :text => ""
  end

  def test_no_publisher
    flash[:test] = translate_with_theme(:message)
    render :text => ""
  end
end

class ThemedTranslationsControllerTest < ActionController::TestCase
  context "publisher specific translations" do
    setup do
      I18n.stubs(:translate).returns(nil)
      I18n.stubs(:translate).with(:message, :scope => ["pub-group-label"], :raise => true).returns(nil)
      I18n.stubs(:translate).with(:message, :scope => ["pub-label"], :raise => true).returns(nil)
      I18n.stubs(:translate).with(:message, {}).returns("Default translation")
    end

    context "given a publisher is set" do
      setup do
        @publisher = Factory(:publisher, :label => "pub-label")
      end

      context "given no translation specified for the publisher" do
        should "return default translation" do
          get :test_with_publisher, :publisher_id => @publisher.to_param
          assert_equal "Default translation", flash[:test]
        end
      end

      context "given a translation specified for the publisher" do
        setup do
          I18n.stubs(:translate).with(:message, :scope => ["pub-label"], :raise => true).returns("Publisher's translation")
        end

        should "return publisher's translation" do
          get :test_with_publisher, :publisher_id => @publisher.to_param
          assert_equal "Publisher's translation", flash[:test]
        end
      end
    end

    context "given a publishing group is set" do
      setup do
        @publishing_group = Factory(:publishing_group, :label => "pub-group-label")
      end

      context "given no translation specified for the publishing group" do
        should "return default translation" do
          get :test_with_publishlishing_group, :publishing_group_id => @publishing_group.to_param
          assert_equal "Default translation", flash[:test]
        end
      end

      context "given a translation specified for the publishing group" do
        setup do
          I18n.stubs(:translate).with(:message, :scope => ["pub-group-label"], :raise => true).returns("Publishing group's translation")
        end

        should "return publishing groups's translation" do
          get :test_with_publishlishing_group, :publishing_group_id => @publishing_group.to_param
          assert_equal "Publishing group's translation", flash[:test]
        end
      end
    end

    context "given no publisher is set" do
      should "return default translation" do
        get :test_no_publisher
        assert_equal "Default translation", flash[:test]
      end
    end
  end
end
