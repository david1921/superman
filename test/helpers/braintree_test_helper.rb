module BraintreeTestHelper
  module InstanceMethods 
    def braintree_sale_transaction(daily_deal_purchase, options={})
      if options[:amount]
        options[:amount] = BigDecimal.new(options[:amount].to_s)
      end
      options = { :type => Braintree::Transaction::Type::Sale, :status => Braintree::Transaction::Status::SubmittedForSettlement }.merge(options)
      braintree_transaction(daily_deal_purchase, options)
    end

    def braintree_transaction_submitted_result(daily_deal_purchase, options={})
      options = { :type => Braintree::Transaction::Type::Sale, :status => Braintree::Transaction::Status::SubmittedForSettlement }.merge(options)
      braintree_result(daily_deal_purchase, options)
    end

    def braintree_transaction_authorized_result(daily_deal_purchase, options = {})
      options = {
        :type   => Braintree::Transaction::Type::Sale,
        :status => Braintree::Transaction::Status::Authorized
      }.merge(options)
      braintree_result(daily_deal_purchase, options)
    end
    
    def braintree_transaction_failed_result(order)
      braintree_transaction = braintree_transaction_submitted_result(order)
      Braintree::TransparentRedirect.expects(:confirm).returns(braintree_transaction)    
      braintree_transaction.expects(:success?).returns(false)
      braintree_transaction.expects(:message).at_least_once.returns("credit card number is invalid")
      braintree_transaction.expects(:params).at_least_once.returns({})

      braintree_transaction.expects(:errors).at_least_once.returns(Braintree::ValidationErrorCollection.new({:errors => {}}))
    end
    
    def braintree_transaction_voided_result(daily_deal_purchase, options={})
      options = { :type => Braintree::Transaction::Type::Sale, :status => Braintree::Transaction::Status::Voided }.merge(options)
      braintree_result(daily_deal_purchase, options)
    end
    
    def braintree_transaction_refunded_result(daily_deal_purchase, options={})
      options = {
        :id => "cred#{'%02d' % next_index}", 
        :type => Braintree::Transaction::Type::Credit,
        :status => Braintree::Transaction::Status::SubmittedForSettlement
      }.merge(options)
      braintree_result(daily_deal_purchase, options)
    end

    def expect_braintree_partial_refund(daily_deal_purchase, amount)
      Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Settled))
      refunded_result = braintree_transaction_refunded_result(daily_deal_purchase, :amount => amount)
      Braintree::Transaction.expects(:refund).with(daily_deal_purchase.payment_gateway_id, amount).returns(refunded_result)
    end

    def expect_braintree_full_refund(daily_deal_purchase)
      Braintree::Transaction.stubs(:find).returns(braintree_sale_transaction(daily_deal_purchase, :status => Braintree::Transaction::Status::Settled))
      refunded_result = braintree_transaction_refunded_result(daily_deal_purchase)
      Braintree::Transaction.stubs(:refund).returns(refunded_result)
    end

    def expect_braintree_void(daily_deal_purchase)
      Braintree::Transaction.expects(:find).returns(braintree_sale_transaction(daily_deal_purchase))
      voided_result = braintree_transaction_voided_result(daily_deal_purchase)
      Braintree::Transaction.expects(:void).with(daily_deal_purchase.payment_gateway_id).returns(voided_result)
    end

    def braintree_credit_card_created_result(consumer, options = {})
      index = next_index
      bin = options[:bin] || "411111"
      last_4 = options[:last_4] || "1111"
      expiration_month = options[:expiration_month] || "12"
      expiration_year = options[:expiration_year] || "2020"
      mock("braintree_result_#{index}").tap do |result|
        result.stubs({ 
          :success? => true,
          :credit_card => mock.tap do |credit_card|
            credit_card.stubs(
              :token => options[:token] || "%06d" % index,
              :bin => bin,
              :card_type => options[:card_type] || "Visa",
              :cardholder_name => options[:cardholder_name] || "John Public",
              :customer_id => consumer.id_for_vault,
              :expiration_month => expiration_month,
              :expiration_year => expiration_year,
              :expiration_date => "#{expiration_month}/#{expiration_year}",
              :last_4 => last_4,
              :masked_number => "#{bin}******#{last_4}",
              :default? => options[:default] || false,
              :billing_address => options[:billing_address]
            )
          end
        })
      end
    end

    def braintree_customer_created_result(consumer, options = {})
      index = next_index
      bin = options[:bin] || "411111"
      last_4 = options[:last_4] || "1111"
      expiration_month = options[:expiration_month] || "12"
      expiration_year = options[:expiration_year] || "2020"
      mock("braintree_result_#{index}").tap do |result|
        result.stubs({
          :success? => true,
          :customer => mock.tap do |customer|
          customer.stubs(
            :id => consumer.id_for_vault,
            :credit_cards => [
              mock.tap do |credit_card|
                credit_card.stubs(
                  :token => options[:token] || "%06d" % index,
                  :bin => bin,
                  :card_type => options[:card_type] || "Visa",
                  :cardholder_name => options[:cardholder_name] || "John Public",
                  :customer_id => consumer.id_for_vault,
                  :expiration_month => expiration_month,
                  :expiration_year => expiration_year,
                  :expiration_date => "#{expiration_month}/#{expiration_year}",
                  :last_4 => last_4,
                  :masked_number => "#{bin}******#{last_4}",
                  :default? => options[:default] || false,
                  :billing_address => options[:billing_address]
                )
              end
            ]
          )
          end
        })
      end
    end

    def braintree_validation_errors_result(errors)
      mock("braintree_result_#{next_index}").tap do |result|
        result.stubs(
          :success? => false,
          :errors => errors.map { |error| OpenStruct.new(error) }
        )
      end
    end
    
    def braintree_credit_card_processor_declined_result
      mock("braintree_result_#{next_index}").tap do |result|
        result.stubs(
          :success? => false,
          :errors => [],
          :credit_card_verification => mock().tap do |verification|
            verification.stubs(
              :status => "processor_declined",
              :processor_response_code => "2000",
              :processor_response_text => "Do Not Honor"
            )
          end
        )
      end
    end

    def braintree_credit_card_gateway_rejected_result
      mock("braintree_result_#{next_index}").tap do |result|
        result.stubs(
          :success? => false,
          :errors => [],
          :credit_card_verification => mock().tap do |verification|
            verification.stubs(
              :status => "gateway_rejected",
              :gateway_rejection_reason => "cvv"
            )
          end
        )
      end
    end

    private

    def braintree_transaction(daily_deal_purchase_or_order, options)
      default_id = "#{next_index}"
      mock("braintree_transaction_#{options[:id] || daily_deal_purchase_or_order.payment_gateway_id || default_id}").tap do |object|
        object.stubs({
          :id => daily_deal_purchase_or_order.payment_gateway_id || default_id,
          :created_at => Time.zone.now,
          :order_id => daily_deal_purchase_or_order.analog_purchase_id,
          :amount => BigDecimal.new(daily_deal_purchase_or_order.total_price.to_s),
          :merchant_account_id => daily_deal_purchase_or_order.publisher.merchant_account_id,
          :credit_card_details => mock.tap { |ccd|
            ccd.stubs(:last_4 => "4545")
            ccd.stubs(:cardholder_name => "Scott Willson")
            ccd.stubs(:bin => "411111")
            ccd.stubs(:token => "abc123")
            ccd.stubs(:card_type => "Visa")
            ccd.stubs(:expiration_date => "05/2012")
          },
          :billing_details => mock.tap { |bd|
            bd.stubs(:first_name => "Jon")
            bd.stubs(:last_name => "Smith")
            bd.stubs(:street_address => "123 Main St")
            bd.stubs(:extended_address => "Apt 100")
            bd.stubs(:locality => "Portland")
            bd.stubs(:region => "OR")
            bd.stubs(:postal_code => "90210")
            bd.stubs(:country_code_alpha2 => "US")
          },
          :customer_details => mock.tap { |cd|
            cd.stubs(:id => daily_deal_purchase_or_order.consumer.id_for_vault)
          },
          :custom_fields => nil
        }.merge(options))
      end
    end
    
    def braintree_result(daily_deal_purchase, options)
      mock("braintree_result_#{next_index}").tap do |object|
        object.stubs :success? => true, :transaction => braintree_transaction(daily_deal_purchase, options)
      end
    end

    def next_index
      @braintree_test_helper_index ||= 0
      @braintree_test_helper_index  += 1
    end
  end
end

ActiveSupport::TestCase.send :include, BraintreeTestHelper::InstanceMethods
