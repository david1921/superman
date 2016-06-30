class CallDetailRecord < ActiveRecord::Base
  belongs_to :voice_message
  before_validation :normalize_phone_numbers
  after_save :associate_voice_message

  def initialize(args={})
    args = HashWithIndifferentAccess.new(args) unless args.is_a?(HashWithIndifferentAccess)
    #
    # The ifbyphone CDR field containing the final destination number
    # after a Transfer or FindMe SurVo question looks like one of:
    #
    #   "Transfer | 6266745901"
    #   "Findme Transfer To | 6266745901"
    #
    if (matches = args.fetch(:center_phone_number, "").match(/transfer.*\s+\|\s+(\d+)/i))
      args[:center_phone_number] = matches[1]
    end
    #
    # Times seem to be reported by ifbyphone in the Eastern timezone.
    #
    if (value = args.fetch(:date_time, nil))
      args[:date_time] = ActiveSupport::TimeZone.new("Eastern Time (US & Canada)").parse(value) rescue Time.now
    end
    super(args)
  end
  
  def associate_voice_message
    if !voice_message && sid.present?
      self.voice_message = VoiceMessage.find_by_call_detail_record_sid(sid)
      if voice_message
        save
      end
    end
  end

  private

  def normalize_phone_numbers
    self.viewer_phone_number = viewer_phone_number.phone_digits
    self.center_phone_number = center_phone_number.phone_digits
  end
end
