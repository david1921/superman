module TravelsaversHelper
  
  def travelsavers_errors_user_can_fix
    render :partial => "daily_deal_purchases/travelsavers_errors_user_can_fix"
  end
  
  def travelsavers_checkout_form_value(field_name)
    flash[:travelsavers_checkout_form_values][field_name] rescue nil
  end

  def travelsavers_booking_redemption_date(booking)
    booking.service_start_date.present? ? I18n.localize(booking.service_start_date.to_date, :format => :long) : nil
  end
  alias_method :travelsavers_booking_expiry_date, :travelsavers_booking_redemption_date

  def travelsavers_booking_purchased_on(booking)
    if booking.payment_succeeded?
      booking.daily_deal_purchase.humanize_executed_at 
    else
      "Payment status: #{booking.payment_status.capitalize}"
    end
  end
  
  def convert_field_name_to_id(field_name)
    field_name.
      gsub(/\[/, "_").
      gsub(/\](?!$)/, "_").
      sub(/\]$/, "").
      squeeze("_")
  end
  
  def label_text_for_field_name(field_name, label_text)
    return label_text.strip if label_text.present?
    
    field_name.
      tr("[]", " ").
      gsub("_", " ").
      strip.
      titleize
  end
  
  def travelsavers_text_field_div(field_name, options = {})
    raise ArgumentError, "field_name can't be blank" unless field_name.present?
    required_class = options[:required] ? 'required' : ''
    field_id = convert_field_name_to_id(field_name)
    label_text = label_text_for_field_name(field_name, options[:label_text])
    %Q{
      <div class="row">
        <label for="#{field_id}">#{label_text}</label>
        <input type="text" id="#{field_id}" name="#{field_name}" value="#{travelsavers_checkout_form_value(field_name)}" maxlength="#{options[:maxlength]}" class="#{required_class} #{options[:validate_as]}">
      </div>
    }.html_safe
  end
  
  def travelsavers_check_box_div(field_name, options = {})
    raise ArgumentError, "field_name can't be blank" unless field_name.present?
    required_class = options[:required] ? 'class="required"' : ""
    field_id = convert_field_name_to_id(field_name)
    label_text = label_text_for_field_name(field_name, options[:label_text])
    checked = travelsavers_checkout_form_value(field_name) == "1" ? "checked='checked'" : ''
    %Q{
      <div class="row">
        <input style="width: 20px; margin-top: 10px" type="checkbox" id="#{field_id}" name="#{field_name}" value="1" #{required_class} #{checked}>
        <label for="#{field_id}" style="width: 200px">#{label_text}</label>
      </div>
    }.html_safe
  end
  
  def travelsavers_select_div(field_name, options_for_select, options)
    field_id = convert_field_name_to_id(field_name)
    label_text = label_text_for_field_name(field_name, options[:label_text])
    include_blank = options[:include_blank]
    classes = options[:class] || ""
    classes += " required" if options[:required]
    field_value = travelsavers_checkout_form_value(field_name)
    
    select_div = '<div class="row">'
    select_div << "<label for='#{field_id}'>#{label_text}</label>"
    select_div << "<select id='#{field_id}' name='#{field_name}' class='#{classes}'>"
    select_div << '<option value=""></option>' if include_blank
    options_for_select.each do |opt|
      selected = if field_value.present? && field_value.to_s == opt.second.to_s
        "selected='selected'"
      else
        ''
      end
      
      select_div << "<option value='#{opt.second}' #{selected}>#{opt.first}</option>"
    end
    select_div << "</select>"
    select_div << "</div>"
    select_div.html_safe
  end
  
  def travelsavers_card_type_select_options
    [
      ["American Express", "AX"],
      ["MasterCard", "MC"],
      ["Visa", "VI"],
      ["Discover", "DS"]
    ]
  end
  
  def travelsavers_region_select_options
    Addresses::Codes::US::STATE_NAMES_BY_CODE.inject([]){|s,e| s << [e[1], e[0]]}.sort
  end
  
  def travelsavers_title_select_options
    [
      ["Mr", "Mr"],
      ["Ms", "Ms"],
      ["Mrs", "Mrs"],
      ["Miss", "Miss"],
      ["Dr", "Dr"],
      ["Mstr", "Mstr"]
    ]
  end
  
  def travelsavers_gender_select_options
    [["Male", "M"], ["Female", "F"]]
  end
  
end
