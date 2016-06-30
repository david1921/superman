class BraintreeFormBuilder < Analog::FormBuilder
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper


  def initialize(object_name, object, template, options, proc)
    super
    @braintree_result = @options[:result]
  end

  def display_braintree_error_messages
    return "" unless braintree_error_messages.any?
    %Q{
<div class="daily_deal_purchase_errors">
  <h3>#{I18n.t("daily_deal_purchases.braintree_buy_now_form.payment_error_message_header")}</h3>
  <ul>#{braintree_error_messages.map{|error| "<li>#{error[1][:message]}</li>"}}</ul>
</div>
    }.html_safe
  end

  def fields_for(record_name, *args, &block)
    options = args.extract_options!
    options[:builder] = BraintreeFormBuilder
    options[:result] = @braintree_result
    new_args = args + [options]
    super record_name, *new_args, &block
  end

  def text_field(method, options = {})
    field = super(method, options.merge(:value => determine_value(method)))
    content_tag("div", field, :class => error_on(method) ? "fieldWithErrors" : "")
  end
  
  
  def expiration_date_div(label_text = nil,options = {})
    label_options = options.delete(:label_options) || {}
    month_options = options.delete(:month_options) || {}
    year_options  = options.delete(:year_options) || {}
    %Q{
<div class="row">
  <div class="label">#{label(nil, label_text, label_options, true)}</div>
  <div class="expiration_date">
    #{select :expiration_month, month_options}
    #{select :expiration_year, year_options}
  </div>
</div>}.html_safe
  end

  def braintree_select_div(method, choices, options = {}, html_options = {})
    %Q{
<div class="row">
  <div class="label">#{label(method, options[:label_text], html_options, true)}</div>
  <div class="input" style="text-align:left;">#{select(method, choices, options, html_options)}</div>
</div>
}.html_safe
  end
  
  def cvv_div(label_text, options = {})
    label_options       = options.delete(:label_options) || {}
    text_field_options  = options.delete(:text_field_options) || {}
    text_field_options.reverse_merge!({ :size => 4, :class => "autowidth required"})
    cvv_popup_url = "/#{I18n.locale.to_s}/what-is-cvv"
    %Q{
<div class="row">
  <div class="label">#{label(:cvv, label_text + " *", label_options, true)}</div>
  <div class="input">
    <div class="transaction_credit_card_cvv" style="text-align: left">
      #{text_field(:cvv, text_field_options)}
      <a id="what-is-cvv" href="#{cvv_popup_url}" onclick="window.open('#{cvv_popup_url}', '', 'width=560,height=315,left=200,top=200,status=no,toolbar=no,location=no,menubar=no,titlebar=no'); return false">#{I18n.t('whats_this')}</a>
    </div>
  </div>
  <div class="help"></div>
</div>}.html_safe
  end  

  protected

  def determine_value(method)
    braintree_params = @braintree_result && @braintree_result.params[:transaction] if @braintree_result && @braintree_result.params
    if braintree_params
      braintree_params[method]
    else
      nil
    end
  end

  # def validation_errors(method)
  #   if @braintree_errors && @braintree_errors.on(method).present?
  #     @braintree_errors.on(method).map do |error|
  #       content_tag("div", ERB::Util.h(error.message), {:style => "color: red;"})
  #     end.join
  #   else
  #     ""
  #   end
  # end
  
  def braintree_error_messages
    # TODO: need to grap the errors from the result object, if there's no errrors then check the message attribute.
    return @braintree_error_messages if @braintree_error_messages
    @braintree_error_messages = HashWithIndifferentAccess.new
    if @braintree_result
      if @braintree_result.errors.any?
        @braintree_result.errors.each do |e|
          @braintree_error_messages[e.attribute] = {:message => e.message}
        end
      elsif @braintree_result.message.present?
        @braintree_error_messages[:base] = {:message => @braintree_result.message}
      end
    end
    return @braintree_error_messages
  end
  
  def error_on(method)
    return braintree_error_messages[method]
  end
end
