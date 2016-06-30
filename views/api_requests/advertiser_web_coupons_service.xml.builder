xml.instruct! :xml, :version => '1.0'
xml.service_response(:type => @service_name) do
  xml.advertiser(:id => @advertiser.id) do
   xml.web_coupons do
     xml.html_head do
       port  = request.port.present? && request.port != 80 ? ":#{request.port}" : ""
       host  = "http://#{@publisher.production_host}#{port}"
       js    = %w( prototype effects dragdrop controls business xd_business ).collect {|js| javascript_include_tag( "#{host}/javascripts/#{js}.js") }.join("\n")
       css   = stylesheet_link_tag("#{host}/stylesheets/#{@publisher.label}/businesses.css") 
       xd_js = "<script>\n";
       xd_js += "Analog.Business.setAnalogBaseUrl(\"http://#{AppConfig.default_host}\");\n"
       xd_js += "Analog.Business.setXdReceiverPath(\"/xd_receiver.html\");\n"
       xd_js += "</script>\n"
       
       xml.cdata!(js + "\n" + css + "\n" + xd_js)
     end
     xml.html_body do
       xml.cdata!(render( :partial => "advertisers/sdcitybeat/widget.html.erb", :locals => {:business => @advertiser} ))
     end
   end
  end
end