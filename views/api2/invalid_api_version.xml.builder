xml.instruct! :xml, :version => '1.0'

xml.errors do
  xml.error do
    xml.text "Missing or invalid API-Version header: current version is 2.0.0"
  end
end
