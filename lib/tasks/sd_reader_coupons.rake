require 'csv'

def tag_to_path_hash(dir)
  returning({}) do |hash|
    Dir.glob("#{dir}/*").map do |path|
      tag = File.basename(path, File.extname(path)).gsub(/\s/, '_').gsub(/[^a-z0-9_]/, '').gsub(/_+/, '_')
      hash[tag] = path
    end
  end
end

def zip_from_address(street, city, state)
  api_key = "ERez39zV34G6Mem1JrDTKG7ECHd_PXzY6qgCcxV9sl1Bhj.OZK4qz0CgJYFSn7.GuB1wvNWZPnRPz.f."
  url  = "http://local.yahooapis.com/MapsService/V1/geocode?appid=#{api_key}"
  url += "&location=#{CGI.escape([street, city, state].join(', '))}"
  response = Net::HTTP.get_response(URI.parse(url))

  raise RuntimeError unless "200" == response.code
  result = REXML::Document.new(response.body).elements["ResultSet/Result"]
  precision = result.attributes["precision"]
  raise RuntimeError unless "address" == precision || "street" == precision || precision =~ /^zip/

  zip = result.elements["Zip"].text
  zip = zip[0, 5] if zip
end

def normalize_address(tag, street, city, state, zip)
  if street && (!city || !state)
    raise "#{tag} has a street but missing city or state"
  end
  if street && city && state && !zip
    zip = zip_from_address(street, city, state)
  end
  if street && city && state && !zip
    if (zip = zip_from_address(street, "San Diego", state))
      city = "San Diego"
    else
      puts "Can't get ZIP for #{tag}: #{street}, #{city}, #{state}"
    end
  end
  [street, city, state, zip]
end

def normalize_categories(text)
  items = []
  text.split(',').each do |item|
    cats = item.split(':').map { |cat| cat.strip }
    if cats.size > 1
      items << "#{cats[0]}:#{cats[1]}"
    else
      items << "#{cats[0]}"
    end
  end
  items.join(",")
end

def record_from_row(row)
  c = Iconv.new('UTF-8', 'ISO-8859-1')
  row = row.map { |item| c.iconv(item) if item }
  
  advertiser_name = row[0].strip
  tag = advertiser_name.downcase.gsub(/\s/, '_').gsub(/[^a-z0-9_]/, '').gsub(/_+/, '_')
  street, city, state, zip = normalize_address(tag, row[5], row[6], row[7], row[8])

  return ({
    :tag => tag,
    :advertiser_name => advertiser_name,
    :offer_message => row[1],
    :value_proposition => row[2],
    :terms => row[3],
    :expiration => row[4],
    :street => street, :city => city, :state => state, :zip => zip,
    :phone => row[9],
    :website => row[10],
    :email => row[11],
    :categories => normalize_categories(row[12])
  })
end

def create_coupon(publisher, record, logos, photos, dryrun=true)
  tag = record[:tag]
  
  advertiser = Advertiser.new({
    :name => record[:advertiser_name],
    :landing_page => "http://example.com",
    :coupon_clipping_modes => ['email'],
    :publisher => publisher
  })
  unless dryrun
    advertiser.save!
  else
    puts "#{record[:tag]} advertiser INVALID: #{advertiser.errors.full_messages.join('. ')}" unless advertiser.valid?
    advertiser = Advertiser.first
  end
  
  offer = advertiser.offers.build({
    :message => record[:offer_message],
    :value_proposition => record[:value_proposition],
    :terms => record[:terms],
    :street => record[:street],
    :city => record[:city],
    :state => record[:state],
    :postal_code => record[:zip],
    :phone_number => record[:phone],
    :website => record[:website],
    :email => record[:email],
    :category_names => record[:categories]
  })
  if logos.has_key?(tag)
    offer.offer_image = File.new(logos[tag])
  else
    puts "#{tag}: no logo"
  end
  if photos.has_key?(tag)
    offer.photo = File.new(photos[tag])
  else
    puts "#{tag}: no photo"
  end
  unless dryrun
    offer.save!
  else
    puts "#{record[:tag]} offer INVALID: #{advertiser.errors.full_messages.join('. ')}" unless offer.valid?
  end
end

namespace :sd_reader_coupons do
  desc "Load coupons for SD Reader"
  task :load => :environment do
    basedir = File.expand_path(Rails.root + 'tmp/sd_reader')    
    puts "DRYRUN: no objects will be created" if (dryrun = (ENV['REALLY'] != 'yes'))
    
    logos = tag_to_path_hash(File.expand_path('images/coupon_logos', basedir))
    photos = tag_to_path_hash(File.expand_path('images/photos', basedir))
    publisher = Publisher.find_by_name("San Diego Weekly Reader")

    CSV::Reader.parse(File.new(File.expand_path('data.csv', basedir))) do |row|
      create_coupon publisher, record_from_row(row), logos, photos, dryrun
    end
  end
end
