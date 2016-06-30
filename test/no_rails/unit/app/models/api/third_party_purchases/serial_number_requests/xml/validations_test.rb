require File.dirname(__FILE__) + "/../../../../../models_helper"

# hydra class Api::ThirdPartyPurchases::SerialNumberRequests::Xml::ValidationsTest

module Api::ThirdPartyPurchases::SerialNumberRequests::Xml
  class ValidationsTest < Test::Unit::TestCase
    def setup
      @obj = Object.new.extend(Api::ThirdPartyPurchases::SerialNumberRequests::Xml::Validations)
      @errors = mock('errors')
      @obj.stubs(:errors).returns(@errors)
    end

    context "#validate_xml_root" do
      should "add an error when root != 'daily_deal_purchases' or root is nil" do
        doc = Nokogiri::XML(<<EOF)
<not_daily_deal_purchase></not_daily_deal_purchase>
EOF
        @errors.expects(:add).with(:xml, "document root is not <daily_deal_purchase>").times(2)
        @obj.validate_xml_root(doc)
        @obj.validate_xml_root(Nokogiri::XML(""))
      end

      should "not add an error if the root is <daily_deal_purchase>" do
        doc = Nokogiri::XML(<<EOF)
        <daily_deal_purchase/>
EOF
        @obj.expects(:errors).never
        @obj.validate_xml_root(doc)
      end
    end

    context "#validate_xml_uuid(node)" do
      should "add an error when root has no uuid" do
        doc = Nokogiri::XML(<<EOF)
<daily_deal_purchase></daily_deal_purchase>
EOF
        @errors.expects(:add).with(:xml, "document root is missing 'uuid' attribute")
        @obj.validate_xml_uuid(doc)
      end

      should "not add an error if uuid is not blank" do
        doc = Nokogiri::XML(<<EOF)
<daily_deal_purchase uuid="not blank"></daily_deal_purchase>
EOF
        @obj.expects(:errors).never
        @obj.validate_xml_uuid(doc)
      end

      should "not add an error if root is nil" do
        doc = Nokogiri::XML("")
        @obj.expects(:errors).never
        @obj.validate_xml_uuid(doc)
      end
    end

    context "#validate_xml_purchase_elements(node)" do
      should "not validate anything when root is nil" do
        doc = Nokogiri::XML('')
        @obj.expects(:validate_xml_presence).never
        @obj.validate_xml_purchase_elements(doc)
      end

      context "with root" do
        setup do
          @doc = Nokogiri::XML('<root></root>')
          @obj.expects(:validate_xml_presence).at_least(1)
        end

        context "stubbing voucher request valiidation" do
          setup do
            @obj.expects(:validate_xml_voucher_requests).at_least(1)
          end

          should "validate the presence of daily_deal_listing" do
            @obj.expects(:validate_xml_presence).with(:daily_deal_listing, @doc.root)
            @obj.validate_xml_purchase_elements(@doc)
          end

          should "add an error when root is missing <executed_at>" do
            @obj.expects(:validate_xml_presence).with(:executed_at, @doc.root)
            @obj.validate_xml_purchase_elements(@doc)
          end

          should "add an error when root is missing <gross_price>" do
            @obj.expects(:validate_xml_presence).with(:gross_price, @doc.root)
            @obj.validate_xml_purchase_elements(@doc)
          end

          should "add an error when root is missing <actual_purchase_price>" do
            @obj.expects(:validate_xml_presence).with(:actual_purchase_price, @doc.root)
            @obj.validate_xml_purchase_elements(@doc)
          end

          should "add an error when root is missing <voucher_requests>" do
            @obj.expects(:validate_xml_presence).with(:voucher_requests, @doc.root)
            @obj.validate_xml_purchase_elements(@doc)
          end
        end

        should "validate the voucher requests" do
          @obj.expects(:validate_xml_voucher_requests).with(@doc.root)
          @obj.validate_xml_purchase_elements(@doc)
        end
      end
    end

    context "#validate_xml_voucher_requests(node)" do
      should "add an error when node has no <voucher_request> elements" do
        doc = Nokogiri::XML(<<EOF)
<root><voucher_requests/></root>
EOF
        @errors.expects(:add).with(:xml, [:voucher_request, :missing])
        @obj.validate_xml_voucher_requests(doc.root)
      end

      should "validate each voucher request" do
        doc = Nokogiri::XML(<<EOF)
<root><voucher_requests><voucher_request/><voucher_request/></root>
EOF
        doc.search('voucher_request').each do |vr|
          @obj.expects(:validate_voucher).with(vr)
        end
        @obj.validate_xml_voucher_requests(doc.root)
      end
    end

    context "#validate_voucher(node)" do
      should "validate the redeemer name" do
        node = mock('node')
        @obj.expects(:validate_xml_presence).with(:redeemer_name, node)
        @obj.stubs(:validate_xml_sequence)
        @obj.validate_voucher(node)
      end

      should "validate the sequence" do
        node = mock('node')
        @obj.stubs(:validate_xml_presence)
        @obj.stubs(:validate_xml_sequence).with(node)
        @obj.validate_voucher(node)
      end
    end

    context "#validate_xml_presence(attr, node)" do
      should "add an error when node missing element with specified name" do
        doc = Nokogiri::XML("<root/>")
        @errors.expects(:add).with(:xml, "name is missing")
        @obj.validate_xml_presence(:name, doc.root)
      end

      should "add an error with the element is blank" do
        doc = Nokogiri::XML("<root><blank_node/></root>")
        @errors.expects(:add).with(:xml, "blank_node cannot be blank")
        @obj.validate_xml_presence(:blank_node, doc.root)
      end
    end

    context "#validate_xml_sequence(node)" do
      setup do
        @doc = Nokogiri::XML('')
      end

      should "not add an error when valid" do
        node = Nokogiri::XML::Node.new 'blank_sequence', @doc
        node['sequence'] = '123'
        @obj.expects(:errors).never
        @obj.validate_xml_sequence(node)
      end

      should "check for presence" do
        node = Nokogiri::XML::Node.new 'without_sequence', @doc
        @errors.expects(:add).with(:xml, [:sequence, :missing])
        @obj.validate_xml_sequence(node)
      end

      should "check for not blank" do
        node = Nokogiri::XML::Node.new 'blank_sequence', @doc
        node['sequence'] = ''
        @errors.expects(:add).with(:xml, [:sequence, :blank])
        @obj.validate_xml_sequence(node)
      end

      should "check for numeric" do
        node = Nokogiri::XML::Node.new 'blank_sequence', @doc
        node['sequence'] = 'not numeric'
        @errors.expects(:add).with(:xml, [:sequence, :invalid])
        @obj.validate_xml_sequence(node)
      end
    end
  end
end
