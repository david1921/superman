# PaypalConfiguration
#
# Responsible for maintaining all the paypal configurations
# based on currency.
class PaypalConfiguration

	attr_accessor :ipn_url, :business, :cert_id

	# returns the Paypal configuration based on the 
	# given currency code.
	def self.for_currency_code(currency_code)
		return sandbox if use_sandbox?
		@@by_currency_code ||= load_configurations_for_currency_code
		raise ArgumentError, "invalid currency code" unless @@by_currency_code.key?(currency_code)
		@@by_currency_code[currency_code]
	end

	# returns the Paypal configuration for the Paypal
	# sandbox.
	def self.sandbox
		@@sandbox ||= PaypalConfiguration.new({
			:host => "www.sandbox.paypal.com",
			:business => "demo_merchant@analoganalytics.com"
		})
	end

	def self.use_sandbox?
		!Rails.env.production?
	end

	def self.production_ipn_url
		"https://www.paypal.com/cgi-bin/websrc"
	end

	def self.load_configurations_for_currency_code		
		config_path 					= "#{RAILS_ROOT}/config/paypal"
		certificate_filename 	= "analog_analytics_paypal_crt.pem"
		key_filename 					= "analog_analytics_paypal_key.pem"
		certificate_path 			= File.join(config_path, certificate_filename)
		key_path							= File.join(config_path, key_filename)
		ipn_url 							= production_ipn_url
		{
			"USD" => PaypalConfiguration.new({
				:ipn_url => ipn_url,
				:business => "kathleen.winer@analoganalytics.com",
				:cert_id => "LLQUFYP28FEPS",
				:certificate_path => certificate_path,
				:key_path => key_path
			}),
			"EUR" => PaypalConfiguration.new({
				:ipn_url => ipn_url,
				:business => "accounting@analoganalytics.com",
				:cert_id => "ZMY27VE5BHB7A",
				:certificate_path => certificate_path,
				:key_path => key_path
			})
		}
	end

	# creates a new PaypalConfiguration, settings can be:
	#
	# ipn_url - the paypal url to use, default is https://www.sandbox.paypal.com/cgi-bin/webscr
	# business - the paypal account, usually an email address
	# cert_id - the cert_id, you can get this from the Certificates link under Profile
	#
	# The follow settings are used in a production type environment that require certificates:
	#
	# certificate_path - the path to pem crt file
	# key_path - the path to the pem key file
	def initialize(settings={})
		settings  = settings.with_indifferent_access
		@ipn_url	= settings[:ipn_url] || "https://www.sandbox.paypal.com/cgi-bin/webscr"
		@business = settings[:business]
		@cert_id	= settings[:cert_id]

		@certificate_path 				= settings[:certificate_path]
		@key_path									= settings[:key_path]
		@paypal_certificate_path 	= settings[:paypal_certificate_path] || "#{Rails.root}/config/paypal/paypal_crt.pem"
	end

	def certificate
		@certificate ||= load_from_file_if_file_exists(@certificate_path)
	end

	def key
		@key ||= load_from_file_if_file_exists(@key_path)
	end

	def paypal_certificate
		@paypal_certificate ||= load_from_file_if_file_exists(@paypal_certificate_path)
	end

	def use_sandbox?
		self.class.use_sandbox?
	end

	def setup_paypal_notification!
		Paypal::Notification.paypal_cert = self.paypal_certificate if paypal_certificate.present?
	end

	private

	def load_from_file_if_file_exists(filepath)		
		File.read(filepath) if filepath.present? and File.exists?(filepath)
	end




end