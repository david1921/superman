class HomeController < ApplicationController
  include Publishers::Themes

  before_filter :check_for_locm, :only => :index

  def index
    if current_user and current_user.affiliate?
      redirect_to affiliate_publisher_daily_deals_path(current_user.publisher)
    elsif request.subdomains.include?("reports")
      redirect_to reports_path
    elsif (publisher = find_publishers_by_host.first)
      if publisher.coupons_homepage == "map"
        redirect_to send("#{publisher.label}_seo_map_url")
      else
        redirect_to render_public_offers_path(publisher)
      end
    else
      with_demo_or_regular_login do
        redirect_to_or_render_home_page(current_user)
      end
    end
  end

  def txt411_index
    render(:template => "txt411/index", :layout => "txt411/application")
  end

  def privacy_policy
    render(:template => "txt411/privacy_policy", :layout => "txt411/application")
  end

  def support
    render(:template => "txt411/support", :layout => "txt411/application")
  end

  def terms_and_conditions
    render(:template => "txt411/terms_and_conditions", :layout => "txt411/application")
  end

  def sitemap
    @host = request.host
    @publishers = find_publishers_by_host
    respond_to do |format|
      format.xml {
        render(:template => "publishers/sitemap", :layout => false)
      }
    end
  end

  protected
  def find_publishers_by_host
    Publisher.find_all_by_production_host(request.host)
  end

  private

  def redirect_to_or_render_home_page(user)
    if User.demo_user_exists? && user.demo?
      redirect_to publisher_advertisers_path(user.publisher) and return
    end

    if user.has_admin_privilege?
      redirect_to publishers_path
    else
      company = user.company
      case
        when company.is_a?(PublishingGroup) && company.self_serve?
          redirect_to publishing_group_publishers_path(company)
        when company.is_a?(Publisher) && company.self_serve?
          begin
            render with_theme(:template => 'admin/index', :layout => 'application')
          rescue ActionView::MissingTemplate
            redirect_to publisher_advertisers_path(company)
          end
        when company.is_a?(Advertiser) && company.publisher.advertiser_self_serve?
          redirect_to edit_advertiser_path(company)
        else
          redirect_to reports_path
      end
    end
  end

  private

  def check_for_locm
    if param = params[:param]
      redirect_to new_session_path(:param => params[:param])
    end
  end
end
