require File.dirname(__FILE__) + "/../../../test_helper"

# hydra class BlueCrossBlueShield::PlanImpoterTest
module BlueCrossBlueShield
  class PlanImpoterTest < ActiveSupport::TestCase

    context "PlanImporter" do
      setup do
        @publishing_group = Factory(:publishing_group)

        @kc_publisher = Factory(:publisher, :publishing_group => @publishing_group, :name => "BCBS Kansas City", :launched => false)
        @ma_publisher = Factory(:publisher, :publishing_group => @publishing_group, :name => "BCBS Massachusetts")
        @nowhere_publisher = Factory(:publisher, :publishing_group => @publishing_group, :name => "BCBS Nowhere")
      end

      context "given valid plans" do
        should "find correct number of plans" do
          importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)
          assert_equal 3, importer.publishers.size
        end

        should "assign correct plan attributes" do
          importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)
          publishers = importer.publishers

          membership_codes = importer.membership_codes

          kc_plan = publishers["BCBS Kansas City"]
          ma_plan = publishers["BCBS Massachusetts"]
          nowhere_plan = publishers["BCBS Nowhere"]

          assert kc_plan.launched?
          assert_equal "BCBSKC", kc_plan.label

          assert ma_plan.launched?
          assert_equal "bcbsma", ma_plan.label

          assert !nowhere_plan.launched?

          assert_equal 4, membership_codes[:additions].length
          assert_equal 2, membership_codes[:deletions].length
        end

        context "import" do
          should "not return errors on valid input" do
            importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)
            importer.import
            assert_equal 0, importer.errors.size
          end

          context "with an existing plan with existing membership codes" do
            setup do
              Factory(:publisher_membership_code, :publisher => @kc_publisher, :code => "WGC")
              Factory(:publisher_membership_code, :publisher => @kc_publisher, :code => "AGC")
              Factory(:publisher_membership_code, :publisher => @kc_publisher, :code => "XYZ")
              Factory(:publisher_membership_code, :publisher => @kc_publisher, :code => "QRS")
            end

            should "not return errors on valid input" do
              importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)
              importer.import
              assert_equal 0, importer.errors.size
            end

            should "update existing plan's attributes" do
              importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)

              assert_no_difference 'Publisher.count' do
                importer.import
                assert @kc_publisher.reload.launched?
              end
            end

            should "reassign membership codes" do
              importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)
              importer.import

              @kc_publisher.reload
              ma_plan = Publisher.find_by_name("BCBS Massachusetts")

              assert_equal %w(WGC), ma_plan.publisher_membership_codes.map(&:code)
              assert_equal %w(AGC YBB YBF), @kc_publisher.publisher_membership_codes.map(&:code).sort
            end

            should "delete requested membership codes" do
              importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group)
              importer.import

              assert !@publishing_group.publisher_membership_codes.find_by_code("XYZ")
              assert !@publishing_group.publisher_membership_codes.find_by_code("QRS")
            end
          end

          should "not save records when :dry_run option is true" do
            importer = PlanImporter.new(test_file_path('valid_plans.csv'), @publishing_group, :dry_run => true)

            assert_no_difference 'PublisherMembershipCode.count' do
              importer.import
              assert !@kc_publisher.reload.launched?
            end
          end
        end
      end

      context "given invalid plan rows" do
        setup do
          @importer = PlanImporter.new(test_file_path('invalid_plans.csv'), @publishing_group)
        end

        should "report an error when a plan has no name" do
          @importer.import
          assert_match /^Plan name not given for line:/, @importer.errors.second
        end

        should "report an erorr when a value does not match across plan rows" do
          @importer.import
          assert @importer.errors.include?("Value for publisher 'BCBS Kansas City' not the same across all rows: launched")
        end

        should "not create any plans or membership codes on failed import" do
          assert_no_difference 'Publisher.count' do
            assert_no_difference 'PublisherMembershipCode.count' do
              @importer.import
              assert !@kc_publisher.reload.launched?
            end
          end
        end
      end
    end

    def test_file_path(filename)
      File.join(File.dirname(__FILE__), 'data', filename)
    end
  end
end
