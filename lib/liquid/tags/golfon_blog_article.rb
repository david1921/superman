require "open-uri"

module Liquid
  module Tags
    class GolfonBlogArticle < Liquid::Tag
      FAIRWAY_BLOG_JSON_FEED_URL = "http://www.golfon.com/blog/?feed=json"

      def render(context)
        blog_json = fetch_blog_article_json!

        if blog_json.present?
          blog_article = %Q{<h2 id="blog_article_title">#{blog_json["title"]}</h2>\n}
          blog_article << "<div id='blog_article_excerpt'>#{blog_json["excerpt"]}</div>\n"
        else
          default_content
        end
      rescue
        default_content
      end
      
      private
      
      def default_content
        "No new articles."
      end
      
      def fetch_blog_article_json!
        blog_json = JSON.parse get_url!(FAIRWAY_BLOG_JSON_FEED_URL)
        blog_json[0]
      rescue
        nil
      end
      
      def get_url!(url)
        open(url).read
      end
    end
  end
end