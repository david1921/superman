require 'soap/header/simplehandler'

module CyberSource
  module Soap
    class WsseAuthHeader < SOAP::Header::SimpleHandler
      NAMESPACE = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'

      def initialize(username, password)
        super(XSD::QName.new(NAMESPACE, "Security"))
        @username = username
        @password = password
      end

      def on_simple_outbound
        { "UsernameToken" => { "Username" => @username, "Password" => @password }}
      end
    end
  end
end
