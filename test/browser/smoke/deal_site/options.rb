require File.dirname(__FILE__) + "/deal_site"

module Smoke
  module DealSite
    class Options < Smoke::SmokeOptions

      def add_options(slop)
        super
        slop.on :publishers, "Publishers or absent for all", :optional_argument => true, :as => Array
        slop.on :publishing_group=, "A single PublishingGroup. Only use when running against a local db.", :optional_argument => true
        slop.on :parent_themes, "All publishers belonging to any parent_theme listed", :optional_argument => true, :as => Array
        slop.on :pre_create_consumers, "Use the database to pre-create consumer accounts for all pubs and use these instead of the signup form.", :optional_argument => true
        slop.on :email=, "Use this email", :optional_argument => true
        slop.on :password=, "Use this password", :optional_argument => true
        slop.on :clear_failures, "Cleared failed publishers before running", :optional_argument => true
        slop.on :fresh_run, "Start fresh with a new run", :optional_argument => true
        slop.on :force, "Remove specific publishers from successes before starting run", :optional_argument => true
        slop.on :status, "Print status and exit", :optional_argument => true
        slop.on :refresh_publishers, "Fetch publishers again to only get pubs with current or future active deals", :optional_argument => true
      end

    end
  end
end