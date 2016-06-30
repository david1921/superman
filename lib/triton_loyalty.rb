require 'net/http'
require 'digest/md5'

class TritonLoyalty
  def initialize(options)
    [:partner_code, :shared_secret].each do |key|
      raise "Configuration parameter #{key} must be present" unless options[key].present?
      instance_variable_set "@#{key}", options[key].strip
    end
    @http = Net::HTTP.new(api_uri.host, api_uri.port)
    @http.use_ssl = true
  end  

  def update_member(site_code, record, local_record_id = nil)
    post = Net::HTTP::Post.new("/Subscriptions.svc/UpdateMember", { "Content-Type" => "application/xml"})
    post.body = update_member_body(site_code, record, local_record_id)
    response = @http.request(post)
    begin
      body = Hash.from_xml(response.body)["SynchResponse"]
      body["MemberID"] if "SUCCESS" == body["Status"]
    rescue
      raise "UpdateMember failed: #{response.code} #{response.body}"
    end
  end
  
  def find_member(remote_record_id)
    remote_record_id = remote_record_id.strip
    token = api_token(remote_record_id, @shared_secret)
    get = Net::HTTP::Get.new("/Subscriptions.svc/FindMember/#{remote_record_id}/#{@partner_code}/#{token}")
    response = @http.request(get)
    begin
      Hash.from_xml(response.body)["member"]
    rescue
      raise "FindMember failed: #{response.code} #{response.body}"
    end
  end
  
  def get_site_subscriptions(site_code, remote_record_id)
    site_code, remote_record_id = site_code.strip, remote_record_id.strip
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    token = api_token(@partner_code, site_code, remote_record_id, timestamp, @shared_secret)
    
    path = "/Subscriptions.svc/GetSiteSubscriptions/#{@partner_code}/#{site_code}/#{timestamp}/#{token}?memberID=#{remote_record_id}"
    get = Net::HTTP::Get.new(path)
    response = @http.request(get)
    begin
      Hash.from_xml(response.body)["SubscriptionsContainer"]
    rescue
      raise "FindMember failed: #{response.code} #{response.body}"
    end
  end
  
  def update_member_subscriptions(site_code, remote_record_id, subscriptions)
    post = Net::HTTP::Post.new("/Subscriptions.svc/UpdateMemberSubscriptions", { "Content-Type" => "application/xml"})
    post.body = update_member_subscriptions_body(site_code, remote_record_id, subscriptions)
    response = @http.request(post)
    begin
      body = Hash.from_xml(response.body)["SynchResponse"]
      body["MemberID"] if "SUCCESS" == body["Status"]
    rescue
      raise "UpdateMemberSubscriptions failed: #{response.code} #{response.body}"
    end
  end
  
  private
  
  def api_uri
    @api_uri ||= URI.parse("https://api.enticent.com")
  end
  
  def api_token(*args)
    Digest::MD5.hexdigest(args.join).upcase.gsub!(/(..)(?=..)/, '\1-')
  end
  
  def update_member_body(site_code, record, local_record_id)
    local_record_id ||= record.id
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    password = "ZCwM1i1qC778aSj6"
    
    "".tap do |buffer|
      xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)
      xml.UpdateMember("xmlns" => "http://www.tritonloyalty.com/ISubscriptions", "xmlns:i" => "http://www.w3.org/2001/XMLSchema-instance") do
        xml.member("xmlns:a" => "http://www.tritonloyalty.com/datacontract/XinbanClientMemberEx",
                   "xmlns:i" => "http://www.w3.org/2001/XMLSchema-instance") do
          xml.a(:MemberID, record.remote_record_id || 0)
          xml.a(:ExMemberId, local_record_id)
          xml.a(:PartnerCode, @partner_code)
          xml.a(:ExSiteCode, site_code)
          xml.a(:UserName, record.email)
          xml.a(:Email, record.email)
          xml.a(:Password, password)
          xml.a(:TimeZoneCode)
          xml.a(:Confirmed, "true")
          xml.a(:Gender, %w{ M F }.include?(value = record.gender.to_s.upcase) ? value : "X")
          xml.a(:Zip, (value = record.zip_code).present? ? value[0,5] : "00000")
          xml.a(:HomePhone)
          xml.a(:WorkPhone)
          xml.a(:MobileNumber, record.mobile_number)
          xml.a(:FirstName, record.last_name.present? ? record.first_name : nil)
          xml.a(:LastName, record.first_name.present? ? record.last_name : nil)
          xml.a(:Address1)
          xml.a(:Address2)
          xml.a(:City)
          xml.a(:State)
          xml.a(:Country)
          xml.a(:EmailHTML, "true")
          xml.a(:NoEmail, "false")
          xml.a(:DOB, "1900-01-01")
          xml.a(:ShipToConfirmed)
          xml.a(:WorkAddress1)
          xml.a(:WorkAddress2)
          xml.a(:WorkCity)
          xml.a(:WorkState)
          xml.a(:WorkZip)
          xml.a(:ReferredBy)
          xml.a(:PasswordFlag)
        end
        xml.token(api_token(local_record_id, site_code, record.email, record.email, password, timestamp, @shared_secret))
        xml.timestamp(timestamp)
      end
    end
  end

  def update_member_subscriptions_body(site_code, remote_record_id, subscriptions)
    subscriptions = subscriptions.clone
    subscriptions.each do |key, val|
      subscriptions[key] = val ? "true" : "false"
    end
    subidlist = subscriptions.map { |key, val| "#{key}#{val}" }.join
    timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")
    
    "".tap do |buffer|
      xml = Builder::XmlMarkup.new(:target => buffer, :indent => 2)
      xml.UpdateMemberSubscriptions({
        "xmlns" => "http://www.tritonloyalty.com/ISubscriptions",
        "xmlns:i" => "http://www.w3.org/2001/XMLSchema-instance"
      }) do
        xml.partnerCode(@partner_code)
        xml.siteCode(site_code)
        xml.memberID(remote_record_id)
        xml.timeStamp(timestamp)
        xml.token(api_token(@partner_code, site_code, remote_record_id, timestamp, subidlist, @shared_secret))
        xml.Subscriptions("xmlns:b" => "http://www.tritonloyalty.com/datacontract/SubscriptionInfo") do
          subscriptions.each do |subscription_id, opt_in|
            xml.b(:SubscriptionInfo) do
              xml.b(:SubscriptionID, subscription_id)
              xml.b(:OptIn, opt_in)
            end
          end
        end
      end
    end
  end
end
