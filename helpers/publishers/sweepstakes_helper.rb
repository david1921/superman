module Publishers::SweepstakesHelper
  
  def sweepstake_promo_email_checkbox_text(sweepstake)
    if sweepstake.promotional_opt_in_text.present?
      sweepstake.promotional_opt_in_text
    else
      "Check here to receive emails from #{sweepstake.publisher.name} about its products and future promotions."
    end
  end
  
end