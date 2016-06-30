class BraintreeCredentials
  #
  # FIXME: Not thread safe!
  #
  # The Braintree API isn't intended to allow access to more than one Braintree account from
  # a single application. We work around that by swapping the configured account credentials
  # on demand. This is API abuse. Remove at the earliest opportunity.
  #
  def self.init(labels)
    $braintree_credentials = labels
  end
  
  def self.load(base_path)
    $braintree_credentials = {}.tap do |labels|
      Dir.foreach(base_path) do |name|
        if name !~ /^\./ && File.directory?(path = File.join(base_path, name))
          labels[name] = {}.tap do |creds|
            [:merchant_id, :public_key, :private_key].each do |attr|
              creds[attr] = File.read(File.join(path, attr.to_s)).strip
            end
          end
        end
      end
    end
    raise "Missing default configuration" unless $braintree_credentials.has_key?("default")
  end
  
  def self.find(*labels)
    l = labels.detect { |label| label.present? && $braintree_credentials.has_key?(label) } || "default"
    $braintree_credentials[l].each { |key, val| Braintree::Configuration.send "#{key}=", val }
  end
end
