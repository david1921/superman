######################################################################
# Module that supports certificate validation via ifbyphone.
######################################################################
module CertificatesIvr

  def self.included(base)
    base.class_eval do
      before_filter :set_serial_number
      before_filter :set_ivr_certificate
    end
  end

  def ivr_validate
    if [@serial_number, params[:survo_1], params[:survo_2]].all?(&:present?)
      status, redeemable = case @ivr_certificate.try(:redeemable?)
        when nil  : ["not valid", false]
        when true: ["confirmed as valid", true]
        when false : ["already marked as redeemed", false]
      end

      intro = "Certificate, #{ivr_serial_number}, is #{status}!"
      if redeemable
        intro += " For #{@ivr_certificate.advertiser.name}, with a value of, #{@ivr_certificate.humanize_value}."
      end
      next_survo_id, message = case redeemable
        when true : [params[:survo_2], "#{intro}"]
        when false: [params[:survo_1], "#{intro} To verify another certificate, please"]
      end

      render :xml => invoke_ivr_survo(next_survo_id, {
        :please => message,
        :p_t => "serial_number|#{@serial_number}"
      })
    else
      render :nothing => true, :status => :bad_request
    end
  end

  def ivr_redeem
    if [@serial_number, params[:option], params[:survo_1]].all?(&:present?)
      #
      # IVR option 1 = redeem current certificate, option 2 = validate another certificate
      #
      if params[:option] == "1"
        if @ivr_certificate
          @ivr_certificate.redeem!
          status = "now marked as redeemed"
        else
          status = "not valid"
        end
        message = "Certificate, #{ivr_serial_number}, is #{status}! To verify another certificate, please"
      else
        message = "Please"
      end
      render :xml => invoke_ivr_survo(params[:survo_1], {
        :please => message
      })
    else
      render :nothing => true, :status => :bad_request
    end
  end

  def ivr_serial_number
    @serial_number.gsub(/\D/, "").scan(/./).join(", ")
  end

  def invoke_ivr_survo(survo_id, options)
    { :app => "SurVo",
      :parameters => {
        :id => survo_id,
        :user_parameters => options.except(:p_t)
      }.merge(options.slice(:p_t))
    }.to_xml(:root => "action", :dasherize => false)
  end

  def p_t_params
    returning Hash.new do |hash|
      params[:p_t].to_s.split("||").each do |pair|
        key, val = pair.split("|").map(&:strip)
        hash[key] = val if key.present?
      end
    end
  end

  def set_serial_number
    @serial_number = params[:serial_number] || p_t_params["serial_number"]
    @serial_number = @serial_number.to_s.gsub(/\D/, "").sub(/(\d{4})(\d{4})/, '\1-\2')
  end

  # So we can validate either kind of certificate from one controller#action (i.e., phone number)
  def set_ivr_certificate
    @ivr_certificate = DailyDealCertificate.find_by_serial_number(@serial_number) || PurchasedGiftCertificate.find_by_serial_number(@serial_number)
  end
end
