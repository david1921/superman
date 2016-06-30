module CyberSource
  class FormBuilder < ActionView::Helpers::FormBuilder
    def hidden_field(method, options = {})
      options = options.dup
      super(method, options.merge!(:name => object.class.param_name(method)))
    end
    
    def text_field_div(method, options = {})
      options = options.dup
      if options.delete(:required)
        marker = "*"
        classes = options.delete(:class)
        options[:class] = classes ? "#{classes} required" : "required"
      else
        marker = "&nbsp;"
      end
      text = I18n.t("cyber_source.order.#{method}") + marker
      options.merge!(:name => object.class.param_name(method))
      %Q{
<div class="row">
  <div class="label">#{label(method, text.html_safe)}</div>
  <div class="input">#{text_field(method, options)}</div>
</div>}.html_safe
    end
  
    def select(method, choices, options = {}, html_options = {})
      html_options = html_options.dup
      html_options.merge!(:name => object.class.param_name(method))
      super(method, choices, options, html_options)
    end
    
    def select_div(method, choices, options = {}, html_options = {})
      options = options.dup
      if options.delete(:required)
        marker = "*"
        classes = html_options.delete(:class)
        html_options[:class] = classes ? "#{classes} required" : "required"
      else
        marker = "&nbsp;"
      end
      text = I18n.t("cyber_source.order.#{method}") + marker
      %Q{
<div class="row">
  <div class="label">#{label(method, text.html_safe)}</div>
  <div class="input">#{select(method, choices, options, html_options)}</div>
</div>}.html_safe
    end


    def state_province_div(method, choices, options = {}, html_options = {})
      %Q{
  <div class="row">
    <div class="label">#{label(method, options[:label_text], html_options)}</div>
    <div class="input" style="text-align:left;">#{select(method, choices, options, html_options)}</div>
  </div>
  }.html_safe
    end     
  end


end
