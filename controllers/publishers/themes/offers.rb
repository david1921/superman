# Offers (coupons) layout-finding and template-finding logic. Daily Deals use Themes. Ideally, offers should use Themes, too.
module Publishers
  module Themes
    module Offers
      def layout_for_publisher(publisher, directory = nil)
        directory ||= controller_name
        if File.exists?("#{Rails.root}/app/views/layouts/#{directory}/#{publisher.label}/public_index.html.liquid")
          "#{directory}/#{publisher.label}/public_index.html.liquid"
        elsif publisher.publishing_group && publisher.publishing_group.label.present? &&
              File.exists?("#{Rails.root}/app/views/layouts/#{directory}/#{publisher.publishing_group.label}/public_index.html.liquid")
          "#{directory}/#{publisher.publishing_group.label}/public_index.html.liquid"
        elsif File.exists?("#{Rails.root}/app/views/layouts/#{directory}/#{publisher.label}/public_index.html.erb")
          "#{directory}/#{publisher.label}/public_index.html.erb"
        else
          "#{directory}/public_index"
        end
      end

      def template_for_publisher(publisher, template)
        if (File.exists?("#{Rails.root}/app/views/#{controller_name}/#{publisher.label}/#{template}.html.erb") ||
            File.exists?("#{Rails.root}/app/views/#{controller_name}/#{publisher.label}/#{template}.html.liquid") ||
            File.exists?("#{Rails.root}/app/views/#{controller_name}/#{publisher.label}/#{template}.liquid"))
          "#{controller_name}/#{publisher.label}/#{template}"
        elsif publisher.publishing_group && publisher.publishing_group.label.present? &&
              (File.exists?("#{Rails.root}/app/views/#{controller_name}/#{publisher.publishing_group.label}/#{template}.liquid") ||
               File.exists?("#{Rails.root}/app/views/#{controller_name}/#{publisher.publishing_group.label}/#{template}.html.liquid"))
          "#{controller_name}/#{publisher.publishing_group.label}/#{template}"
        elsif File.exists?("#{Rails.root}/app/views/#{controller_name}/#{publisher.theme}/#{template}.html.erb")
          "#{controller_name}/#{publisher.theme}/#{template}"
        else
          "#{controller_name}/#{template}"
        end
      end
    end
  end
end
