require 'CyberSourceTransactionWS.rb'
require 'CyberSourceTransactionWSMappingRegistry.rb'
require 'soap/rpc/driver'
require 'wsse_authentication.rb'

module CyberSource::Soap

class ITransactionProcessor < ::SOAP::RPC::Driver
  DefaultEndpointUrl = "https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor"

  Methods = [
    [ "runTransaction",
      "runTransaction",
      [ [:in, "input", ["::SOAP::SOAPElement", "urn:schemas-cybersource-com:transaction-data-1.67", "requestMessage"]],
        [:out, "result", ["::SOAP::SOAPElement", "urn:schemas-cybersource-com:transaction-data-1.67", "replyMessage"]] ],
      { :request_style =>  :document, :request_use =>  :literal,
        :response_style => :document, :response_use => :literal,
        :faults => {} }
    ]
  ]

  def initialize(username, password, endpoint_url = nil)
    endpoint_url ||= DefaultEndpointUrl
    super(endpoint_url, nil)
    self.mapping_registry = CyberSourceTransactionWSMappingRegistry::EncodedRegistry
    self.literal_mapping_registry = CyberSourceTransactionWSMappingRegistry::LiteralRegistry
    self.headerhandler << WsseAuthHeader.new(username, password)
    init_methods
  end

private

  def init_methods
    Methods.each do |definitions|
      opt = definitions.last
      if opt[:request_style] == :document
        add_document_operation(*definitions)
      else
        add_rpc_operation(*definitions)
        qname = definitions[0]
        name = definitions[2]
        if qname.name != name and qname.name.capitalize == name.capitalize
          ::SOAP::Mapping.define_singleton_method(self, qname.name) do |*arg|
            __send__(name, *arg)
          end
        end
      end
    end
  end
end


end
