xml.instruct!(:xml, :version => '1.0')

xml.callback_config do
  xml.url @config.callback_url
  xml.username @config.callback_username
  xml.password @config.callback_password
end