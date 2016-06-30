require 'CyberSourceTransactionWS.rb'
require 'soap/mapping'

module CyberSource; module Soap

module CyberSourceTransactionWSMappingRegistry
  EncodedRegistry = ::SOAP::Mapping::EncodedRegistry.new
  LiteralRegistry = ::SOAP::Mapping::LiteralRegistry.new
  NsTransactionData167 = "urn:schemas-cybersource-com:transaction-data-1.67"
  NsXMLSchema = "http://www.w3.org/2001/XMLSchema"

  EncodedRegistry.register(
    :class => CyberSource::Soap::Item,
    :schema_type => XSD::QName.new(NsTransactionData167, "Item"),
    :schema_element => [
      ["unitPrice", nil, [0, 1]],
      ["quantity", "SOAP::SOAPInteger", [0, 1]],
      ["productCode", "SOAP::SOAPString", [0, 1]],
      ["productName", "SOAP::SOAPString", [0, 1]],
      ["productSKU", "SOAP::SOAPString", [0, 1]],
      ["productRisk", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", nil, [0, 1]],
      ["cityOverrideAmount", nil, [0, 1]],
      ["cityOverrideRate", nil, [0, 1]],
      ["countyOverrideAmount", nil, [0, 1]],
      ["countyOverrideRate", nil, [0, 1]],
      ["districtOverrideAmount", nil, [0, 1]],
      ["districtOverrideRate", nil, [0, 1]],
      ["stateOverrideAmount", nil, [0, 1]],
      ["stateOverrideRate", nil, [0, 1]],
      ["countryOverrideAmount", nil, [0, 1]],
      ["countryOverrideRate", nil, [0, 1]],
      ["orderAcceptanceCity", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCounty", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCountry", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceState", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptancePostalCode", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCity", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCounty", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCountry", "SOAP::SOAPString", [0, 1]],
      ["orderOriginState", "SOAP::SOAPString", [0, 1]],
      ["orderOriginPostalCode", "SOAP::SOAPString", [0, 1]],
      ["shipFromCity", "SOAP::SOAPString", [0, 1]],
      ["shipFromCounty", "SOAP::SOAPString", [0, 1]],
      ["shipFromCountry", "SOAP::SOAPString", [0, 1]],
      ["shipFromState", "SOAP::SOAPString", [0, 1]],
      ["shipFromPostalCode", "SOAP::SOAPString", [0, 1]],
      ["export", "SOAP::SOAPString", [0, 1]],
      ["noExport", "SOAP::SOAPString", [0, 1]],
      ["nationalTax", nil, [0, 1]],
      ["vatRate", nil, [0, 1]],
      ["sellerRegistration", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration0", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration1", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration2", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration3", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration4", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration5", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration6", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration7", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration8", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration9", "SOAP::SOAPString", [0, 1]],
      ["buyerRegistration", "SOAP::SOAPString", [0, 1]],
      ["middlemanRegistration", "SOAP::SOAPString", [0, 1]],
      ["pointOfTitleTransfer", "SOAP::SOAPString", [0, 1]],
      ["giftCategory", nil, [0, 1]],
      ["timeCategory", "SOAP::SOAPString", [0, 1]],
      ["hostHedge", "SOAP::SOAPString", [0, 1]],
      ["timeHedge", "SOAP::SOAPString", [0, 1]],
      ["velocityHedge", "SOAP::SOAPString", [0, 1]],
      ["nonsensicalHedge", "SOAP::SOAPString", [0, 1]],
      ["phoneHedge", "SOAP::SOAPString", [0, 1]],
      ["obscenitiesHedge", "SOAP::SOAPString", [0, 1]],
      ["unitOfMeasure", "SOAP::SOAPString", [0, 1]],
      ["taxRate", nil, [0, 1]],
      ["totalAmount", nil, [0, 1]],
      ["discountAmount", nil, [0, 1]],
      ["discountRate", nil, [0, 1]],
      ["commodityCode", "SOAP::SOAPString", [0, 1]],
      ["grossNetIndicator", "SOAP::SOAPString", [0, 1]],
      ["taxTypeApplied", "SOAP::SOAPString", [0, 1]],
      ["discountIndicator", "SOAP::SOAPString", [0, 1]],
      ["alternateTaxID", "SOAP::SOAPString", [0, 1]],
      ["alternateTaxAmount", nil, [0, 1]],
      ["alternateTaxTypeApplied", "SOAP::SOAPString", [0, 1]],
      ["alternateTaxRate", nil, [0, 1]],
      ["alternateTaxType", "SOAP::SOAPString", [0, 1]],
      ["localTax", nil, [0, 1]],
      ["zeroCostToCustomerIndicator", "SOAP::SOAPString", [0, 1]],
      ["passengerFirstName", "SOAP::SOAPString", [0, 1]],
      ["passengerLastName", "SOAP::SOAPString", [0, 1]],
      ["passengerID", "SOAP::SOAPString", [0, 1]],
      ["passengerStatus", "SOAP::SOAPString", [0, 1]],
      ["passengerType", "SOAP::SOAPString", [0, 1]],
      ["passengerEmail", "SOAP::SOAPString", [0, 1]],
      ["passengerPhone", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCAuthService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthService"),
    :schema_element => [
      ["cavv", "SOAP::SOAPString", [0, 1]],
      ["cavvAlgorithm", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["eciRaw", "SOAP::SOAPString", [0, 1]],
      ["xid", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["avsLevel", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteID", "SOAP::SOAPString", [0, 1]],
      ["returnAuthRecord", nil, [0, 1]],
      ["authType", "SOAP::SOAPString", [0, 1]],
      ["verbalAuthCode", "SOAP::SOAPString", [0, 1]],
      ["billPayment", nil, [0, 1]],
      ["authenticationXID", "SOAP::SOAPString", [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["industryDatatype", "SOAP::SOAPString", [0, 1]],
      ["traceNumber", "SOAP::SOAPString", [0, 1]],
      ["checksumKey", "SOAP::SOAPString", [0, 1]],
      ["aggregatorID", "SOAP::SOAPString", [0, 1]],
      ["splitTenderIndicator", "SOAP::SOAPString", [0, 1]],
      ["veresEnrolled", "SOAP::SOAPString", [0, 1]],
      ["paresStatus", "SOAP::SOAPString", [0, 1]],
      ["partialAuthIndicator", nil, [0, 1]],
      ["captureDate", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCCaptureService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCaptureService"),
    :schema_element => [
      ["authType", "SOAP::SOAPString", [0, 1]],
      ["verbalAuthCode", "SOAP::SOAPString", [0, 1]],
      ["authRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["purchasingLevel", "SOAP::SOAPString", [0, 1]],
      ["industryDatatype", "SOAP::SOAPString", [0, 1]],
      ["authRequestToken", "SOAP::SOAPString", [0, 1]],
      ["merchantReceiptNumber", "SOAP::SOAPString", [0, 1]],
      ["posData", "SOAP::SOAPString", [0, 1]],
      ["transactionID", "SOAP::SOAPString", [0, 1]],
      ["checksumKey", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCCreditService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCreditService"),
    :schema_element => [
      ["captureRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["purchasingLevel", "SOAP::SOAPString", [0, 1]],
      ["industryDatatype", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["billPayment", nil, [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["occurrenceNumber", "SOAP::SOAPString", [0, 1]],
      ["authCode", "SOAP::SOAPString", [0, 1]],
      ["captureRequestToken", "SOAP::SOAPString", [0, 1]],
      ["merchantReceiptNumber", "SOAP::SOAPString", [0, 1]],
      ["checksumKey", "SOAP::SOAPString", [0, 1]],
      ["aggregatorID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCAuthReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthReversalService"),
    :schema_element => [
      ["authRequestID", "SOAP::SOAPString", [0, 1]],
      ["authRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCAutoAuthReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAutoAuthReversalService"),
    :schema_element => [
      ["authPaymentServiceData", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["authAmount", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["authRequestID", "SOAP::SOAPString", [0, 1]],
      ["billAmount", "SOAP::SOAPString", [0, 1]],
      ["authCode", "SOAP::SOAPString", [0, 1]],
      ["authType", "SOAP::SOAPString", [0, 1]],
      ["billPayment", nil, [0, 1]],
      ["dateAdded", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCDCCService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCDCCService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ECDebitService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECDebitService"),
    :schema_element => [
      ["paymentMode", "SOAP::SOAPInteger", [0, 1]],
      ["referenceNumber", "SOAP::SOAPString", [0, 1]],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["transactionToken", "SOAP::SOAPString", [0, 1]],
      ["verificationLevel", "SOAP::SOAPInteger", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["debitRequestID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ECCreditService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECCreditService"),
    :schema_element => [
      ["referenceNumber", "SOAP::SOAPString", [0, 1]],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["transactionToken", "SOAP::SOAPString", [0, 1]],
      ["debitRequestID", "SOAP::SOAPString", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["debitRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ECAuthenticateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECAuthenticateService"),
    :schema_element => [
      ["referenceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayerAuthEnrollService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthEnrollService"),
    :schema_element => [
      ["httpAccept", "SOAP::SOAPString", [0, 1]],
      ["httpUserAgent", "SOAP::SOAPString", [0, 1]],
      ["merchantName", "SOAP::SOAPString", [0, 1]],
      ["merchantURL", "SOAP::SOAPString", [0, 1]],
      ["purchaseDescription", "SOAP::SOAPString", [0, 1]],
      ["purchaseTime", nil, [0, 1]],
      ["countryCode", "SOAP::SOAPString", [0, 1]],
      ["acquirerBin", "SOAP::SOAPString", [0, 1]],
      ["loginID", "SOAP::SOAPString", [0, 1]],
      ["password", "SOAP::SOAPString", [0, 1]],
      ["merchantID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayerAuthValidateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthValidateService"),
    :schema_element => [
      ["signedPARes", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::TaxService,
    :schema_type => XSD::QName.new(NsTransactionData167, "TaxService"),
    :schema_element => [
      ["nexus", "SOAP::SOAPString", [0, 1]],
      ["noNexus", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCity", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCounty", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCountry", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceState", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptancePostalCode", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCity", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCounty", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCountry", "SOAP::SOAPString", [0, 1]],
      ["orderOriginState", "SOAP::SOAPString", [0, 1]],
      ["orderOriginPostalCode", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration0", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration1", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration2", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration3", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration4", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration5", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration6", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration7", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration8", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration9", "SOAP::SOAPString", [0, 1]],
      ["buyerRegistration", "SOAP::SOAPString", [0, 1]],
      ["middlemanRegistration", "SOAP::SOAPString", [0, 1]],
      ["pointOfTitleTransfer", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::AFSService,
    :schema_type => XSD::QName.new(NsTransactionData167, "AFSService"),
    :schema_element => [
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["cvCode", "SOAP::SOAPString", [0, 1]],
      ["disableAVSScoring", nil, [0, 1]],
      ["customRiskModel", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DAVService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DAVService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ExportService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ExportService"),
    :schema_element => [
      ["addressOperator", "SOAP::SOAPString", [0, 1]],
      ["addressWeight", "SOAP::SOAPString", [0, 1]],
      ["companyWeight", "SOAP::SOAPString", [0, 1]],
      ["nameWeight", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FXRatesService,
    :schema_type => XSD::QName.new(NsTransactionData167, "FXRatesService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankTransferService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankTransferRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRefundService"),
    :schema_element => [
      ["bankTransferRequestID", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRealTimeRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRealTimeReconciliationID", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRequestToken", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRealTimeRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankTransferRealTimeService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRealTimeService"),
    :schema_element => [
      ["bankTransferRealTimeType", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitMandateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitMandateService"),
    :schema_element => [
      ["mandateDescriptor", "SOAP::SOAPString", [0, 1]],
      ["firstDebitDate", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitService"),
    :schema_element => [
      ["dateCollect", "SOAP::SOAPString", [0, 1]],
      ["directDebitText", "SOAP::SOAPString", [0, 1]],
      ["authorizationID", "SOAP::SOAPString", [0, 1]],
      ["transactionType", "SOAP::SOAPString", [0, 1]],
      ["directDebitType", "SOAP::SOAPString", [0, 1]],
      ["validateRequestID", "SOAP::SOAPString", [0, 1]],
      ["recurringType", "SOAP::SOAPString", [0, 1]],
      ["mandateID", "SOAP::SOAPString", [0, 1]],
      ["validateRequestToken", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["mandateAuthenticationDate", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitRefundService"),
    :schema_element => [
      ["directDebitRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["directDebitRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitValidateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitValidateService"),
    :schema_element => [
      ["directDebitValidateText", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionCreateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionCreateService"),
    :schema_element => [
      ["paymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["paymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["disableAutoAuth", nil, [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionUpdateService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionEventUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionEventUpdateService"),
    :schema_element => [
      ["action", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionRetrieveService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionRetrieveService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionDeleteService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionDeleteService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPaymentService"),
    :schema_element => [
      ["cancelURL", "SOAP::SOAPString", [0, 1]],
      ["successURL", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalCreditService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreditService"),
    :schema_element => [
      ["payPalPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["payPalPaymentRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcSetService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcSetService"),
    :schema_element => [
      ["paypalReturn", "SOAP::SOAPString", [0, 1]],
      ["paypalCancelReturn", "SOAP::SOAPString", [0, 1]],
      ["paypalMaxamt", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalReqconfirmshipping", "SOAP::SOAPString", [0, 1]],
      ["paypalNoshipping", "SOAP::SOAPString", [0, 1]],
      ["paypalAddressOverride", "SOAP::SOAPString", [0, 1]],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalLc", "SOAP::SOAPString", [0, 1]],
      ["paypalPagestyle", "SOAP::SOAPString", [0, 1]],
      ["paypalHdrimg", "SOAP::SOAPString", [0, 1]],
      ["paypalHdrbordercolor", "SOAP::SOAPString", [0, 1]],
      ["paypalHdrbackcolor", "SOAP::SOAPString", [0, 1]],
      ["paypalPayflowcolor", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]],
      ["promoCode0", "SOAP::SOAPString", [0, 1]],
      ["requestBillingAddress", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingType", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementCustom", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcGetDetailsService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcGetDetailsService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcDoPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcDoPaymentService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalPayerId", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]],
      ["promoCode0", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalDoCaptureService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoCaptureService"),
    :schema_element => [
      ["paypalAuthorizationId", "SOAP::SOAPString", [0, 1]],
      ["completeType", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestToken", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalAuthReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthReversalService"),
    :schema_element => [
      ["paypalAuthorizationId", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalRefundService"),
    :schema_element => [
      ["paypalDoCaptureRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalDoCaptureRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalCaptureId", "SOAP::SOAPString", [0, 1]],
      ["paypalNote", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcOrderSetupService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcOrderSetupService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalPayerId", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]],
      ["promoCode0", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalAuthorizationService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthorizationService"),
    :schema_element => [
      ["paypalOrderId", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalDoRefTransactionRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalDoRefTransactionRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalUpdateAgreementService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalUpdateAgreementService"),
    :schema_element => [
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementCustom", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalCreateAgreementService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreateAgreementService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalDoRefTransactionService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoRefTransactionService"),
    :schema_element => [
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalReqconfirmshipping", "SOAP::SOAPString", [0, 1]],
      ["paypalReturnFmfDetails", "SOAP::SOAPString", [0, 1]],
      ["paypalSoftDescriptor", "SOAP::SOAPString", [0, 1]],
      ["paypalShippingdiscount", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]],
      ["paypalEcNotifyUrl", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::VoidService,
    :schema_type => XSD::QName.new(NsTransactionData167, "VoidService"),
    :schema_element => [
      ["voidRequestID", "SOAP::SOAPString", [0, 1]],
      ["voidRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PinlessDebitService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitService"),
    :schema_element => [
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PinlessDebitValidateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitValidateService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PinlessDebitReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitReversalService"),
    :schema_element => [
      ["pinlessDebitRequestID", "SOAP::SOAPString", [0, 1]],
      ["pinlessDebitRequestToken", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalButtonCreateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalButtonCreateService"),
    :schema_element => [
      ["buttonType", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedPaymentService"),
    :schema_element => [
      ["mpID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedUpdateService"),
    :schema_element => [
      ["mpID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ChinaPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaPaymentService"),
    :schema_element => [
      ["paymentMode", "SOAP::SOAPString", [0, 1]],
      ["returnURL", "SOAP::SOAPString", [0, 1]],
      ["pickUpAddress", "SOAP::SOAPString", [0, 1]],
      ["pickUpPhoneNumber", "SOAP::SOAPString", [0, 1]],
      ["pickUpPostalCode", "SOAP::SOAPString", [0, 1]],
      ["pickUpName", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ChinaRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaRefundService"),
    :schema_element => [
      ["chinaPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["chinaPaymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["refundReason", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BoletoPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BoletoPaymentService"),
    :schema_element => [
      ["instruction", "SOAP::SOAPString", [0, 1]],
      ["expirationDate", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Address,
    :schema_type => XSD::QName.new(NsTransactionData167, "Address"),
    :schema_element => [
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RiskUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "RiskUpdateService"),
    :schema_element => [
      ["actionCode", "SOAP::SOAPString", [0, 1]],
      ["recordID", "SOAP::SOAPString", [0, 1]],
      ["recordName", "SOAP::SOAPString", [0, 1]],
      ["negativeAddress", "CyberSource::Soap::Address", [0, 1]],
      ["markingReason", "SOAP::SOAPString", [0, 1]],
      ["markingNotes", "SOAP::SOAPString", [0, 1]],
      ["markingRequestID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FraudUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "FraudUpdateService"),
    :schema_element => [
      ["actionCode", "SOAP::SOAPString", [0, 1]],
      ["markedData", "SOAP::SOAPString", [0, 1]],
      ["markingReason", "SOAP::SOAPString", [0, 1]],
      ["markingNotes", "SOAP::SOAPString", [0, 1]],
      ["markingRequestID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::InvoiceHeader,
    :schema_type => XSD::QName.new(NsTransactionData167, "InvoiceHeader"),
    :schema_element => [
      ["merchantDescriptor", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorContact", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorAlternate", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorStreet", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorCity", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorState", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorPostalCode", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorCountry", "SOAP::SOAPString", [0, 1]],
      ["isGift", nil, [0, 1]],
      ["returnsAccepted", nil, [0, 1]],
      ["tenderType", "SOAP::SOAPString", [0, 1]],
      ["merchantVATRegistrationNumber", "SOAP::SOAPString", [0, 1]],
      ["purchaserOrderDate", "SOAP::SOAPString", [0, 1]],
      ["purchaserVATRegistrationNumber", "SOAP::SOAPString", [0, 1]],
      ["vatInvoiceReferenceNumber", "SOAP::SOAPString", [0, 1]],
      ["summaryCommodityCode", "SOAP::SOAPString", [0, 1]],
      ["supplierOrderReference", "SOAP::SOAPString", [0, 1]],
      ["userPO", "SOAP::SOAPString", [0, 1]],
      ["costCenter", "SOAP::SOAPString", [0, 1]],
      ["purchaserCode", "SOAP::SOAPString", [0, 1]],
      ["taxable", nil, [0, 1]],
      ["amexDataTAA1", "SOAP::SOAPString", [0, 1]],
      ["amexDataTAA2", "SOAP::SOAPString", [0, 1]],
      ["amexDataTAA3", "SOAP::SOAPString", [0, 1]],
      ["amexDataTAA4", "SOAP::SOAPString", [0, 1]],
      ["invoiceDate", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BusinessRules,
    :schema_type => XSD::QName.new(NsTransactionData167, "BusinessRules"),
    :schema_element => [
      ["ignoreAVSResult", nil, [0, 1]],
      ["ignoreCVResult", nil, [0, 1]],
      ["ignoreDAVResult", nil, [0, 1]],
      ["ignoreExportResult", nil, [0, 1]],
      ["ignoreValidateResult", nil, [0, 1]],
      ["declineAVSFlags", "SOAP::SOAPString", [0, 1]],
      ["scoreThreshold", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BillTo,
    :schema_type => XSD::QName.new(NsTransactionData167, "BillTo"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["middleName", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["suffix", "SOAP::SOAPString", [0, 1]],
      ["buildingNumber", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["street3", "SOAP::SOAPString", [0, 1]],
      ["street4", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["company", "SOAP::SOAPString", [0, 1]],
      ["companyTaxID", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]],
      ["ipAddress", "SOAP::SOAPString", [0, 1]],
      ["customerPassword", "SOAP::SOAPString", [0, 1]],
      ["ipNetworkAddress", "SOAP::SOAPString", [0, 1]],
      ["hostname", "SOAP::SOAPString", [0, 1]],
      ["domainName", "SOAP::SOAPString", [0, 1]],
      ["dateOfBirth", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseNumber", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseState", "SOAP::SOAPString", [0, 1]],
      ["ssn", "SOAP::SOAPString", [0, 1]],
      ["customerID", "SOAP::SOAPString", [0, 1]],
      ["httpBrowserType", "SOAP::SOAPString", [0, 1]],
      ["httpBrowserEmail", "SOAP::SOAPString", [0, 1]],
      ["httpBrowserCookiesAccepted", nil, [0, 1]],
      ["nif", "SOAP::SOAPString", [0, 1]],
      ["personalID", "SOAP::SOAPString", [0, 1]],
      ["language", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ShipTo,
    :schema_type => XSD::QName.new(NsTransactionData167, "ShipTo"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["middleName", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["suffix", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["street3", "SOAP::SOAPString", [0, 1]],
      ["street4", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["company", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]],
      ["shippingMethod", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ShipFrom,
    :schema_type => XSD::QName.new(NsTransactionData167, "ShipFrom"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["middleName", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["suffix", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["street3", "SOAP::SOAPString", [0, 1]],
      ["street4", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["company", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Card,
    :schema_type => XSD::QName.new(NsTransactionData167, "Card"),
    :schema_element => [
      ["fullName", "SOAP::SOAPString", [0, 1]],
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["expirationMonth", "SOAP::SOAPInteger", [0, 1]],
      ["expirationYear", "SOAP::SOAPInteger", [0, 1]],
      ["cvIndicator", "SOAP::SOAPString", [0, 1]],
      ["cvNumber", "SOAP::SOAPString", [0, 1]],
      ["cardType", "SOAP::SOAPString", [0, 1]],
      ["issueNumber", "SOAP::SOAPString", [0, 1]],
      ["startMonth", "SOAP::SOAPInteger", [0, 1]],
      ["startYear", "SOAP::SOAPInteger", [0, 1]],
      ["pin", "SOAP::SOAPString", [0, 1]],
      ["accountEncoderID", "SOAP::SOAPString", [0, 1]],
      ["bin", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Check,
    :schema_type => XSD::QName.new(NsTransactionData167, "Check"),
    :schema_element => [
      ["fullName", "SOAP::SOAPString", [0, 1]],
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["accountType", "SOAP::SOAPString", [0, 1]],
      ["bankTransitNumber", "SOAP::SOAPString", [0, 1]],
      ["checkNumber", "SOAP::SOAPString", [0, 1]],
      ["secCode", "SOAP::SOAPString", [0, 1]],
      ["accountEncoderID", "SOAP::SOAPString", [0, 1]],
      ["authenticateID", "SOAP::SOAPString", [0, 1]],
      ["paymentInfo", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BML,
    :schema_type => XSD::QName.new(NsTransactionData167, "BML"),
    :schema_element => [
      ["customerBillingAddressChange", nil, [0, 1]],
      ["customerEmailChange", nil, [0, 1]],
      ["customerHasCheckingAccount", nil, [0, 1]],
      ["customerHasSavingsAccount", nil, [0, 1]],
      ["customerPasswordChange", nil, [0, 1]],
      ["customerPhoneChange", nil, [0, 1]],
      ["customerRegistrationDate", "SOAP::SOAPString", [0, 1]],
      ["customerTypeFlag", "SOAP::SOAPString", [0, 1]],
      ["grossHouseholdIncome", nil, [0, 1]],
      ["householdIncomeCurrency", "SOAP::SOAPString", [0, 1]],
      ["itemCategory", "SOAP::SOAPString", [0, 1]],
      ["merchantPromotionCode", "SOAP::SOAPString", [0, 1]],
      ["preapprovalNumber", "SOAP::SOAPString", [0, 1]],
      ["productDeliveryTypeIndicator", "SOAP::SOAPString", [0, 1]],
      ["residenceStatus", "SOAP::SOAPString", [0, 1]],
      ["tcVersion", "SOAP::SOAPString", [0, 1]],
      ["yearsAtCurrentResidence", "SOAP::SOAPInteger", [0, 1]],
      ["yearsWithCurrentEmployer", "SOAP::SOAPInteger", [0, 1]],
      ["employerStreet1", "SOAP::SOAPString", [0, 1]],
      ["employerStreet2", "SOAP::SOAPString", [0, 1]],
      ["employerCity", "SOAP::SOAPString", [0, 1]],
      ["employerCompanyName", "SOAP::SOAPString", [0, 1]],
      ["employerCountry", "SOAP::SOAPString", [0, 1]],
      ["employerPhoneNumber", "SOAP::SOAPString", [0, 1]],
      ["employerPhoneType", "SOAP::SOAPString", [0, 1]],
      ["employerState", "SOAP::SOAPString", [0, 1]],
      ["employerPostalCode", "SOAP::SOAPString", [0, 1]],
      ["shipToPhoneType", "SOAP::SOAPString", [0, 1]],
      ["billToPhoneType", "SOAP::SOAPString", [0, 1]],
      ["methodOfPayment", "SOAP::SOAPString", [0, 1]],
      ["productType", "SOAP::SOAPString", [0, 1]],
      ["customerAuthenticatedByMerchant", "SOAP::SOAPString", [0, 1]],
      ["backOfficeIndicator", "SOAP::SOAPString", [0, 1]],
      ["shipToEqualsBillToNameIndicator", "SOAP::SOAPString", [0, 1]],
      ["shipToEqualsBillToAddressIndicator", "SOAP::SOAPString", [0, 1]],
      ["alternateIPAddress", "SOAP::SOAPString", [0, 1]],
      ["businessLegalName", "SOAP::SOAPString", [0, 1]],
      ["dbaName", "SOAP::SOAPString", [0, 1]],
      ["businessAddress1", "SOAP::SOAPString", [0, 1]],
      ["businessAddress2", "SOAP::SOAPString", [0, 1]],
      ["businessCity", "SOAP::SOAPString", [0, 1]],
      ["businessState", "SOAP::SOAPString", [0, 1]],
      ["businessPostalCode", "SOAP::SOAPString", [0, 1]],
      ["businessCountry", "SOAP::SOAPString", [0, 1]],
      ["businessMainPhone", "SOAP::SOAPString", [0, 1]],
      ["userID", "SOAP::SOAPString", [0, 1]],
      ["pin", "SOAP::SOAPString", [0, 1]],
      ["adminLastName", "SOAP::SOAPString", [0, 1]],
      ["adminFirstName", "SOAP::SOAPString", [0, 1]],
      ["adminPhone", "SOAP::SOAPString", [0, 1]],
      ["adminFax", "SOAP::SOAPString", [0, 1]],
      ["adminEmailAddress", "SOAP::SOAPString", [0, 1]],
      ["adminTitle", "SOAP::SOAPString", [0, 1]],
      ["supervisorLastName", "SOAP::SOAPString", [0, 1]],
      ["supervisorFirstName", "SOAP::SOAPString", [0, 1]],
      ["supervisorEmailAddress", "SOAP::SOAPString", [0, 1]],
      ["businessDAndBNumber", "SOAP::SOAPString", [0, 1]],
      ["businessTaxID", "SOAP::SOAPString", [0, 1]],
      ["businessNAICSCode", "SOAP::SOAPString", [0, 1]],
      ["businessType", "SOAP::SOAPString", [0, 1]],
      ["businessYearsInBusiness", "SOAP::SOAPString", [0, 1]],
      ["businessNumberOfEmployees", "SOAP::SOAPString", [0, 1]],
      ["businessPONumber", "SOAP::SOAPString", [0, 1]],
      ["businessLoanType", "SOAP::SOAPString", [0, 1]],
      ["businessApplicationID", "SOAP::SOAPString", [0, 1]],
      ["businessProductCode", "SOAP::SOAPString", [0, 1]],
      ["pgLastName", "SOAP::SOAPString", [0, 1]],
      ["pgFirstName", "SOAP::SOAPString", [0, 1]],
      ["pgSSN", "SOAP::SOAPString", [0, 1]],
      ["pgDateOfBirth", "SOAP::SOAPString", [0, 1]],
      ["pgAnnualIncome", "SOAP::SOAPString", [0, 1]],
      ["pgIncomeCurrencyType", "SOAP::SOAPString", [0, 1]],
      ["pgResidenceStatus", "SOAP::SOAPString", [0, 1]],
      ["pgCheckingAccountIndicator", "SOAP::SOAPString", [0, 1]],
      ["pgSavingsAccountIndicator", "SOAP::SOAPString", [0, 1]],
      ["pgYearsAtEmployer", "SOAP::SOAPString", [0, 1]],
      ["pgYearsAtResidence", "SOAP::SOAPString", [0, 1]],
      ["pgHomeAddress1", "SOAP::SOAPString", [0, 1]],
      ["pgHomeAddress2", "SOAP::SOAPString", [0, 1]],
      ["pgHomeCity", "SOAP::SOAPString", [0, 1]],
      ["pgHomeState", "SOAP::SOAPString", [0, 1]],
      ["pgHomePostalCode", "SOAP::SOAPString", [0, 1]],
      ["pgHomeCountry", "SOAP::SOAPString", [0, 1]],
      ["pgEmailAddress", "SOAP::SOAPString", [0, 1]],
      ["pgHomePhone", "SOAP::SOAPString", [0, 1]],
      ["pgTitle", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::OtherTax,
    :schema_type => XSD::QName.new(NsTransactionData167, "OtherTax"),
    :schema_element => [
      ["vatTaxAmount", nil, [0, 1]],
      ["vatTaxRate", nil, [0, 1]],
      ["alternateTaxAmount", nil, [0, 1]],
      ["alternateTaxIndicator", nil, [0, 1]],
      ["alternateTaxID", "SOAP::SOAPString", [0, 1]],
      ["localTaxAmount", nil, [0, 1]],
      ["localTaxIndicator", "SOAP::SOAPInteger", [0, 1]],
      ["nationalTaxAmount", nil, [0, 1]],
      ["nationalTaxIndicator", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PurchaseTotals,
    :schema_type => XSD::QName.new(NsTransactionData167, "PurchaseTotals"),
    :schema_element => [
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["discountAmount", nil, [0, 1]],
      ["taxAmount", nil, [0, 1]],
      ["dutyAmount", nil, [0, 1]],
      ["grandTotalAmount", nil, [0, 1]],
      ["freightAmount", nil, [0, 1]],
      ["foreignAmount", nil, [0, 1]],
      ["foreignCurrency", "SOAP::SOAPString", [0, 1]],
      ["exchangeRate", nil, [0, 1]],
      ["exchangeRateTimeStamp", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FundingTotals,
    :schema_type => XSD::QName.new(NsTransactionData167, "FundingTotals"),
    :schema_element => [
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["grandTotalAmount", nil, [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::GECC,
    :schema_type => XSD::QName.new(NsTransactionData167, "GECC"),
    :schema_element => [
      ["saleType", "SOAP::SOAPString", [0, 1]],
      ["planNumber", "SOAP::SOAPString", [0, 1]],
      ["sequenceNumber", "SOAP::SOAPString", [0, 1]],
      ["promotionEndDate", "SOAP::SOAPString", [0, 1]],
      ["promotionPlan", "SOAP::SOAPString", [0, 1]],
      ["line", "SOAP::SOAPString[]", [0, 7]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::UCAF,
    :schema_type => XSD::QName.new(NsTransactionData167, "UCAF"),
    :schema_element => [
      ["authenticationData", "SOAP::SOAPString", [0, 1]],
      ["collectionIndicator", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FundTransfer,
    :schema_type => XSD::QName.new(NsTransactionData167, "FundTransfer"),
    :schema_element => [
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["accountName", "SOAP::SOAPString", [0, 1]],
      ["bankCheckDigit", "SOAP::SOAPString", [0, 1]],
      ["iban", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankInfo,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankInfo"),
    :schema_element => [
      ["bankCode", "SOAP::SOAPString", [0, 1]],
      ["name", "SOAP::SOAPString", [0, 1]],
      ["address", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["branchCode", "SOAP::SOAPString", [0, 1]],
      ["swiftCode", "SOAP::SOAPString", [0, 1]],
      ["sortCode", "SOAP::SOAPString", [0, 1]],
      ["issuerID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RecurringSubscriptionInfo,
    :schema_type => XSD::QName.new(NsTransactionData167, "RecurringSubscriptionInfo"),
    :schema_element => [
      ["subscriptionID", "SOAP::SOAPString", [0, 1]],
      ["status", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]],
      ["numberOfPayments", "SOAP::SOAPInteger", [0, 1]],
      ["numberOfPaymentsToAdd", "SOAP::SOAPInteger", [0, 1]],
      ["automaticRenew", nil, [0, 1]],
      ["frequency", "SOAP::SOAPString", [0, 1]],
      ["startDate", "SOAP::SOAPString", [0, 1]],
      ["endDate", "SOAP::SOAPString", [0, 1]],
      ["approvalRequired", nil, [0, 1]],
      ["event", "CyberSource::Soap::PaySubscriptionEvent", [0, 1]],
      ["billPayment", nil, [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionEvent,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionEvent"),
    :schema_element => [
      ["amount", nil, [0, 1]],
      ["approvedBy", "SOAP::SOAPString", [0, 1]],
      ["number", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Subscription,
    :schema_type => XSD::QName.new(NsTransactionData167, "Subscription"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["paymentMethod", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DecisionManager,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionManager"),
    :schema_element => [
      ["enabled", nil, [0, 1]],
      ["profile", "SOAP::SOAPString", [0, 1]],
      ["travelData", "CyberSource::Soap::DecisionManagerTravelData", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DecisionManagerTravelData,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionManagerTravelData"),
    :schema_element => [
      ["leg", "CyberSource::Soap::DecisionManagerTravelLeg[]", [0, nil]],
      ["departureDateTime", nil, [0, 1]],
      ["completeRoute", "SOAP::SOAPString", [0, 1]],
      ["journeyType", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DecisionManagerTravelLeg,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionManagerTravelLeg"),
    :schema_element => [
      ["origin", "SOAP::SOAPString", [0, 1]],
      ["destination", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Batch,
    :schema_type => XSD::QName.new(NsTransactionData167, "Batch"),
    :schema_element => [
      ["batchID", "SOAP::SOAPString", [0, 1]],
      ["recordID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPal,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPal"),
    :schema_element => [
      ["any", [nil, XSD::QName.new(NsXMLSchema, "anyType")]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::JPO,
    :schema_type => XSD::QName.new(NsTransactionData167, "JPO"),
    :schema_element => [
      ["paymentMethod", "SOAP::SOAPInteger", [0, 1]],
      ["bonusAmount", nil, [0, 1]],
      ["bonuses", "SOAP::SOAPInteger", [0, 1]],
      ["installments", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RequestMessage,
    :schema_type => XSD::QName.new(NsTransactionData167, "RequestMessage"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString", [0, 1]],
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["debtIndicator", nil, [0, 1]],
      ["clientLibrary", "SOAP::SOAPString", [0, 1]],
      ["clientLibraryVersion", "SOAP::SOAPString", [0, 1]],
      ["clientEnvironment", "SOAP::SOAPString", [0, 1]],
      ["clientSecurityLibraryVersion", "SOAP::SOAPString", [0, 1]],
      ["clientApplication", "SOAP::SOAPString", [0, 1]],
      ["clientApplicationVersion", "SOAP::SOAPString", [0, 1]],
      ["clientApplicationUser", "SOAP::SOAPString", [0, 1]],
      ["routingCode", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["returnURL", "SOAP::SOAPString", [0, 1]],
      ["invoiceHeader", "CyberSource::Soap::InvoiceHeader", [0, 1]],
      ["billTo", "CyberSource::Soap::BillTo", [0, 1]],
      ["shipTo", "CyberSource::Soap::ShipTo", [0, 1]],
      ["shipFrom", "CyberSource::Soap::ShipFrom", [0, 1]],
      ["item", "CyberSource::Soap::Item[]", [0, nil]],
      ["purchaseTotals", "CyberSource::Soap::PurchaseTotals", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["dcc", "CyberSource::Soap::DCC", [0, 1]],
      ["pos", "CyberSource::Soap::Pos", [0, 1]],
      ["installment", "CyberSource::Soap::Installment", [0, 1]],
      ["card", "CyberSource::Soap::Card", [0, 1]],
      ["check", "CyberSource::Soap::Check", [0, 1]],
      ["bml", "CyberSource::Soap::BML", [0, 1]],
      ["gecc", "CyberSource::Soap::GECC", [0, 1]],
      ["ucaf", "CyberSource::Soap::UCAF", [0, 1]],
      ["fundTransfer", "CyberSource::Soap::FundTransfer", [0, 1]],
      ["bankInfo", "CyberSource::Soap::BankInfo", [0, 1]],
      ["subscription", "CyberSource::Soap::Subscription", [0, 1]],
      ["recurringSubscriptionInfo", "CyberSource::Soap::RecurringSubscriptionInfo", [0, 1]],
      ["decisionManager", "CyberSource::Soap::DecisionManager", [0, 1]],
      ["otherTax", "CyberSource::Soap::OtherTax", [0, 1]],
      ["paypal", "CyberSource::Soap::PayPal", [0, 1]],
      ["merchantDefinedData", "CyberSource::Soap::MerchantDefinedData", [0, 1]],
      ["merchantSecureData", "CyberSource::Soap::MerchantSecureData", [0, 1]],
      ["jpo", "CyberSource::Soap::JPO", [0, 1]],
      ["orderRequestToken", "SOAP::SOAPString", [0, 1]],
      ["linkToRequest", "SOAP::SOAPString", [0, 1]],
      ["ccAuthService", "CyberSource::Soap::CCAuthService", [0, 1]],
      ["ccCaptureService", "CyberSource::Soap::CCCaptureService", [0, 1]],
      ["ccCreditService", "CyberSource::Soap::CCCreditService", [0, 1]],
      ["ccAuthReversalService", "CyberSource::Soap::CCAuthReversalService", [0, 1]],
      ["ccAutoAuthReversalService", "CyberSource::Soap::CCAutoAuthReversalService", [0, 1]],
      ["ccDCCService", "CyberSource::Soap::CCDCCService", [0, 1]],
      ["ecDebitService", "CyberSource::Soap::ECDebitService", [0, 1]],
      ["ecCreditService", "CyberSource::Soap::ECCreditService", [0, 1]],
      ["ecAuthenticateService", "CyberSource::Soap::ECAuthenticateService", [0, 1]],
      ["payerAuthEnrollService", "CyberSource::Soap::PayerAuthEnrollService", [0, 1]],
      ["payerAuthValidateService", "CyberSource::Soap::PayerAuthValidateService", [0, 1]],
      ["taxService", "CyberSource::Soap::TaxService", [0, 1]],
      ["afsService", "CyberSource::Soap::AFSService", [0, 1]],
      ["davService", "CyberSource::Soap::DAVService", [0, 1]],
      ["exportService", "CyberSource::Soap::ExportService", [0, 1]],
      ["fxRatesService", "CyberSource::Soap::FXRatesService", [0, 1]],
      ["bankTransferService", "CyberSource::Soap::BankTransferService", [0, 1]],
      ["bankTransferRefundService", "CyberSource::Soap::BankTransferRefundService", [0, 1]],
      ["bankTransferRealTimeService", "CyberSource::Soap::BankTransferRealTimeService", [0, 1]],
      ["directDebitMandateService", "CyberSource::Soap::DirectDebitMandateService", [0, 1]],
      ["directDebitService", "CyberSource::Soap::DirectDebitService", [0, 1]],
      ["directDebitRefundService", "CyberSource::Soap::DirectDebitRefundService", [0, 1]],
      ["directDebitValidateService", "CyberSource::Soap::DirectDebitValidateService", [0, 1]],
      ["paySubscriptionCreateService", "CyberSource::Soap::PaySubscriptionCreateService", [0, 1]],
      ["paySubscriptionUpdateService", "CyberSource::Soap::PaySubscriptionUpdateService", [0, 1]],
      ["paySubscriptionEventUpdateService", "CyberSource::Soap::PaySubscriptionEventUpdateService", [0, 1]],
      ["paySubscriptionRetrieveService", "CyberSource::Soap::PaySubscriptionRetrieveService", [0, 1]],
      ["paySubscriptionDeleteService", "CyberSource::Soap::PaySubscriptionDeleteService", [0, 1]],
      ["payPalPaymentService", "CyberSource::Soap::PayPalPaymentService", [0, 1]],
      ["payPalCreditService", "CyberSource::Soap::PayPalCreditService", [0, 1]],
      ["voidService", "CyberSource::Soap::VoidService", [0, 1]],
      ["businessRules", "CyberSource::Soap::BusinessRules", [0, 1]],
      ["pinlessDebitService", "CyberSource::Soap::PinlessDebitService", [0, 1]],
      ["pinlessDebitValidateService", "CyberSource::Soap::PinlessDebitValidateService", [0, 1]],
      ["pinlessDebitReversalService", "CyberSource::Soap::PinlessDebitReversalService", [0, 1]],
      ["batch", "CyberSource::Soap::Batch", [0, 1]],
      ["airlineData", "CyberSource::Soap::AirlineData", [0, 1]],
      ["payPalButtonCreateService", "CyberSource::Soap::PayPalButtonCreateService", [0, 1]],
      ["payPalPreapprovedPaymentService", "CyberSource::Soap::PayPalPreapprovedPaymentService", [0, 1]],
      ["payPalPreapprovedUpdateService", "CyberSource::Soap::PayPalPreapprovedUpdateService", [0, 1]],
      ["riskUpdateService", "CyberSource::Soap::RiskUpdateService", [0, 1]],
      ["fraudUpdateService", "CyberSource::Soap::FraudUpdateService", [0, 1]],
      ["reserved", "CyberSource::Soap::RequestReserved[]", [0, nil]],
      ["deviceFingerprintID", "SOAP::SOAPString", [0, 1]],
      ["payPalRefundService", "CyberSource::Soap::PayPalRefundService", [0, 1]],
      ["payPalAuthReversalService", "CyberSource::Soap::PayPalAuthReversalService", [0, 1]],
      ["payPalDoCaptureService", "CyberSource::Soap::PayPalDoCaptureService", [0, 1]],
      ["payPalEcDoPaymentService", "CyberSource::Soap::PayPalEcDoPaymentService", [0, 1]],
      ["payPalEcGetDetailsService", "CyberSource::Soap::PayPalEcGetDetailsService", [0, 1]],
      ["payPalEcSetService", "CyberSource::Soap::PayPalEcSetService", [0, 1]],
      ["payPalEcOrderSetupService", "CyberSource::Soap::PayPalEcOrderSetupService", [0, 1]],
      ["payPalAuthorizationService", "CyberSource::Soap::PayPalAuthorizationService", [0, 1]],
      ["payPalUpdateAgreementService", "CyberSource::Soap::PayPalUpdateAgreementService", [0, 1]],
      ["payPalCreateAgreementService", "CyberSource::Soap::PayPalCreateAgreementService", [0, 1]],
      ["payPalDoRefTransactionService", "CyberSource::Soap::PayPalDoRefTransactionService", [0, 1]],
      ["chinaPaymentService", "CyberSource::Soap::ChinaPaymentService", [0, 1]],
      ["chinaRefundService", "CyberSource::Soap::ChinaRefundService", [0, 1]],
      ["boletoPaymentService", "CyberSource::Soap::BoletoPaymentService", [0, 1]],
      ["ignoreCardExpiration", nil, [0, 1]],
      ["reportGroup", "SOAP::SOAPString", [0, 1]],
      ["processorID", "SOAP::SOAPString", [0, 1]],
      ["solutionProviderTransactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DCC,
    :schema_type => XSD::QName.new(NsTransactionData167, "DCC"),
    :schema_element => [
      ["dccIndicator", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCAuthReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["authorizationCode", "SOAP::SOAPString", [0, 1]],
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["avsCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["cvCode", "SOAP::SOAPString", [0, 1]],
      ["cvCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["personalIDCode", "SOAP::SOAPString", [0, 1]],
      ["authorizedDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["bmlAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["authFactorCode", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["fxQuoteID", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteRate", nil, [0, 1]],
      ["fxQuoteType", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteExpirationDateTime", nil, [0, 1]],
      ["authRecord", "SOAP::SOAPString", [0, 1]],
      ["merchantAdviceCode", "SOAP::SOAPString", [0, 1]],
      ["merchantAdviceCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["cavvResponseCode", "SOAP::SOAPString", [0, 1]],
      ["cavvResponseCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["authenticationXID", "SOAP::SOAPString", [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["processorCardType", "SOAP::SOAPString", [0, 1]],
      ["accountBalance", nil, [0, 1]],
      ["forwardCode", "SOAP::SOAPString", [0, 1]],
      ["enhancedDataEnabled", "SOAP::SOAPString", [0, 1]],
      ["referralResponseNumber", "SOAP::SOAPString", [0, 1]],
      ["subResponseCode", "SOAP::SOAPString", [0, 1]],
      ["approvedAmount", "SOAP::SOAPString", [0, 1]],
      ["creditLine", "SOAP::SOAPString", [0, 1]],
      ["approvedTerms", "SOAP::SOAPString", [0, 1]],
      ["paymentNetworkTransactionID", "SOAP::SOAPString", [0, 1]],
      ["cardCategory", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]],
      ["requestAmount", nil, [0, 1]],
      ["requestCurrency", "SOAP::SOAPString", [0, 1]],
      ["accountBalanceCurrency", "SOAP::SOAPString", [0, 1]],
      ["accountBalanceSign", "SOAP::SOAPString", [0, 1]],
      ["affluenceIndicator", "SOAP::SOAPString", [0, 1]],
      ["evEmail", "SOAP::SOAPString", [0, 1]],
      ["evPhoneNumber", "SOAP::SOAPString", [0, 1]],
      ["evPostalCode", "SOAP::SOAPString", [0, 1]],
      ["evName", "SOAP::SOAPString", [0, 1]],
      ["evStreet", "SOAP::SOAPString", [0, 1]],
      ["evEmailRaw", "SOAP::SOAPString", [0, 1]],
      ["evPhoneNumberRaw", "SOAP::SOAPString", [0, 1]],
      ["evPostalCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["evNameRaw", "SOAP::SOAPString", [0, 1]],
      ["evStreetRaw", "SOAP::SOAPString", [0, 1]],
      ["cardGroup", "SOAP::SOAPString", [0, 1]],
      ["posData", "SOAP::SOAPString", [0, 1]],
      ["transactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCCaptureReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCaptureReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["fxQuoteID", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteRate", nil, [0, 1]],
      ["fxQuoteType", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteExpirationDateTime", nil, [0, 1]],
      ["purchasingLevel3Enabled", "SOAP::SOAPString", [0, 1]],
      ["enhancedDataEnabled", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCCreditReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCreditReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["purchasingLevel3Enabled", "SOAP::SOAPString", [0, 1]],
      ["enhancedDataEnabled", "SOAP::SOAPString", [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["forwardCode", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCAuthReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["authorizationCode", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["forwardCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCAutoAuthReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAutoAuthReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["result", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ECDebitReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECDebitReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["verificationLevel", "SOAP::SOAPInteger", [0, 1]],
      ["processorTransactionID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["avsCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["verificationCode", "SOAP::SOAPString", [0, 1]],
      ["verificationCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["correctedAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["correctedRoutingNumber", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ECCreditReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECCreditReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["processorTransactionID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["verificationCode", "SOAP::SOAPString", [0, 1]],
      ["verificationCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["correctedAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["correctedRoutingNumber", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ECAuthenticateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECAuthenticateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["checkpointSummary", "SOAP::SOAPString", [0, 1]],
      ["fraudShieldIndicators", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayerAuthEnrollReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthEnrollReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["acsURL", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["eci", "SOAP::SOAPString", [0, 1]],
      ["paReq", "SOAP::SOAPString", [0, 1]],
      ["proxyPAN", "SOAP::SOAPString", [0, 1]],
      ["xid", "SOAP::SOAPString", [0, 1]],
      ["proofXML", "SOAP::SOAPString", [0, 1]],
      ["ucafCollectionIndicator", "SOAP::SOAPString", [0, 1]],
      ["veresEnrolled", "SOAP::SOAPString", [0, 1]],
      ["authenticationPath", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayerAuthValidateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthValidateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["authenticationResult", "SOAP::SOAPString", [0, 1]],
      ["authenticationStatusMessage", "SOAP::SOAPString", [0, 1]],
      ["cavv", "SOAP::SOAPString", [0, 1]],
      ["cavvAlgorithm", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["eci", "SOAP::SOAPString", [0, 1]],
      ["eciRaw", "SOAP::SOAPString", [0, 1]],
      ["xid", "SOAP::SOAPString", [0, 1]],
      ["ucafAuthenticationData", "SOAP::SOAPString", [0, 1]],
      ["ucafCollectionIndicator", "SOAP::SOAPString", [0, 1]],
      ["paresStatus", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::TaxReplyItem,
    :schema_type => XSD::QName.new(NsTransactionData167, "TaxReplyItem"),
    :schema_element => [
      ["cityTaxAmount", nil, [0, 1]],
      ["countyTaxAmount", nil, [0, 1]],
      ["districtTaxAmount", nil, [0, 1]],
      ["stateTaxAmount", nil, [0, 1]],
      ["totalTaxAmount", nil]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::TaxReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "TaxReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["grandTotalAmount", nil, [0, 1]],
      ["totalCityTaxAmount", nil, [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["totalCountyTaxAmount", nil, [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["totalDistrictTaxAmount", nil, [0, 1]],
      ["totalStateTaxAmount", nil, [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["totalTaxAmount", nil, [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["geocode", "SOAP::SOAPString", [0, 1]],
      ["item", "CyberSource::Soap::TaxReplyItem[]", [0, nil]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DeviceFingerprint,
    :schema_type => XSD::QName.new(NsTransactionData167, "DeviceFingerprint"),
    :schema_element => [
      ["cookiesEnabled", nil, [0, 1]],
      ["flashEnabled", nil, [0, 1]],
      ["hash", "SOAP::SOAPString", [0, 1]],
      ["imagesEnabled", nil, [0, 1]],
      ["javascriptEnabled", nil, [0, 1]],
      ["proxyIPAddress", "SOAP::SOAPString", [0, 1]],
      ["proxyIPAddressActivities", "SOAP::SOAPString", [0, 1]],
      ["proxyIPAddressAttributes", "SOAP::SOAPString", [0, 1]],
      ["proxyServerType", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddress", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressActivities", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressAttributes", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressCity", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressCountry", "SOAP::SOAPString", [0, 1]],
      ["smartID", "SOAP::SOAPString", [0, 1]],
      ["smartIDConfidenceLevel", "SOAP::SOAPString", [0, 1]],
      ["screenResolution", "SOAP::SOAPString", [0, 1]],
      ["browserLanguage", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::AFSReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "AFSReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["afsResult", "SOAP::SOAPInteger", [0, 1]],
      ["hostSeverity", "SOAP::SOAPInteger", [0, 1]],
      ["consumerLocalTime", "SOAP::SOAPString", [0, 1]],
      ["afsFactorCode", "SOAP::SOAPString", [0, 1]],
      ["addressInfoCode", "SOAP::SOAPString", [0, 1]],
      ["hotlistInfoCode", "SOAP::SOAPString", [0, 1]],
      ["internetInfoCode", "SOAP::SOAPString", [0, 1]],
      ["phoneInfoCode", "SOAP::SOAPString", [0, 1]],
      ["suspiciousInfoCode", "SOAP::SOAPString", [0, 1]],
      ["velocityInfoCode", "SOAP::SOAPString", [0, 1]],
      ["identityInfoCode", "SOAP::SOAPString", [0, 1]],
      ["ipCountry", "SOAP::SOAPString", [0, 1]],
      ["ipState", "SOAP::SOAPString", [0, 1]],
      ["ipCity", "SOAP::SOAPString", [0, 1]],
      ["ipRoutingMethod", "SOAP::SOAPString", [0, 1]],
      ["scoreModelUsed", "SOAP::SOAPString", [0, 1]],
      ["binCountry", "SOAP::SOAPString", [0, 1]],
      ["cardAccountType", "SOAP::SOAPString", [0, 1]],
      ["cardScheme", "SOAP::SOAPString", [0, 1]],
      ["cardIssuer", "SOAP::SOAPString", [0, 1]],
      ["deviceFingerprint", "CyberSource::Soap::DeviceFingerprint", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DAVReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DAVReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["addressType", "SOAP::SOAPString", [0, 1]],
      ["apartmentInfo", "SOAP::SOAPString", [0, 1]],
      ["barCode", "SOAP::SOAPString", [0, 1]],
      ["barCodeCheckDigit", "SOAP::SOAPString", [0, 1]],
      ["careOf", "SOAP::SOAPString", [0, 1]],
      ["cityInfo", "SOAP::SOAPString", [0, 1]],
      ["countryInfo", "SOAP::SOAPString", [0, 1]],
      ["directionalInfo", "SOAP::SOAPString", [0, 1]],
      ["lvrInfo", "SOAP::SOAPString", [0, 1]],
      ["matchScore", "SOAP::SOAPInteger", [0, 1]],
      ["standardizedAddress1", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddress2", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddress3", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddress4", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddressNoApt", "SOAP::SOAPString", [0, 1]],
      ["standardizedCity", "SOAP::SOAPString", [0, 1]],
      ["standardizedCounty", "SOAP::SOAPString", [0, 1]],
      ["standardizedCSP", "SOAP::SOAPString", [0, 1]],
      ["standardizedState", "SOAP::SOAPString", [0, 1]],
      ["standardizedPostalCode", "SOAP::SOAPString", [0, 1]],
      ["standardizedCountry", "SOAP::SOAPString", [0, 1]],
      ["standardizedISOCountry", "SOAP::SOAPString", [0, 1]],
      ["stateInfo", "SOAP::SOAPString", [0, 1]],
      ["streetInfo", "SOAP::SOAPString", [0, 1]],
      ["suffixInfo", "SOAP::SOAPString", [0, 1]],
      ["postalCodeInfo", "SOAP::SOAPString", [0, 1]],
      ["overallInfo", "SOAP::SOAPString", [0, 1]],
      ["usInfo", "SOAP::SOAPString", [0, 1]],
      ["caInfo", "SOAP::SOAPString", [0, 1]],
      ["intlInfo", "SOAP::SOAPString", [0, 1]],
      ["usErrorInfo", "SOAP::SOAPString", [0, 1]],
      ["caErrorInfo", "SOAP::SOAPString", [0, 1]],
      ["intlErrorInfo", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DeniedPartiesMatch,
    :schema_type => XSD::QName.new(NsTransactionData167, "DeniedPartiesMatch"),
    :schema_element => [
      ["list", "SOAP::SOAPString", [0, 1]],
      ["name", "SOAP::SOAPString[]", [0, nil]],
      ["address", "SOAP::SOAPString[]", [0, nil]],
      ["program", "SOAP::SOAPString[]", [0, nil]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ExportReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ExportReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["ipCountryConfidence", "SOAP::SOAPInteger", [0, 1]],
      ["infoCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FXQuote,
    :schema_type => XSD::QName.new(NsTransactionData167, "FXQuote"),
    :schema_element => [
      ["id", "SOAP::SOAPString", [0, 1]],
      ["rate", "SOAP::SOAPString", [0, 1]],
      ["type", "SOAP::SOAPString", [0, 1]],
      ["expirationDateTime", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["fundingCurrency", "SOAP::SOAPString", [0, 1]],
      ["receivedDateTime", nil, [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FXRatesReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "FXRatesReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["quote", "CyberSource::Soap::FXQuote[]", [0, nil]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankTransferReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["accountHolder", "SOAP::SOAPString", [0, 1]],
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]],
      ["bankName", "SOAP::SOAPString", [0, 1]],
      ["bankCity", "SOAP::SOAPString", [0, 1]],
      ["bankCountry", "SOAP::SOAPString", [0, 1]],
      ["paymentReference", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["bankSwiftCode", "SOAP::SOAPString", [0, 1]],
      ["bankSpecialID", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["iban", "SOAP::SOAPString", [0, 1]],
      ["bankCode", "SOAP::SOAPString", [0, 1]],
      ["branchCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankTransferRealTimeReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRealTimeReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["formMethod", "SOAP::SOAPString", [0, 1]],
      ["formAction", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["paymentReference", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitMandateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitMandateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["mandateID", "SOAP::SOAPString", [0, 1]],
      ["mandateMaturationDate", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BankTransferRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitValidateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitValidateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DirectDebitRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionCreateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionCreateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["subscriptionID", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["subscriptionID", "SOAP::SOAPString"],
      ["subscriptionIDNew", "SOAP::SOAPString"],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionEventUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionEventUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionRetrieveReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionRetrieveReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["approvalRequired", "SOAP::SOAPString", [0, 1]],
      ["automaticRenew", "SOAP::SOAPString", [0, 1]],
      ["cardAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["cardExpirationMonth", "SOAP::SOAPString", [0, 1]],
      ["cardExpirationYear", "SOAP::SOAPString", [0, 1]],
      ["cardIssueNumber", "SOAP::SOAPString", [0, 1]],
      ["cardStartMonth", "SOAP::SOAPString", [0, 1]],
      ["cardStartYear", "SOAP::SOAPString", [0, 1]],
      ["cardType", "SOAP::SOAPString", [0, 1]],
      ["checkAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["checkAccountType", "SOAP::SOAPString", [0, 1]],
      ["checkBankTransitNumber", "SOAP::SOAPString", [0, 1]],
      ["checkSecCode", "SOAP::SOAPString", [0, 1]],
      ["checkAuthenticateID", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["companyName", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["customerAccountID", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]],
      ["endDate", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["frequency", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["paymentMethod", "SOAP::SOAPString", [0, 1]],
      ["paymentsRemaining", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["recurringAmount", "SOAP::SOAPString", [0, 1]],
      ["setupAmount", "SOAP::SOAPString", [0, 1]],
      ["startDate", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["status", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["subscriptionID", "SOAP::SOAPString", [0, 1]],
      ["subscriptionIDNew", "SOAP::SOAPString"],
      ["title", "SOAP::SOAPString", [0, 1]],
      ["totalPayments", "SOAP::SOAPString", [0, 1]],
      ["shipToFirstName", "SOAP::SOAPString", [0, 1]],
      ["shipToLastName", "SOAP::SOAPString", [0, 1]],
      ["shipToStreet1", "SOAP::SOAPString", [0, 1]],
      ["shipToStreet2", "SOAP::SOAPString", [0, 1]],
      ["shipToCity", "SOAP::SOAPString", [0, 1]],
      ["shipToState", "SOAP::SOAPString", [0, 1]],
      ["shipToPostalCode", "SOAP::SOAPString", [0, 1]],
      ["shipToCompany", "SOAP::SOAPString", [0, 1]],
      ["shipToCountry", "SOAP::SOAPString", [0, 1]],
      ["billPayment", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField1", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField2", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField3", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField4", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField1", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField2", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField3", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField4", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]],
      ["companyTaxID", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseNumber", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseState", "SOAP::SOAPString", [0, 1]],
      ["dateOfBirth", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionDeleteReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionDeleteReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["subscriptionID", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["secureData", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalCreditReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreditReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::VoidReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "VoidReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PinlessDebitReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["authorizationCode", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["receiptNumber", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PinlessDebitValidateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitValidateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["status", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PinlessDebitReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalButtonCreateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalButtonCreateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["encryptedFormData", "SOAP::SOAPString", [0, 1]],
      ["unencryptedFormData", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["buttonType", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerName", "SOAP::SOAPString", [0, 1]],
      ["transactionType", "SOAP::SOAPString", [0, 1]],
      ["feeAmount", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["pendingReason", "SOAP::SOAPString", [0, 1]],
      ["paymentStatus", "SOAP::SOAPString", [0, 1]],
      ["mpStatus", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerID", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["transactionID", "SOAP::SOAPString", [0, 1]],
      ["desc", "SOAP::SOAPString", [0, 1]],
      ["mpMax", "SOAP::SOAPString", [0, 1]],
      ["paymentType", "SOAP::SOAPString", [0, 1]],
      ["paymentDate", "SOAP::SOAPString", [0, 1]],
      ["paymentGrossAmount", "SOAP::SOAPString", [0, 1]],
      ["settleAmount", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", "SOAP::SOAPString", [0, 1]],
      ["exchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paymentSourceID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerName", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["mpStatus", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerID", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["desc", "SOAP::SOAPString", [0, 1]],
      ["mpMax", "SOAP::SOAPString", [0, 1]],
      ["paymentSourceID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcSetReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcSetReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcGetDetailsReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcGetDetailsReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerId", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerSalutation", "SOAP::SOAPString", [0, 1]],
      ["payerFirstname", "SOAP::SOAPString", [0, 1]],
      ["payerMiddlename", "SOAP::SOAPString", [0, 1]],
      ["payerLastname", "SOAP::SOAPString", [0, 1]],
      ["payerSuffix", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["shipToName", "SOAP::SOAPString", [0, 1]],
      ["shipToAddress1", "SOAP::SOAPString", [0, 1]],
      ["shipToAddress2", "SOAP::SOAPString", [0, 1]],
      ["shipToCity", "SOAP::SOAPString", [0, 1]],
      ["shipToState", "SOAP::SOAPString", [0, 1]],
      ["shipToCountry", "SOAP::SOAPString", [0, 1]],
      ["shipToZip", "SOAP::SOAPString", [0, 1]],
      ["addressStatus", "SOAP::SOAPString", [0, 1]],
      ["payerPhone", "SOAP::SOAPString", [0, 1]],
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["countryCode", "SOAP::SOAPString", [0, 1]],
      ["countryName", "SOAP::SOAPString", [0, 1]],
      ["addressID", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementAcceptedStatus", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcDoPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcDoPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactiontype", "SOAP::SOAPString", [0, 1]],
      ["paymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalPendingReason", "SOAP::SOAPString", [0, 1]],
      ["orderId", "SOAP::SOAPString", [0, 1]],
      ["paypalReasonCode", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalDoCaptureReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoCaptureReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["authorizationId", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["parentTransactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalReceiptId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactiontype", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentGrossAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalAuthReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["authorizationId", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalNetRefundAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeRefundAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalGrossRefundAmount", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalEcOrderSetupReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcOrderSetupReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactiontype", "SOAP::SOAPString", [0, 1]],
      ["paymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalPendingReason", "SOAP::SOAPString", [0, 1]],
      ["paypalReasonCode", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalAuthorizationReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthorizationReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["protectionEligibility", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalUpdateAgreementReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalUpdateAgreementReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementCustom", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementStatus", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerId", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["payerSalutation", "SOAP::SOAPString", [0, 1]],
      ["payerFirstname", "SOAP::SOAPString", [0, 1]],
      ["payerMiddlename", "SOAP::SOAPString", [0, 1]],
      ["payerLastname", "SOAP::SOAPString", [0, 1]],
      ["payerSuffix", "SOAP::SOAPString", [0, 1]],
      ["addressStatus", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalCreateAgreementReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreateAgreementReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::PayPalDoRefTransactionReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoRefTransactionReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactionType", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalPendingReason", "SOAP::SOAPString", [0, 1]],
      ["paypalReasonCode", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RiskUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "RiskUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FraudUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "FraudUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RuleResultItem,
    :schema_type => XSD::QName.new(NsTransactionData167, "RuleResultItem"),
    :schema_element => [
      ["name", "SOAP::SOAPString", [0, 1]],
      ["decision", "SOAP::SOAPString", [0, 1]],
      ["evaluation", "SOAP::SOAPString", [0, 1]],
      ["ruleID", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RuleResultItems,
    :schema_type => XSD::QName.new(NsTransactionData167, "RuleResultItems"),
    :schema_element => [
      ["ruleResultItem", "CyberSource::Soap::RuleResultItem[]", [0, nil]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::DecisionReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionReply"),
    :schema_element => [
      ["casePriority", "SOAP::SOAPInteger", [0, 1]],
      ["activeProfileReply", "CyberSource::Soap::ProfileReply", [0, 1]],
      ["velocityInfoCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ProfileReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ProfileReply"),
    :schema_element => [
      ["selectedBy", "SOAP::SOAPString", [0, 1]],
      ["name", "SOAP::SOAPString", [0, 1]],
      ["destinationQueue", "SOAP::SOAPString", [0, 1]],
      ["rulesTriggered", "CyberSource::Soap::RuleResultItems", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::CCDCCReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCDCCReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["dccSupported", nil, [0, 1]],
      ["validHours", "SOAP::SOAPString", [0, 1]],
      ["marginRatePercentage", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ChinaPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["formData", "SOAP::SOAPString", [0, 1]],
      ["verifyFailure", "SOAP::SOAPString", [0, 1]],
      ["verifyInProcess", "SOAP::SOAPString", [0, 1]],
      ["verifySuccess", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ChinaRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::BoletoPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BoletoPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["boletoNumber", "SOAP::SOAPString", [0, 1]],
      ["expirationDate", "SOAP::SOAPString", [0, 1]],
      ["url", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ReplyMessage,
    :schema_type => XSD::QName.new(NsTransactionData167, "ReplyMessage"),
    :schema_element => [
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["requestID", "SOAP::SOAPString"],
      ["decision", "SOAP::SOAPString"],
      ["reasonCode", "SOAP::SOAPInteger"],
      ["missingField", "SOAP::SOAPString[]", [0, nil]],
      ["invalidField", "SOAP::SOAPString[]", [0, nil]],
      ["requestToken", "SOAP::SOAPString"],
      ["purchaseTotals", "CyberSource::Soap::PurchaseTotals", [0, 1]],
      ["deniedPartiesMatch", "CyberSource::Soap::DeniedPartiesMatch[]", [0, nil]],
      ["ccAuthReply", "CyberSource::Soap::CCAuthReply", [0, 1]],
      ["ccCaptureReply", "CyberSource::Soap::CCCaptureReply", [0, 1]],
      ["ccCreditReply", "CyberSource::Soap::CCCreditReply", [0, 1]],
      ["ccAuthReversalReply", "CyberSource::Soap::CCAuthReversalReply", [0, 1]],
      ["ccAutoAuthReversalReply", "CyberSource::Soap::CCAutoAuthReversalReply", [0, 1]],
      ["ccDCCReply", "CyberSource::Soap::CCDCCReply", [0, 1]],
      ["ecDebitReply", "CyberSource::Soap::ECDebitReply", [0, 1]],
      ["ecCreditReply", "CyberSource::Soap::ECCreditReply", [0, 1]],
      ["ecAuthenticateReply", "CyberSource::Soap::ECAuthenticateReply", [0, 1]],
      ["payerAuthEnrollReply", "CyberSource::Soap::PayerAuthEnrollReply", [0, 1]],
      ["payerAuthValidateReply", "CyberSource::Soap::PayerAuthValidateReply", [0, 1]],
      ["taxReply", "CyberSource::Soap::TaxReply", [0, 1]],
      ["afsReply", "CyberSource::Soap::AFSReply", [0, 1]],
      ["davReply", "CyberSource::Soap::DAVReply", [0, 1]],
      ["exportReply", "CyberSource::Soap::ExportReply", [0, 1]],
      ["fxRatesReply", "CyberSource::Soap::FXRatesReply", [0, 1]],
      ["bankTransferReply", "CyberSource::Soap::BankTransferReply", [0, 1]],
      ["bankTransferRefundReply", "CyberSource::Soap::BankTransferRefundReply", [0, 1]],
      ["bankTransferRealTimeReply", "CyberSource::Soap::BankTransferRealTimeReply", [0, 1]],
      ["directDebitMandateReply", "CyberSource::Soap::DirectDebitMandateReply", [0, 1]],
      ["directDebitReply", "CyberSource::Soap::DirectDebitReply", [0, 1]],
      ["directDebitValidateReply", "CyberSource::Soap::DirectDebitValidateReply", [0, 1]],
      ["directDebitRefundReply", "CyberSource::Soap::DirectDebitRefundReply", [0, 1]],
      ["paySubscriptionCreateReply", "CyberSource::Soap::PaySubscriptionCreateReply", [0, 1]],
      ["paySubscriptionUpdateReply", "CyberSource::Soap::PaySubscriptionUpdateReply", [0, 1]],
      ["paySubscriptionEventUpdateReply", "CyberSource::Soap::PaySubscriptionEventUpdateReply", [0, 1]],
      ["paySubscriptionRetrieveReply", "CyberSource::Soap::PaySubscriptionRetrieveReply", [0, 1]],
      ["paySubscriptionDeleteReply", "CyberSource::Soap::PaySubscriptionDeleteReply", [0, 1]],
      ["payPalPaymentReply", "CyberSource::Soap::PayPalPaymentReply", [0, 1]],
      ["payPalCreditReply", "CyberSource::Soap::PayPalCreditReply", [0, 1]],
      ["voidReply", "CyberSource::Soap::VoidReply", [0, 1]],
      ["pinlessDebitReply", "CyberSource::Soap::PinlessDebitReply", [0, 1]],
      ["pinlessDebitValidateReply", "CyberSource::Soap::PinlessDebitValidateReply", [0, 1]],
      ["pinlessDebitReversalReply", "CyberSource::Soap::PinlessDebitReversalReply", [0, 1]],
      ["payPalButtonCreateReply", "CyberSource::Soap::PayPalButtonCreateReply", [0, 1]],
      ["payPalPreapprovedPaymentReply", "CyberSource::Soap::PayPalPreapprovedPaymentReply", [0, 1]],
      ["payPalPreapprovedUpdateReply", "CyberSource::Soap::PayPalPreapprovedUpdateReply", [0, 1]],
      ["riskUpdateReply", "CyberSource::Soap::RiskUpdateReply", [0, 1]],
      ["fraudUpdateReply", "CyberSource::Soap::FraudUpdateReply", [0, 1]],
      ["decisionReply", "CyberSource::Soap::DecisionReply", [0, 1]],
      ["reserved", "CyberSource::Soap::ReplyReserved", [0, 1]],
      ["payPalRefundReply", "CyberSource::Soap::PayPalRefundReply", [0, 1]],
      ["payPalAuthReversalReply", "CyberSource::Soap::PayPalAuthReversalReply", [0, 1]],
      ["payPalDoCaptureReply", "CyberSource::Soap::PayPalDoCaptureReply", [0, 1]],
      ["payPalEcDoPaymentReply", "CyberSource::Soap::PayPalEcDoPaymentReply", [0, 1]],
      ["payPalEcGetDetailsReply", "CyberSource::Soap::PayPalEcGetDetailsReply", [0, 1]],
      ["payPalEcSetReply", "CyberSource::Soap::PayPalEcSetReply", [0, 1]],
      ["payPalAuthorizationReply", "CyberSource::Soap::PayPalAuthorizationReply", [0, 1]],
      ["payPalEcOrderSetupReply", "CyberSource::Soap::PayPalEcOrderSetupReply", [0, 1]],
      ["payPalUpdateAgreementReply", "CyberSource::Soap::PayPalUpdateAgreementReply", [0, 1]],
      ["payPalCreateAgreementReply", "CyberSource::Soap::PayPalCreateAgreementReply", [0, 1]],
      ["payPalDoRefTransactionReply", "CyberSource::Soap::PayPalDoRefTransactionReply", [0, 1]],
      ["chinaPaymentReply", "CyberSource::Soap::ChinaPaymentReply", [0, 1]],
      ["chinaRefundReply", "CyberSource::Soap::ChinaRefundReply", [0, 1]],
      ["boletoPaymentReply", "CyberSource::Soap::BoletoPaymentReply", [0, 1]],
      ["receiptNumber", "SOAP::SOAPString", [0, 1]],
      ["additionalData", "SOAP::SOAPString", [0, 1]],
      ["solutionProviderTransactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::FaultDetails,
    :schema_type => XSD::QName.new(NsTransactionData167, "FaultDetails"),
    :schema_element => [
      ["requestID", "SOAP::SOAPString"]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::AirlineData,
    :schema_type => XSD::QName.new(NsTransactionData167, "AirlineData"),
    :schema_element => [
      ["agentCode", "SOAP::SOAPString", [0, 1]],
      ["agentName", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerCity", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerState", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerPostalCode", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerCountry", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerAddress", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerCode", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerName", "SOAP::SOAPString", [0, 1]],
      ["ticketNumber", "SOAP::SOAPString", [0, 1]],
      ["checkDigit", "SOAP::SOAPInteger", [0, 1]],
      ["restrictedTicketIndicator", "SOAP::SOAPInteger", [0, 1]],
      ["transactionType", "SOAP::SOAPString", [0, 1]],
      ["extendedPaymentCode", "SOAP::SOAPString", [0, 1]],
      ["carrierName", "SOAP::SOAPString", [0, 1]],
      ["passengerName", "SOAP::SOAPString", [0, 1]],
      ["customerCode", "SOAP::SOAPString", [0, 1]],
      ["documentType", "SOAP::SOAPString", [0, 1]],
      ["documentNumber", "SOAP::SOAPString", [0, 1]],
      ["documentNumberOfParts", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]],
      ["invoiceDate", "SOAP::SOAPString", [0, 1]],
      ["chargeDetails", "SOAP::SOAPString", [0, 1]],
      ["bookingReference", "SOAP::SOAPString", [0, 1]],
      ["totalFee", nil, [0, 1]],
      ["clearingSequence", "SOAP::SOAPString", [0, 1]],
      ["clearingCount", "SOAP::SOAPInteger", [0, 1]],
      ["totalClearingAmount", nil, [0, 1]],
      ["leg", "CyberSource::Soap::Leg[]", [0, nil]],
      ["numberOfPassengers", "SOAP::SOAPString", [0, 1]],
      ["reservationSystem", "SOAP::SOAPString", [0, 1]],
      ["processIdentifier", "SOAP::SOAPString", [0, 1]],
      ["iataNumericCode", "SOAP::SOAPString", [0, 1]],
      ["ticketIssueDate", "SOAP::SOAPString", [0, 1]],
      ["electronicTicket", "SOAP::SOAPString", [0, 1]],
      ["originalTicketNumber", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Leg,
    :schema_type => XSD::QName.new(NsTransactionData167, "Leg"),
    :schema_element => [
      ["carrierCode", "SOAP::SOAPString", [0, 1]],
      ["flightNumber", "SOAP::SOAPString", [0, 1]],
      ["originatingAirportCode", "SOAP::SOAPString", [0, 1]],
      ["v_class", ["SOAP::SOAPString", XSD::QName.new(NsTransactionData167, "class")], [0, 1]],
      ["stopoverCode", "SOAP::SOAPString", [0, 1]],
      ["departureDate", "SOAP::SOAPString", [0, 1]],
      ["destination", "SOAP::SOAPString", [0, 1]],
      ["fareBasis", "SOAP::SOAPString", [0, 1]],
      ["departTax", "SOAP::SOAPString", [0, 1]],
      ["conjunctionTicket", "SOAP::SOAPString", [0, 1]],
      ["exchangeTicket", "SOAP::SOAPString", [0, 1]],
      ["couponNumber", "SOAP::SOAPString", [0, 1]],
      ["departureTime", "SOAP::SOAPString", [0, 1]],
      ["departureTimeSegment", "SOAP::SOAPString", [0, 1]],
      ["arrivalTime", "SOAP::SOAPString", [0, 1]],
      ["arrivalTimeSegment", "SOAP::SOAPString", [0, 1]],
      ["endorsementsRestrictions", "SOAP::SOAPString", [0, 1]],
      ["fare", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Pos,
    :schema_type => XSD::QName.new(NsTransactionData167, "Pos"),
    :schema_element => [
      ["entryMode", "SOAP::SOAPString", [0, 1]],
      ["cardPresent", "SOAP::SOAPString", [0, 1]],
      ["terminalCapability", "SOAP::SOAPString", [0, 1]],
      ["trackData", "SOAP::SOAPString", [0, 1]],
      ["terminalID", "SOAP::SOAPString", [0, 1]],
      ["terminalType", "SOAP::SOAPString", [0, 1]],
      ["terminalLocation", "SOAP::SOAPString", [0, 1]],
      ["transactionSecurity", "SOAP::SOAPString", [0, 1]],
      ["catLevel", "SOAP::SOAPString", [0, 1]],
      ["conditionCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::Installment,
    :schema_type => XSD::QName.new(NsTransactionData167, "Installment"),
    :schema_element => [
      ["sequence", "SOAP::SOAPString", [0, 1]],
      ["totalCount", "SOAP::SOAPString", [0, 1]],
      ["totalAmount", "SOAP::SOAPString", [0, 1]],
      ["frequency", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::MerchantDefinedData,
    :schema_type => XSD::QName.new(NsTransactionData167, "MerchantDefinedData"),
    :schema_element => [
      ["field1", "SOAP::SOAPString", [0, 1]],
      ["field2", "SOAP::SOAPString", [0, 1]],
      ["field3", "SOAP::SOAPString", [0, 1]],
      ["field4", "SOAP::SOAPString", [0, 1]],
      ["field5", "SOAP::SOAPString", [0, 1]],
      ["field6", "SOAP::SOAPString", [0, 1]],
      ["field7", "SOAP::SOAPString", [0, 1]],
      ["field8", "SOAP::SOAPString", [0, 1]],
      ["field9", "SOAP::SOAPString", [0, 1]],
      ["field10", "SOAP::SOAPString", [0, 1]],
      ["field11", "SOAP::SOAPString", [0, 1]],
      ["field12", "SOAP::SOAPString", [0, 1]],
      ["field13", "SOAP::SOAPString", [0, 1]],
      ["field14", "SOAP::SOAPString", [0, 1]],
      ["field15", "SOAP::SOAPString", [0, 1]],
      ["field16", "SOAP::SOAPString", [0, 1]],
      ["field17", "SOAP::SOAPString", [0, 1]],
      ["field18", "SOAP::SOAPString", [0, 1]],
      ["field19", "SOAP::SOAPString", [0, 1]],
      ["field20", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::MerchantSecureData,
    :schema_type => XSD::QName.new(NsTransactionData167, "MerchantSecureData"),
    :schema_element => [
      ["field1", "SOAP::SOAPString", [0, 1]],
      ["field2", "SOAP::SOAPString", [0, 1]],
      ["field3", "SOAP::SOAPString", [0, 1]],
      ["field4", "SOAP::SOAPString", [0, 1]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::ReplyReserved,
    :schema_type => XSD::QName.new(NsTransactionData167, "ReplyReserved"),
    :schema_element => [
      ["any", [nil, XSD::QName.new(NsXMLSchema, "anyType")]]
    ]
  )

  EncodedRegistry.register(
    :class => CyberSource::Soap::RequestReserved,
    :schema_type => XSD::QName.new(NsTransactionData167, "RequestReserved"),
    :schema_element => [
      ["name", "SOAP::SOAPString"],
      ["value", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Item,
    :schema_type => XSD::QName.new(NsTransactionData167, "Item"),
    :schema_element => [
      ["unitPrice", nil, [0, 1]],
      ["quantity", "SOAP::SOAPInteger", [0, 1]],
      ["productCode", "SOAP::SOAPString", [0, 1]],
      ["productName", "SOAP::SOAPString", [0, 1]],
      ["productSKU", "SOAP::SOAPString", [0, 1]],
      ["productRisk", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", nil, [0, 1]],
      ["cityOverrideAmount", nil, [0, 1]],
      ["cityOverrideRate", nil, [0, 1]],
      ["countyOverrideAmount", nil, [0, 1]],
      ["countyOverrideRate", nil, [0, 1]],
      ["districtOverrideAmount", nil, [0, 1]],
      ["districtOverrideRate", nil, [0, 1]],
      ["stateOverrideAmount", nil, [0, 1]],
      ["stateOverrideRate", nil, [0, 1]],
      ["countryOverrideAmount", nil, [0, 1]],
      ["countryOverrideRate", nil, [0, 1]],
      ["orderAcceptanceCity", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCounty", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCountry", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceState", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptancePostalCode", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCity", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCounty", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCountry", "SOAP::SOAPString", [0, 1]],
      ["orderOriginState", "SOAP::SOAPString", [0, 1]],
      ["orderOriginPostalCode", "SOAP::SOAPString", [0, 1]],
      ["shipFromCity", "SOAP::SOAPString", [0, 1]],
      ["shipFromCounty", "SOAP::SOAPString", [0, 1]],
      ["shipFromCountry", "SOAP::SOAPString", [0, 1]],
      ["shipFromState", "SOAP::SOAPString", [0, 1]],
      ["shipFromPostalCode", "SOAP::SOAPString", [0, 1]],
      ["export", "SOAP::SOAPString", [0, 1]],
      ["noExport", "SOAP::SOAPString", [0, 1]],
      ["nationalTax", nil, [0, 1]],
      ["vatRate", nil, [0, 1]],
      ["sellerRegistration", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration0", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration1", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration2", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration3", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration4", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration5", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration6", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration7", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration8", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration9", "SOAP::SOAPString", [0, 1]],
      ["buyerRegistration", "SOAP::SOAPString", [0, 1]],
      ["middlemanRegistration", "SOAP::SOAPString", [0, 1]],
      ["pointOfTitleTransfer", "SOAP::SOAPString", [0, 1]],
      ["giftCategory", nil, [0, 1]],
      ["timeCategory", "SOAP::SOAPString", [0, 1]],
      ["hostHedge", "SOAP::SOAPString", [0, 1]],
      ["timeHedge", "SOAP::SOAPString", [0, 1]],
      ["velocityHedge", "SOAP::SOAPString", [0, 1]],
      ["nonsensicalHedge", "SOAP::SOAPString", [0, 1]],
      ["phoneHedge", "SOAP::SOAPString", [0, 1]],
      ["obscenitiesHedge", "SOAP::SOAPString", [0, 1]],
      ["unitOfMeasure", "SOAP::SOAPString", [0, 1]],
      ["taxRate", nil, [0, 1]],
      ["totalAmount", nil, [0, 1]],
      ["discountAmount", nil, [0, 1]],
      ["discountRate", nil, [0, 1]],
      ["commodityCode", "SOAP::SOAPString", [0, 1]],
      ["grossNetIndicator", "SOAP::SOAPString", [0, 1]],
      ["taxTypeApplied", "SOAP::SOAPString", [0, 1]],
      ["discountIndicator", "SOAP::SOAPString", [0, 1]],
      ["alternateTaxID", "SOAP::SOAPString", [0, 1]],
      ["alternateTaxAmount", nil, [0, 1]],
      ["alternateTaxTypeApplied", "SOAP::SOAPString", [0, 1]],
      ["alternateTaxRate", nil, [0, 1]],
      ["alternateTaxType", "SOAP::SOAPString", [0, 1]],
      ["localTax", nil, [0, 1]],
      ["zeroCostToCustomerIndicator", "SOAP::SOAPString", [0, 1]],
      ["passengerFirstName", "SOAP::SOAPString", [0, 1]],
      ["passengerLastName", "SOAP::SOAPString", [0, 1]],
      ["passengerID", "SOAP::SOAPString", [0, 1]],
      ["passengerStatus", "SOAP::SOAPString", [0, 1]],
      ["passengerType", "SOAP::SOAPString", [0, 1]],
      ["passengerEmail", "SOAP::SOAPString", [0, 1]],
      ["passengerPhone", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCAuthService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthService"),
    :schema_element => [
      ["cavv", "SOAP::SOAPString", [0, 1]],
      ["cavvAlgorithm", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["eciRaw", "SOAP::SOAPString", [0, 1]],
      ["xid", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["avsLevel", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteID", "SOAP::SOAPString", [0, 1]],
      ["returnAuthRecord", nil, [0, 1]],
      ["authType", "SOAP::SOAPString", [0, 1]],
      ["verbalAuthCode", "SOAP::SOAPString", [0, 1]],
      ["billPayment", nil, [0, 1]],
      ["authenticationXID", "SOAP::SOAPString", [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["industryDatatype", "SOAP::SOAPString", [0, 1]],
      ["traceNumber", "SOAP::SOAPString", [0, 1]],
      ["checksumKey", "SOAP::SOAPString", [0, 1]],
      ["aggregatorID", "SOAP::SOAPString", [0, 1]],
      ["splitTenderIndicator", "SOAP::SOAPString", [0, 1]],
      ["veresEnrolled", "SOAP::SOAPString", [0, 1]],
      ["paresStatus", "SOAP::SOAPString", [0, 1]],
      ["partialAuthIndicator", nil, [0, 1]],
      ["captureDate", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCCaptureService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCaptureService"),
    :schema_element => [
      ["authType", "SOAP::SOAPString", [0, 1]],
      ["verbalAuthCode", "SOAP::SOAPString", [0, 1]],
      ["authRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["purchasingLevel", "SOAP::SOAPString", [0, 1]],
      ["industryDatatype", "SOAP::SOAPString", [0, 1]],
      ["authRequestToken", "SOAP::SOAPString", [0, 1]],
      ["merchantReceiptNumber", "SOAP::SOAPString", [0, 1]],
      ["posData", "SOAP::SOAPString", [0, 1]],
      ["transactionID", "SOAP::SOAPString", [0, 1]],
      ["checksumKey", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCCreditService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCreditService"),
    :schema_element => [
      ["captureRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["purchasingLevel", "SOAP::SOAPString", [0, 1]],
      ["industryDatatype", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["billPayment", nil, [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["occurrenceNumber", "SOAP::SOAPString", [0, 1]],
      ["authCode", "SOAP::SOAPString", [0, 1]],
      ["captureRequestToken", "SOAP::SOAPString", [0, 1]],
      ["merchantReceiptNumber", "SOAP::SOAPString", [0, 1]],
      ["checksumKey", "SOAP::SOAPString", [0, 1]],
      ["aggregatorID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCAuthReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthReversalService"),
    :schema_element => [
      ["authRequestID", "SOAP::SOAPString", [0, 1]],
      ["authRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCAutoAuthReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAutoAuthReversalService"),
    :schema_element => [
      ["authPaymentServiceData", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["authAmount", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["authRequestID", "SOAP::SOAPString", [0, 1]],
      ["billAmount", "SOAP::SOAPString", [0, 1]],
      ["authCode", "SOAP::SOAPString", [0, 1]],
      ["authType", "SOAP::SOAPString", [0, 1]],
      ["billPayment", nil, [0, 1]],
      ["dateAdded", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCDCCService,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCDCCService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ECDebitService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECDebitService"),
    :schema_element => [
      ["paymentMode", "SOAP::SOAPInteger", [0, 1]],
      ["referenceNumber", "SOAP::SOAPString", [0, 1]],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["transactionToken", "SOAP::SOAPString", [0, 1]],
      ["verificationLevel", "SOAP::SOAPInteger", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["debitRequestID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ECCreditService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECCreditService"),
    :schema_element => [
      ["referenceNumber", "SOAP::SOAPString", [0, 1]],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["transactionToken", "SOAP::SOAPString", [0, 1]],
      ["debitRequestID", "SOAP::SOAPString", [0, 1]],
      ["partialPaymentID", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["debitRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ECAuthenticateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECAuthenticateService"),
    :schema_element => [
      ["referenceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayerAuthEnrollService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthEnrollService"),
    :schema_element => [
      ["httpAccept", "SOAP::SOAPString", [0, 1]],
      ["httpUserAgent", "SOAP::SOAPString", [0, 1]],
      ["merchantName", "SOAP::SOAPString", [0, 1]],
      ["merchantURL", "SOAP::SOAPString", [0, 1]],
      ["purchaseDescription", "SOAP::SOAPString", [0, 1]],
      ["purchaseTime", nil, [0, 1]],
      ["countryCode", "SOAP::SOAPString", [0, 1]],
      ["acquirerBin", "SOAP::SOAPString", [0, 1]],
      ["loginID", "SOAP::SOAPString", [0, 1]],
      ["password", "SOAP::SOAPString", [0, 1]],
      ["merchantID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayerAuthValidateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthValidateService"),
    :schema_element => [
      ["signedPARes", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::TaxService,
    :schema_type => XSD::QName.new(NsTransactionData167, "TaxService"),
    :schema_element => [
      ["nexus", "SOAP::SOAPString", [0, 1]],
      ["noNexus", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCity", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCounty", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceCountry", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptanceState", "SOAP::SOAPString", [0, 1]],
      ["orderAcceptancePostalCode", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCity", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCounty", "SOAP::SOAPString", [0, 1]],
      ["orderOriginCountry", "SOAP::SOAPString", [0, 1]],
      ["orderOriginState", "SOAP::SOAPString", [0, 1]],
      ["orderOriginPostalCode", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration0", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration1", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration2", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration3", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration4", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration5", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration6", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration7", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration8", "SOAP::SOAPString", [0, 1]],
      ["sellerRegistration9", "SOAP::SOAPString", [0, 1]],
      ["buyerRegistration", "SOAP::SOAPString", [0, 1]],
      ["middlemanRegistration", "SOAP::SOAPString", [0, 1]],
      ["pointOfTitleTransfer", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::AFSService,
    :schema_type => XSD::QName.new(NsTransactionData167, "AFSService"),
    :schema_element => [
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["cvCode", "SOAP::SOAPString", [0, 1]],
      ["disableAVSScoring", nil, [0, 1]],
      ["customRiskModel", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DAVService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DAVService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ExportService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ExportService"),
    :schema_element => [
      ["addressOperator", "SOAP::SOAPString", [0, 1]],
      ["addressWeight", "SOAP::SOAPString", [0, 1]],
      ["companyWeight", "SOAP::SOAPString", [0, 1]],
      ["nameWeight", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FXRatesService,
    :schema_type => XSD::QName.new(NsTransactionData167, "FXRatesService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankTransferService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankTransferRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRefundService"),
    :schema_element => [
      ["bankTransferRequestID", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRealTimeRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRealTimeReconciliationID", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRequestToken", "SOAP::SOAPString", [0, 1]],
      ["bankTransferRealTimeRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankTransferRealTimeService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRealTimeService"),
    :schema_element => [
      ["bankTransferRealTimeType", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitMandateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitMandateService"),
    :schema_element => [
      ["mandateDescriptor", "SOAP::SOAPString", [0, 1]],
      ["firstDebitDate", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitService"),
    :schema_element => [
      ["dateCollect", "SOAP::SOAPString", [0, 1]],
      ["directDebitText", "SOAP::SOAPString", [0, 1]],
      ["authorizationID", "SOAP::SOAPString", [0, 1]],
      ["transactionType", "SOAP::SOAPString", [0, 1]],
      ["directDebitType", "SOAP::SOAPString", [0, 1]],
      ["validateRequestID", "SOAP::SOAPString", [0, 1]],
      ["recurringType", "SOAP::SOAPString", [0, 1]],
      ["mandateID", "SOAP::SOAPString", [0, 1]],
      ["validateRequestToken", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["mandateAuthenticationDate", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitRefundService"),
    :schema_element => [
      ["directDebitRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["directDebitRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitValidateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitValidateService"),
    :schema_element => [
      ["directDebitValidateText", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionCreateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionCreateService"),
    :schema_element => [
      ["paymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["paymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["disableAutoAuth", nil, [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionUpdateService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionEventUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionEventUpdateService"),
    :schema_element => [
      ["action", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionRetrieveService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionRetrieveService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionDeleteService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionDeleteService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPaymentService"),
    :schema_element => [
      ["cancelURL", "SOAP::SOAPString", [0, 1]],
      ["successURL", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalCreditService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreditService"),
    :schema_element => [
      ["payPalPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["payPalPaymentRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcSetService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcSetService"),
    :schema_element => [
      ["paypalReturn", "SOAP::SOAPString", [0, 1]],
      ["paypalCancelReturn", "SOAP::SOAPString", [0, 1]],
      ["paypalMaxamt", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalReqconfirmshipping", "SOAP::SOAPString", [0, 1]],
      ["paypalNoshipping", "SOAP::SOAPString", [0, 1]],
      ["paypalAddressOverride", "SOAP::SOAPString", [0, 1]],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalLc", "SOAP::SOAPString", [0, 1]],
      ["paypalPagestyle", "SOAP::SOAPString", [0, 1]],
      ["paypalHdrimg", "SOAP::SOAPString", [0, 1]],
      ["paypalHdrbordercolor", "SOAP::SOAPString", [0, 1]],
      ["paypalHdrbackcolor", "SOAP::SOAPString", [0, 1]],
      ["paypalPayflowcolor", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]],
      ["promoCode0", "SOAP::SOAPString", [0, 1]],
      ["requestBillingAddress", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingType", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementCustom", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcGetDetailsService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcGetDetailsService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcDoPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcDoPaymentService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalPayerId", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]],
      ["promoCode0", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalDoCaptureService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoCaptureService"),
    :schema_element => [
      ["paypalAuthorizationId", "SOAP::SOAPString", [0, 1]],
      ["completeType", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestToken", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalAuthReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthReversalService"),
    :schema_element => [
      ["paypalAuthorizationId", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcDoPaymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalAuthorizationRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalRefundService"),
    :schema_element => [
      ["paypalDoCaptureRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalDoCaptureRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalCaptureId", "SOAP::SOAPString", [0, 1]],
      ["paypalNote", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcOrderSetupService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcOrderSetupService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalPayerId", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]],
      ["promoCode0", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalAuthorizationService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthorizationService"),
    :schema_element => [
      ["paypalOrderId", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcOrderSetupRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalDoRefTransactionRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalDoRefTransactionRequestToken", "SOAP::SOAPString", [0, 1]],
      ["paypalCustomerEmail", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalUpdateAgreementService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalUpdateAgreementService"),
    :schema_element => [
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementCustom", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalCreateAgreementService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreateAgreementService"),
    :schema_element => [
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestID", "SOAP::SOAPString", [0, 1]],
      ["paypalEcSetRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalDoRefTransactionService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoRefTransactionService"),
    :schema_element => [
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalReqconfirmshipping", "SOAP::SOAPString", [0, 1]],
      ["paypalReturnFmfDetails", "SOAP::SOAPString", [0, 1]],
      ["paypalSoftDescriptor", "SOAP::SOAPString", [0, 1]],
      ["paypalShippingdiscount", "SOAP::SOAPString", [0, 1]],
      ["paypalDesc", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]],
      ["paypalEcNotifyUrl", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::VoidService,
    :schema_type => XSD::QName.new(NsTransactionData167, "VoidService"),
    :schema_element => [
      ["voidRequestID", "SOAP::SOAPString", [0, 1]],
      ["voidRequestToken", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PinlessDebitService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitService"),
    :schema_element => [
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PinlessDebitValidateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitValidateService"),
    :schema_element => [],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PinlessDebitReversalService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitReversalService"),
    :schema_element => [
      ["pinlessDebitRequestID", "SOAP::SOAPString", [0, 1]],
      ["pinlessDebitRequestToken", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalButtonCreateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalButtonCreateService"),
    :schema_element => [
      ["buttonType", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedPaymentService"),
    :schema_element => [
      ["mpID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedUpdateService"),
    :schema_element => [
      ["mpID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ChinaPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaPaymentService"),
    :schema_element => [
      ["paymentMode", "SOAP::SOAPString", [0, 1]],
      ["returnURL", "SOAP::SOAPString", [0, 1]],
      ["pickUpAddress", "SOAP::SOAPString", [0, 1]],
      ["pickUpPhoneNumber", "SOAP::SOAPString", [0, 1]],
      ["pickUpPostalCode", "SOAP::SOAPString", [0, 1]],
      ["pickUpName", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ChinaRefundService,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaRefundService"),
    :schema_element => [
      ["chinaPaymentRequestID", "SOAP::SOAPString", [0, 1]],
      ["chinaPaymentRequestToken", "SOAP::SOAPString", [0, 1]],
      ["refundReason", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BoletoPaymentService,
    :schema_type => XSD::QName.new(NsTransactionData167, "BoletoPaymentService"),
    :schema_element => [
      ["instruction", "SOAP::SOAPString", [0, 1]],
      ["expirationDate", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Address,
    :schema_type => XSD::QName.new(NsTransactionData167, "Address"),
    :schema_element => [
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RiskUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "RiskUpdateService"),
    :schema_element => [
      ["actionCode", "SOAP::SOAPString", [0, 1]],
      ["recordID", "SOAP::SOAPString", [0, 1]],
      ["recordName", "SOAP::SOAPString", [0, 1]],
      ["negativeAddress", "CyberSource::Soap::Address", [0, 1]],
      ["markingReason", "SOAP::SOAPString", [0, 1]],
      ["markingNotes", "SOAP::SOAPString", [0, 1]],
      ["markingRequestID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FraudUpdateService,
    :schema_type => XSD::QName.new(NsTransactionData167, "FraudUpdateService"),
    :schema_element => [
      ["actionCode", "SOAP::SOAPString", [0, 1]],
      ["markedData", "SOAP::SOAPString", [0, 1]],
      ["markingReason", "SOAP::SOAPString", [0, 1]],
      ["markingNotes", "SOAP::SOAPString", [0, 1]],
      ["markingRequestID", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "run") => "SOAP::SOAPString"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::InvoiceHeader,
    :schema_type => XSD::QName.new(NsTransactionData167, "InvoiceHeader"),
    :schema_element => [
      ["merchantDescriptor", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorContact", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorAlternate", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorStreet", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorCity", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorState", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorPostalCode", "SOAP::SOAPString", [0, 1]],
      ["merchantDescriptorCountry", "SOAP::SOAPString", [0, 1]],
      ["isGift", nil, [0, 1]],
      ["returnsAccepted", nil, [0, 1]],
      ["tenderType", "SOAP::SOAPString", [0, 1]],
      ["merchantVATRegistrationNumber", "SOAP::SOAPString", [0, 1]],
      ["purchaserOrderDate", "SOAP::SOAPString", [0, 1]],
      ["purchaserVATRegistrationNumber", "SOAP::SOAPString", [0, 1]],
      ["vatInvoiceReferenceNumber", "SOAP::SOAPString", [0, 1]],
      ["summaryCommodityCode", "SOAP::SOAPString", [0, 1]],
      ["supplierOrderReference", "SOAP::SOAPString", [0, 1]],
      ["userPO", "SOAP::SOAPString", [0, 1]],
      ["costCenter", "SOAP::SOAPString", [0, 1]],
      ["purchaserCode", "SOAP::SOAPString", [0, 1]],
      ["taxable", nil, [0, 1]],
      ["amexDataTAA1", "SOAP::SOAPString", [0, 1]],
      ["amexDataTAA2", "SOAP::SOAPString", [0, 1]],
      ["amexDataTAA3", "SOAP::SOAPString", [0, 1]],
      ["amexDataTAA4", "SOAP::SOAPString", [0, 1]],
      ["invoiceDate", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BusinessRules,
    :schema_type => XSD::QName.new(NsTransactionData167, "BusinessRules"),
    :schema_element => [
      ["ignoreAVSResult", nil, [0, 1]],
      ["ignoreCVResult", nil, [0, 1]],
      ["ignoreDAVResult", nil, [0, 1]],
      ["ignoreExportResult", nil, [0, 1]],
      ["ignoreValidateResult", nil, [0, 1]],
      ["declineAVSFlags", "SOAP::SOAPString", [0, 1]],
      ["scoreThreshold", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BillTo,
    :schema_type => XSD::QName.new(NsTransactionData167, "BillTo"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["middleName", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["suffix", "SOAP::SOAPString", [0, 1]],
      ["buildingNumber", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["street3", "SOAP::SOAPString", [0, 1]],
      ["street4", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["company", "SOAP::SOAPString", [0, 1]],
      ["companyTaxID", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]],
      ["ipAddress", "SOAP::SOAPString", [0, 1]],
      ["customerPassword", "SOAP::SOAPString", [0, 1]],
      ["ipNetworkAddress", "SOAP::SOAPString", [0, 1]],
      ["hostname", "SOAP::SOAPString", [0, 1]],
      ["domainName", "SOAP::SOAPString", [0, 1]],
      ["dateOfBirth", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseNumber", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseState", "SOAP::SOAPString", [0, 1]],
      ["ssn", "SOAP::SOAPString", [0, 1]],
      ["customerID", "SOAP::SOAPString", [0, 1]],
      ["httpBrowserType", "SOAP::SOAPString", [0, 1]],
      ["httpBrowserEmail", "SOAP::SOAPString", [0, 1]],
      ["httpBrowserCookiesAccepted", nil, [0, 1]],
      ["nif", "SOAP::SOAPString", [0, 1]],
      ["personalID", "SOAP::SOAPString", [0, 1]],
      ["language", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ShipTo,
    :schema_type => XSD::QName.new(NsTransactionData167, "ShipTo"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["middleName", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["suffix", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["street3", "SOAP::SOAPString", [0, 1]],
      ["street4", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["company", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]],
      ["shippingMethod", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ShipFrom,
    :schema_type => XSD::QName.new(NsTransactionData167, "ShipFrom"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["middleName", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["suffix", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["street3", "SOAP::SOAPString", [0, 1]],
      ["street4", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["company", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Card,
    :schema_type => XSD::QName.new(NsTransactionData167, "Card"),
    :schema_element => [
      ["fullName", "SOAP::SOAPString", [0, 1]],
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["expirationMonth", "SOAP::SOAPInteger", [0, 1]],
      ["expirationYear", "SOAP::SOAPInteger", [0, 1]],
      ["cvIndicator", "SOAP::SOAPString", [0, 1]],
      ["cvNumber", "SOAP::SOAPString", [0, 1]],
      ["cardType", "SOAP::SOAPString", [0, 1]],
      ["issueNumber", "SOAP::SOAPString", [0, 1]],
      ["startMonth", "SOAP::SOAPInteger", [0, 1]],
      ["startYear", "SOAP::SOAPInteger", [0, 1]],
      ["pin", "SOAP::SOAPString", [0, 1]],
      ["accountEncoderID", "SOAP::SOAPString", [0, 1]],
      ["bin", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Check,
    :schema_type => XSD::QName.new(NsTransactionData167, "Check"),
    :schema_element => [
      ["fullName", "SOAP::SOAPString", [0, 1]],
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["accountType", "SOAP::SOAPString", [0, 1]],
      ["bankTransitNumber", "SOAP::SOAPString", [0, 1]],
      ["checkNumber", "SOAP::SOAPString", [0, 1]],
      ["secCode", "SOAP::SOAPString", [0, 1]],
      ["accountEncoderID", "SOAP::SOAPString", [0, 1]],
      ["authenticateID", "SOAP::SOAPString", [0, 1]],
      ["paymentInfo", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BML,
    :schema_type => XSD::QName.new(NsTransactionData167, "BML"),
    :schema_element => [
      ["customerBillingAddressChange", nil, [0, 1]],
      ["customerEmailChange", nil, [0, 1]],
      ["customerHasCheckingAccount", nil, [0, 1]],
      ["customerHasSavingsAccount", nil, [0, 1]],
      ["customerPasswordChange", nil, [0, 1]],
      ["customerPhoneChange", nil, [0, 1]],
      ["customerRegistrationDate", "SOAP::SOAPString", [0, 1]],
      ["customerTypeFlag", "SOAP::SOAPString", [0, 1]],
      ["grossHouseholdIncome", nil, [0, 1]],
      ["householdIncomeCurrency", "SOAP::SOAPString", [0, 1]],
      ["itemCategory", "SOAP::SOAPString", [0, 1]],
      ["merchantPromotionCode", "SOAP::SOAPString", [0, 1]],
      ["preapprovalNumber", "SOAP::SOAPString", [0, 1]],
      ["productDeliveryTypeIndicator", "SOAP::SOAPString", [0, 1]],
      ["residenceStatus", "SOAP::SOAPString", [0, 1]],
      ["tcVersion", "SOAP::SOAPString", [0, 1]],
      ["yearsAtCurrentResidence", "SOAP::SOAPInteger", [0, 1]],
      ["yearsWithCurrentEmployer", "SOAP::SOAPInteger", [0, 1]],
      ["employerStreet1", "SOAP::SOAPString", [0, 1]],
      ["employerStreet2", "SOAP::SOAPString", [0, 1]],
      ["employerCity", "SOAP::SOAPString", [0, 1]],
      ["employerCompanyName", "SOAP::SOAPString", [0, 1]],
      ["employerCountry", "SOAP::SOAPString", [0, 1]],
      ["employerPhoneNumber", "SOAP::SOAPString", [0, 1]],
      ["employerPhoneType", "SOAP::SOAPString", [0, 1]],
      ["employerState", "SOAP::SOAPString", [0, 1]],
      ["employerPostalCode", "SOAP::SOAPString", [0, 1]],
      ["shipToPhoneType", "SOAP::SOAPString", [0, 1]],
      ["billToPhoneType", "SOAP::SOAPString", [0, 1]],
      ["methodOfPayment", "SOAP::SOAPString", [0, 1]],
      ["productType", "SOAP::SOAPString", [0, 1]],
      ["customerAuthenticatedByMerchant", "SOAP::SOAPString", [0, 1]],
      ["backOfficeIndicator", "SOAP::SOAPString", [0, 1]],
      ["shipToEqualsBillToNameIndicator", "SOAP::SOAPString", [0, 1]],
      ["shipToEqualsBillToAddressIndicator", "SOAP::SOAPString", [0, 1]],
      ["alternateIPAddress", "SOAP::SOAPString", [0, 1]],
      ["businessLegalName", "SOAP::SOAPString", [0, 1]],
      ["dbaName", "SOAP::SOAPString", [0, 1]],
      ["businessAddress1", "SOAP::SOAPString", [0, 1]],
      ["businessAddress2", "SOAP::SOAPString", [0, 1]],
      ["businessCity", "SOAP::SOAPString", [0, 1]],
      ["businessState", "SOAP::SOAPString", [0, 1]],
      ["businessPostalCode", "SOAP::SOAPString", [0, 1]],
      ["businessCountry", "SOAP::SOAPString", [0, 1]],
      ["businessMainPhone", "SOAP::SOAPString", [0, 1]],
      ["userID", "SOAP::SOAPString", [0, 1]],
      ["pin", "SOAP::SOAPString", [0, 1]],
      ["adminLastName", "SOAP::SOAPString", [0, 1]],
      ["adminFirstName", "SOAP::SOAPString", [0, 1]],
      ["adminPhone", "SOAP::SOAPString", [0, 1]],
      ["adminFax", "SOAP::SOAPString", [0, 1]],
      ["adminEmailAddress", "SOAP::SOAPString", [0, 1]],
      ["adminTitle", "SOAP::SOAPString", [0, 1]],
      ["supervisorLastName", "SOAP::SOAPString", [0, 1]],
      ["supervisorFirstName", "SOAP::SOAPString", [0, 1]],
      ["supervisorEmailAddress", "SOAP::SOAPString", [0, 1]],
      ["businessDAndBNumber", "SOAP::SOAPString", [0, 1]],
      ["businessTaxID", "SOAP::SOAPString", [0, 1]],
      ["businessNAICSCode", "SOAP::SOAPString", [0, 1]],
      ["businessType", "SOAP::SOAPString", [0, 1]],
      ["businessYearsInBusiness", "SOAP::SOAPString", [0, 1]],
      ["businessNumberOfEmployees", "SOAP::SOAPString", [0, 1]],
      ["businessPONumber", "SOAP::SOAPString", [0, 1]],
      ["businessLoanType", "SOAP::SOAPString", [0, 1]],
      ["businessApplicationID", "SOAP::SOAPString", [0, 1]],
      ["businessProductCode", "SOAP::SOAPString", [0, 1]],
      ["pgLastName", "SOAP::SOAPString", [0, 1]],
      ["pgFirstName", "SOAP::SOAPString", [0, 1]],
      ["pgSSN", "SOAP::SOAPString", [0, 1]],
      ["pgDateOfBirth", "SOAP::SOAPString", [0, 1]],
      ["pgAnnualIncome", "SOAP::SOAPString", [0, 1]],
      ["pgIncomeCurrencyType", "SOAP::SOAPString", [0, 1]],
      ["pgResidenceStatus", "SOAP::SOAPString", [0, 1]],
      ["pgCheckingAccountIndicator", "SOAP::SOAPString", [0, 1]],
      ["pgSavingsAccountIndicator", "SOAP::SOAPString", [0, 1]],
      ["pgYearsAtEmployer", "SOAP::SOAPString", [0, 1]],
      ["pgYearsAtResidence", "SOAP::SOAPString", [0, 1]],
      ["pgHomeAddress1", "SOAP::SOAPString", [0, 1]],
      ["pgHomeAddress2", "SOAP::SOAPString", [0, 1]],
      ["pgHomeCity", "SOAP::SOAPString", [0, 1]],
      ["pgHomeState", "SOAP::SOAPString", [0, 1]],
      ["pgHomePostalCode", "SOAP::SOAPString", [0, 1]],
      ["pgHomeCountry", "SOAP::SOAPString", [0, 1]],
      ["pgEmailAddress", "SOAP::SOAPString", [0, 1]],
      ["pgHomePhone", "SOAP::SOAPString", [0, 1]],
      ["pgTitle", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::OtherTax,
    :schema_type => XSD::QName.new(NsTransactionData167, "OtherTax"),
    :schema_element => [
      ["vatTaxAmount", nil, [0, 1]],
      ["vatTaxRate", nil, [0, 1]],
      ["alternateTaxAmount", nil, [0, 1]],
      ["alternateTaxIndicator", nil, [0, 1]],
      ["alternateTaxID", "SOAP::SOAPString", [0, 1]],
      ["localTaxAmount", nil, [0, 1]],
      ["localTaxIndicator", "SOAP::SOAPInteger", [0, 1]],
      ["nationalTaxAmount", nil, [0, 1]],
      ["nationalTaxIndicator", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PurchaseTotals,
    :schema_type => XSD::QName.new(NsTransactionData167, "PurchaseTotals"),
    :schema_element => [
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["discountAmount", nil, [0, 1]],
      ["taxAmount", nil, [0, 1]],
      ["dutyAmount", nil, [0, 1]],
      ["grandTotalAmount", nil, [0, 1]],
      ["freightAmount", nil, [0, 1]],
      ["foreignAmount", nil, [0, 1]],
      ["foreignCurrency", "SOAP::SOAPString", [0, 1]],
      ["exchangeRate", nil, [0, 1]],
      ["exchangeRateTimeStamp", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FundingTotals,
    :schema_type => XSD::QName.new(NsTransactionData167, "FundingTotals"),
    :schema_element => [
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["grandTotalAmount", nil, [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::GECC,
    :schema_type => XSD::QName.new(NsTransactionData167, "GECC"),
    :schema_element => [
      ["saleType", "SOAP::SOAPString", [0, 1]],
      ["planNumber", "SOAP::SOAPString", [0, 1]],
      ["sequenceNumber", "SOAP::SOAPString", [0, 1]],
      ["promotionEndDate", "SOAP::SOAPString", [0, 1]],
      ["promotionPlan", "SOAP::SOAPString", [0, 1]],
      ["line", "SOAP::SOAPString[]", [0, 7]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::UCAF,
    :schema_type => XSD::QName.new(NsTransactionData167, "UCAF"),
    :schema_element => [
      ["authenticationData", "SOAP::SOAPString", [0, 1]],
      ["collectionIndicator", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FundTransfer,
    :schema_type => XSD::QName.new(NsTransactionData167, "FundTransfer"),
    :schema_element => [
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["accountName", "SOAP::SOAPString", [0, 1]],
      ["bankCheckDigit", "SOAP::SOAPString", [0, 1]],
      ["iban", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankInfo,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankInfo"),
    :schema_element => [
      ["bankCode", "SOAP::SOAPString", [0, 1]],
      ["name", "SOAP::SOAPString", [0, 1]],
      ["address", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["branchCode", "SOAP::SOAPString", [0, 1]],
      ["swiftCode", "SOAP::SOAPString", [0, 1]],
      ["sortCode", "SOAP::SOAPString", [0, 1]],
      ["issuerID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RecurringSubscriptionInfo,
    :schema_type => XSD::QName.new(NsTransactionData167, "RecurringSubscriptionInfo"),
    :schema_element => [
      ["subscriptionID", "SOAP::SOAPString", [0, 1]],
      ["status", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]],
      ["numberOfPayments", "SOAP::SOAPInteger", [0, 1]],
      ["numberOfPaymentsToAdd", "SOAP::SOAPInteger", [0, 1]],
      ["automaticRenew", nil, [0, 1]],
      ["frequency", "SOAP::SOAPString", [0, 1]],
      ["startDate", "SOAP::SOAPString", [0, 1]],
      ["endDate", "SOAP::SOAPString", [0, 1]],
      ["approvalRequired", nil, [0, 1]],
      ["event", "CyberSource::Soap::PaySubscriptionEvent", [0, 1]],
      ["billPayment", nil, [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionEvent,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionEvent"),
    :schema_element => [
      ["amount", nil, [0, 1]],
      ["approvedBy", "SOAP::SOAPString", [0, 1]],
      ["number", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Subscription,
    :schema_type => XSD::QName.new(NsTransactionData167, "Subscription"),
    :schema_element => [
      ["title", "SOAP::SOAPString", [0, 1]],
      ["paymentMethod", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DecisionManager,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionManager"),
    :schema_element => [
      ["enabled", nil, [0, 1]],
      ["profile", "SOAP::SOAPString", [0, 1]],
      ["travelData", "CyberSource::Soap::DecisionManagerTravelData", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DecisionManagerTravelData,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionManagerTravelData"),
    :schema_element => [
      ["leg", "CyberSource::Soap::DecisionManagerTravelLeg[]", [0, nil]],
      ["departureDateTime", nil, [0, 1]],
      ["completeRoute", "SOAP::SOAPString", [0, 1]],
      ["journeyType", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DecisionManagerTravelLeg,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionManagerTravelLeg"),
    :schema_element => [
      ["origin", "SOAP::SOAPString", [0, 1]],
      ["destination", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Batch,
    :schema_type => XSD::QName.new(NsTransactionData167, "Batch"),
    :schema_element => [
      ["batchID", "SOAP::SOAPString", [0, 1]],
      ["recordID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPal,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPal"),
    :schema_element => [
      ["any", [nil, XSD::QName.new(NsXMLSchema, "anyType")]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::JPO,
    :schema_type => XSD::QName.new(NsTransactionData167, "JPO"),
    :schema_element => [
      ["paymentMethod", "SOAP::SOAPInteger", [0, 1]],
      ["bonusAmount", nil, [0, 1]],
      ["bonuses", "SOAP::SOAPInteger", [0, 1]],
      ["installments", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RequestMessage,
    :schema_type => XSD::QName.new(NsTransactionData167, "RequestMessage"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString", [0, 1]],
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["debtIndicator", nil, [0, 1]],
      ["clientLibrary", "SOAP::SOAPString", [0, 1]],
      ["clientLibraryVersion", "SOAP::SOAPString", [0, 1]],
      ["clientEnvironment", "SOAP::SOAPString", [0, 1]],
      ["clientSecurityLibraryVersion", "SOAP::SOAPString", [0, 1]],
      ["clientApplication", "SOAP::SOAPString", [0, 1]],
      ["clientApplicationVersion", "SOAP::SOAPString", [0, 1]],
      ["clientApplicationUser", "SOAP::SOAPString", [0, 1]],
      ["routingCode", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["returnURL", "SOAP::SOAPString", [0, 1]],
      ["invoiceHeader", "CyberSource::Soap::InvoiceHeader", [0, 1]],
      ["billTo", "CyberSource::Soap::BillTo", [0, 1]],
      ["shipTo", "CyberSource::Soap::ShipTo", [0, 1]],
      ["shipFrom", "CyberSource::Soap::ShipFrom", [0, 1]],
      ["item", "CyberSource::Soap::Item[]", [0, nil]],
      ["purchaseTotals", "CyberSource::Soap::PurchaseTotals", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["dcc", "CyberSource::Soap::DCC", [0, 1]],
      ["pos", "CyberSource::Soap::Pos", [0, 1]],
      ["installment", "CyberSource::Soap::Installment", [0, 1]],
      ["card", "CyberSource::Soap::Card", [0, 1]],
      ["check", "CyberSource::Soap::Check", [0, 1]],
      ["bml", "CyberSource::Soap::BML", [0, 1]],
      ["gecc", "CyberSource::Soap::GECC", [0, 1]],
      ["ucaf", "CyberSource::Soap::UCAF", [0, 1]],
      ["fundTransfer", "CyberSource::Soap::FundTransfer", [0, 1]],
      ["bankInfo", "CyberSource::Soap::BankInfo", [0, 1]],
      ["subscription", "CyberSource::Soap::Subscription", [0, 1]],
      ["recurringSubscriptionInfo", "CyberSource::Soap::RecurringSubscriptionInfo", [0, 1]],
      ["decisionManager", "CyberSource::Soap::DecisionManager", [0, 1]],
      ["otherTax", "CyberSource::Soap::OtherTax", [0, 1]],
      ["paypal", "CyberSource::Soap::PayPal", [0, 1]],
      ["merchantDefinedData", "CyberSource::Soap::MerchantDefinedData", [0, 1]],
      ["merchantSecureData", "CyberSource::Soap::MerchantSecureData", [0, 1]],
      ["jpo", "CyberSource::Soap::JPO", [0, 1]],
      ["orderRequestToken", "SOAP::SOAPString", [0, 1]],
      ["linkToRequest", "SOAP::SOAPString", [0, 1]],
      ["ccAuthService", "CyberSource::Soap::CCAuthService", [0, 1]],
      ["ccCaptureService", "CyberSource::Soap::CCCaptureService", [0, 1]],
      ["ccCreditService", "CyberSource::Soap::CCCreditService", [0, 1]],
      ["ccAuthReversalService", "CyberSource::Soap::CCAuthReversalService", [0, 1]],
      ["ccAutoAuthReversalService", "CyberSource::Soap::CCAutoAuthReversalService", [0, 1]],
      ["ccDCCService", "CyberSource::Soap::CCDCCService", [0, 1]],
      ["ecDebitService", "CyberSource::Soap::ECDebitService", [0, 1]],
      ["ecCreditService", "CyberSource::Soap::ECCreditService", [0, 1]],
      ["ecAuthenticateService", "CyberSource::Soap::ECAuthenticateService", [0, 1]],
      ["payerAuthEnrollService", "CyberSource::Soap::PayerAuthEnrollService", [0, 1]],
      ["payerAuthValidateService", "CyberSource::Soap::PayerAuthValidateService", [0, 1]],
      ["taxService", "CyberSource::Soap::TaxService", [0, 1]],
      ["afsService", "CyberSource::Soap::AFSService", [0, 1]],
      ["davService", "CyberSource::Soap::DAVService", [0, 1]],
      ["exportService", "CyberSource::Soap::ExportService", [0, 1]],
      ["fxRatesService", "CyberSource::Soap::FXRatesService", [0, 1]],
      ["bankTransferService", "CyberSource::Soap::BankTransferService", [0, 1]],
      ["bankTransferRefundService", "CyberSource::Soap::BankTransferRefundService", [0, 1]],
      ["bankTransferRealTimeService", "CyberSource::Soap::BankTransferRealTimeService", [0, 1]],
      ["directDebitMandateService", "CyberSource::Soap::DirectDebitMandateService", [0, 1]],
      ["directDebitService", "CyberSource::Soap::DirectDebitService", [0, 1]],
      ["directDebitRefundService", "CyberSource::Soap::DirectDebitRefundService", [0, 1]],
      ["directDebitValidateService", "CyberSource::Soap::DirectDebitValidateService", [0, 1]],
      ["paySubscriptionCreateService", "CyberSource::Soap::PaySubscriptionCreateService", [0, 1]],
      ["paySubscriptionUpdateService", "CyberSource::Soap::PaySubscriptionUpdateService", [0, 1]],
      ["paySubscriptionEventUpdateService", "CyberSource::Soap::PaySubscriptionEventUpdateService", [0, 1]],
      ["paySubscriptionRetrieveService", "CyberSource::Soap::PaySubscriptionRetrieveService", [0, 1]],
      ["paySubscriptionDeleteService", "CyberSource::Soap::PaySubscriptionDeleteService", [0, 1]],
      ["payPalPaymentService", "CyberSource::Soap::PayPalPaymentService", [0, 1]],
      ["payPalCreditService", "CyberSource::Soap::PayPalCreditService", [0, 1]],
      ["voidService", "CyberSource::Soap::VoidService", [0, 1]],
      ["businessRules", "CyberSource::Soap::BusinessRules", [0, 1]],
      ["pinlessDebitService", "CyberSource::Soap::PinlessDebitService", [0, 1]],
      ["pinlessDebitValidateService", "CyberSource::Soap::PinlessDebitValidateService", [0, 1]],
      ["pinlessDebitReversalService", "CyberSource::Soap::PinlessDebitReversalService", [0, 1]],
      ["batch", "CyberSource::Soap::Batch", [0, 1]],
      ["airlineData", "CyberSource::Soap::AirlineData", [0, 1]],
      ["payPalButtonCreateService", "CyberSource::Soap::PayPalButtonCreateService", [0, 1]],
      ["payPalPreapprovedPaymentService", "CyberSource::Soap::PayPalPreapprovedPaymentService", [0, 1]],
      ["payPalPreapprovedUpdateService", "CyberSource::Soap::PayPalPreapprovedUpdateService", [0, 1]],
      ["riskUpdateService", "CyberSource::Soap::RiskUpdateService", [0, 1]],
      ["fraudUpdateService", "CyberSource::Soap::FraudUpdateService", [0, 1]],
      ["reserved", "CyberSource::Soap::RequestReserved[]", [0, nil]],
      ["deviceFingerprintID", "SOAP::SOAPString", [0, 1]],
      ["payPalRefundService", "CyberSource::Soap::PayPalRefundService", [0, 1]],
      ["payPalAuthReversalService", "CyberSource::Soap::PayPalAuthReversalService", [0, 1]],
      ["payPalDoCaptureService", "CyberSource::Soap::PayPalDoCaptureService", [0, 1]],
      ["payPalEcDoPaymentService", "CyberSource::Soap::PayPalEcDoPaymentService", [0, 1]],
      ["payPalEcGetDetailsService", "CyberSource::Soap::PayPalEcGetDetailsService", [0, 1]],
      ["payPalEcSetService", "CyberSource::Soap::PayPalEcSetService", [0, 1]],
      ["payPalEcOrderSetupService", "CyberSource::Soap::PayPalEcOrderSetupService", [0, 1]],
      ["payPalAuthorizationService", "CyberSource::Soap::PayPalAuthorizationService", [0, 1]],
      ["payPalUpdateAgreementService", "CyberSource::Soap::PayPalUpdateAgreementService", [0, 1]],
      ["payPalCreateAgreementService", "CyberSource::Soap::PayPalCreateAgreementService", [0, 1]],
      ["payPalDoRefTransactionService", "CyberSource::Soap::PayPalDoRefTransactionService", [0, 1]],
      ["chinaPaymentService", "CyberSource::Soap::ChinaPaymentService", [0, 1]],
      ["chinaRefundService", "CyberSource::Soap::ChinaRefundService", [0, 1]],
      ["boletoPaymentService", "CyberSource::Soap::BoletoPaymentService", [0, 1]],
      ["ignoreCardExpiration", nil, [0, 1]],
      ["reportGroup", "SOAP::SOAPString", [0, 1]],
      ["processorID", "SOAP::SOAPString", [0, 1]],
      ["solutionProviderTransactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DCC,
    :schema_type => XSD::QName.new(NsTransactionData167, "DCC"),
    :schema_element => [
      ["dccIndicator", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCAuthReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["authorizationCode", "SOAP::SOAPString", [0, 1]],
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["avsCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["cvCode", "SOAP::SOAPString", [0, 1]],
      ["cvCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["personalIDCode", "SOAP::SOAPString", [0, 1]],
      ["authorizedDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["bmlAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["authFactorCode", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["fxQuoteID", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteRate", nil, [0, 1]],
      ["fxQuoteType", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteExpirationDateTime", nil, [0, 1]],
      ["authRecord", "SOAP::SOAPString", [0, 1]],
      ["merchantAdviceCode", "SOAP::SOAPString", [0, 1]],
      ["merchantAdviceCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["cavvResponseCode", "SOAP::SOAPString", [0, 1]],
      ["cavvResponseCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["authenticationXID", "SOAP::SOAPString", [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["processorCardType", "SOAP::SOAPString", [0, 1]],
      ["accountBalance", nil, [0, 1]],
      ["forwardCode", "SOAP::SOAPString", [0, 1]],
      ["enhancedDataEnabled", "SOAP::SOAPString", [0, 1]],
      ["referralResponseNumber", "SOAP::SOAPString", [0, 1]],
      ["subResponseCode", "SOAP::SOAPString", [0, 1]],
      ["approvedAmount", "SOAP::SOAPString", [0, 1]],
      ["creditLine", "SOAP::SOAPString", [0, 1]],
      ["approvedTerms", "SOAP::SOAPString", [0, 1]],
      ["paymentNetworkTransactionID", "SOAP::SOAPString", [0, 1]],
      ["cardCategory", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]],
      ["requestAmount", nil, [0, 1]],
      ["requestCurrency", "SOAP::SOAPString", [0, 1]],
      ["accountBalanceCurrency", "SOAP::SOAPString", [0, 1]],
      ["accountBalanceSign", "SOAP::SOAPString", [0, 1]],
      ["affluenceIndicator", "SOAP::SOAPString", [0, 1]],
      ["evEmail", "SOAP::SOAPString", [0, 1]],
      ["evPhoneNumber", "SOAP::SOAPString", [0, 1]],
      ["evPostalCode", "SOAP::SOAPString", [0, 1]],
      ["evName", "SOAP::SOAPString", [0, 1]],
      ["evStreet", "SOAP::SOAPString", [0, 1]],
      ["evEmailRaw", "SOAP::SOAPString", [0, 1]],
      ["evPhoneNumberRaw", "SOAP::SOAPString", [0, 1]],
      ["evPostalCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["evNameRaw", "SOAP::SOAPString", [0, 1]],
      ["evStreetRaw", "SOAP::SOAPString", [0, 1]],
      ["cardGroup", "SOAP::SOAPString", [0, 1]],
      ["posData", "SOAP::SOAPString", [0, 1]],
      ["transactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCCaptureReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCaptureReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["fxQuoteID", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteRate", nil, [0, 1]],
      ["fxQuoteType", "SOAP::SOAPString", [0, 1]],
      ["fxQuoteExpirationDateTime", nil, [0, 1]],
      ["purchasingLevel3Enabled", "SOAP::SOAPString", [0, 1]],
      ["enhancedDataEnabled", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCCreditReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCCreditReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["purchasingLevel3Enabled", "SOAP::SOAPString", [0, 1]],
      ["enhancedDataEnabled", "SOAP::SOAPString", [0, 1]],
      ["authorizationXID", "SOAP::SOAPString", [0, 1]],
      ["forwardCode", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCAuthReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAuthReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["authorizationCode", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["forwardCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCAutoAuthReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCAutoAuthReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["result", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ECDebitReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECDebitReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["verificationLevel", "SOAP::SOAPInteger", [0, 1]],
      ["processorTransactionID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["avsCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["verificationCode", "SOAP::SOAPString", [0, 1]],
      ["verificationCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["correctedAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["correctedRoutingNumber", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ECCreditReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECCreditReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["settlementMethod", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["processorTransactionID", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["verificationCode", "SOAP::SOAPString", [0, 1]],
      ["verificationCodeRaw", "SOAP::SOAPString", [0, 1]],
      ["correctedAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["correctedRoutingNumber", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ECAuthenticateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ECAuthenticateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["checkpointSummary", "SOAP::SOAPString", [0, 1]],
      ["fraudShieldIndicators", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayerAuthEnrollReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthEnrollReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["acsURL", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["eci", "SOAP::SOAPString", [0, 1]],
      ["paReq", "SOAP::SOAPString", [0, 1]],
      ["proxyPAN", "SOAP::SOAPString", [0, 1]],
      ["xid", "SOAP::SOAPString", [0, 1]],
      ["proofXML", "SOAP::SOAPString", [0, 1]],
      ["ucafCollectionIndicator", "SOAP::SOAPString", [0, 1]],
      ["veresEnrolled", "SOAP::SOAPString", [0, 1]],
      ["authenticationPath", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayerAuthValidateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayerAuthValidateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["authenticationResult", "SOAP::SOAPString", [0, 1]],
      ["authenticationStatusMessage", "SOAP::SOAPString", [0, 1]],
      ["cavv", "SOAP::SOAPString", [0, 1]],
      ["cavvAlgorithm", "SOAP::SOAPString", [0, 1]],
      ["commerceIndicator", "SOAP::SOAPString", [0, 1]],
      ["eci", "SOAP::SOAPString", [0, 1]],
      ["eciRaw", "SOAP::SOAPString", [0, 1]],
      ["xid", "SOAP::SOAPString", [0, 1]],
      ["ucafAuthenticationData", "SOAP::SOAPString", [0, 1]],
      ["ucafCollectionIndicator", "SOAP::SOAPString", [0, 1]],
      ["paresStatus", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::TaxReplyItem,
    :schema_type => XSD::QName.new(NsTransactionData167, "TaxReplyItem"),
    :schema_element => [
      ["cityTaxAmount", nil, [0, 1]],
      ["countyTaxAmount", nil, [0, 1]],
      ["districtTaxAmount", nil, [0, 1]],
      ["stateTaxAmount", nil, [0, 1]],
      ["totalTaxAmount", nil]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::TaxReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "TaxReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["grandTotalAmount", nil, [0, 1]],
      ["totalCityTaxAmount", nil, [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["totalCountyTaxAmount", nil, [0, 1]],
      ["county", "SOAP::SOAPString", [0, 1]],
      ["totalDistrictTaxAmount", nil, [0, 1]],
      ["totalStateTaxAmount", nil, [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["totalTaxAmount", nil, [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["geocode", "SOAP::SOAPString", [0, 1]],
      ["item", "CyberSource::Soap::TaxReplyItem[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DeviceFingerprint,
    :schema_type => XSD::QName.new(NsTransactionData167, "DeviceFingerprint"),
    :schema_element => [
      ["cookiesEnabled", nil, [0, 1]],
      ["flashEnabled", nil, [0, 1]],
      ["hash", "SOAP::SOAPString", [0, 1]],
      ["imagesEnabled", nil, [0, 1]],
      ["javascriptEnabled", nil, [0, 1]],
      ["proxyIPAddress", "SOAP::SOAPString", [0, 1]],
      ["proxyIPAddressActivities", "SOAP::SOAPString", [0, 1]],
      ["proxyIPAddressAttributes", "SOAP::SOAPString", [0, 1]],
      ["proxyServerType", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddress", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressActivities", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressAttributes", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressCity", "SOAP::SOAPString", [0, 1]],
      ["trueIPAddressCountry", "SOAP::SOAPString", [0, 1]],
      ["smartID", "SOAP::SOAPString", [0, 1]],
      ["smartIDConfidenceLevel", "SOAP::SOAPString", [0, 1]],
      ["screenResolution", "SOAP::SOAPString", [0, 1]],
      ["browserLanguage", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::AFSReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "AFSReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["afsResult", "SOAP::SOAPInteger", [0, 1]],
      ["hostSeverity", "SOAP::SOAPInteger", [0, 1]],
      ["consumerLocalTime", "SOAP::SOAPString", [0, 1]],
      ["afsFactorCode", "SOAP::SOAPString", [0, 1]],
      ["addressInfoCode", "SOAP::SOAPString", [0, 1]],
      ["hotlistInfoCode", "SOAP::SOAPString", [0, 1]],
      ["internetInfoCode", "SOAP::SOAPString", [0, 1]],
      ["phoneInfoCode", "SOAP::SOAPString", [0, 1]],
      ["suspiciousInfoCode", "SOAP::SOAPString", [0, 1]],
      ["velocityInfoCode", "SOAP::SOAPString", [0, 1]],
      ["identityInfoCode", "SOAP::SOAPString", [0, 1]],
      ["ipCountry", "SOAP::SOAPString", [0, 1]],
      ["ipState", "SOAP::SOAPString", [0, 1]],
      ["ipCity", "SOAP::SOAPString", [0, 1]],
      ["ipRoutingMethod", "SOAP::SOAPString", [0, 1]],
      ["scoreModelUsed", "SOAP::SOAPString", [0, 1]],
      ["binCountry", "SOAP::SOAPString", [0, 1]],
      ["cardAccountType", "SOAP::SOAPString", [0, 1]],
      ["cardScheme", "SOAP::SOAPString", [0, 1]],
      ["cardIssuer", "SOAP::SOAPString", [0, 1]],
      ["deviceFingerprint", "CyberSource::Soap::DeviceFingerprint", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DAVReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DAVReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["addressType", "SOAP::SOAPString", [0, 1]],
      ["apartmentInfo", "SOAP::SOAPString", [0, 1]],
      ["barCode", "SOAP::SOAPString", [0, 1]],
      ["barCodeCheckDigit", "SOAP::SOAPString", [0, 1]],
      ["careOf", "SOAP::SOAPString", [0, 1]],
      ["cityInfo", "SOAP::SOAPString", [0, 1]],
      ["countryInfo", "SOAP::SOAPString", [0, 1]],
      ["directionalInfo", "SOAP::SOAPString", [0, 1]],
      ["lvrInfo", "SOAP::SOAPString", [0, 1]],
      ["matchScore", "SOAP::SOAPInteger", [0, 1]],
      ["standardizedAddress1", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddress2", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddress3", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddress4", "SOAP::SOAPString", [0, 1]],
      ["standardizedAddressNoApt", "SOAP::SOAPString", [0, 1]],
      ["standardizedCity", "SOAP::SOAPString", [0, 1]],
      ["standardizedCounty", "SOAP::SOAPString", [0, 1]],
      ["standardizedCSP", "SOAP::SOAPString", [0, 1]],
      ["standardizedState", "SOAP::SOAPString", [0, 1]],
      ["standardizedPostalCode", "SOAP::SOAPString", [0, 1]],
      ["standardizedCountry", "SOAP::SOAPString", [0, 1]],
      ["standardizedISOCountry", "SOAP::SOAPString", [0, 1]],
      ["stateInfo", "SOAP::SOAPString", [0, 1]],
      ["streetInfo", "SOAP::SOAPString", [0, 1]],
      ["suffixInfo", "SOAP::SOAPString", [0, 1]],
      ["postalCodeInfo", "SOAP::SOAPString", [0, 1]],
      ["overallInfo", "SOAP::SOAPString", [0, 1]],
      ["usInfo", "SOAP::SOAPString", [0, 1]],
      ["caInfo", "SOAP::SOAPString", [0, 1]],
      ["intlInfo", "SOAP::SOAPString", [0, 1]],
      ["usErrorInfo", "SOAP::SOAPString", [0, 1]],
      ["caErrorInfo", "SOAP::SOAPString", [0, 1]],
      ["intlErrorInfo", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DeniedPartiesMatch,
    :schema_type => XSD::QName.new(NsTransactionData167, "DeniedPartiesMatch"),
    :schema_element => [
      ["list", "SOAP::SOAPString", [0, 1]],
      ["name", "SOAP::SOAPString[]", [0, nil]],
      ["address", "SOAP::SOAPString[]", [0, nil]],
      ["program", "SOAP::SOAPString[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ExportReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ExportReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["ipCountryConfidence", "SOAP::SOAPInteger", [0, 1]],
      ["infoCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FXQuote,
    :schema_type => XSD::QName.new(NsTransactionData167, "FXQuote"),
    :schema_element => [
      ["id", "SOAP::SOAPString", [0, 1]],
      ["rate", "SOAP::SOAPString", [0, 1]],
      ["type", "SOAP::SOAPString", [0, 1]],
      ["expirationDateTime", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["fundingCurrency", "SOAP::SOAPString", [0, 1]],
      ["receivedDateTime", nil, [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FXRatesReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "FXRatesReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["quote", "CyberSource::Soap::FXQuote[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankTransferReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["accountHolder", "SOAP::SOAPString", [0, 1]],
      ["accountNumber", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]],
      ["bankName", "SOAP::SOAPString", [0, 1]],
      ["bankCity", "SOAP::SOAPString", [0, 1]],
      ["bankCountry", "SOAP::SOAPString", [0, 1]],
      ["paymentReference", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["bankSwiftCode", "SOAP::SOAPString", [0, 1]],
      ["bankSpecialID", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["iban", "SOAP::SOAPString", [0, 1]],
      ["bankCode", "SOAP::SOAPString", [0, 1]],
      ["branchCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankTransferRealTimeReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRealTimeReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["formMethod", "SOAP::SOAPString", [0, 1]],
      ["formAction", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["paymentReference", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitMandateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitMandateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["mandateID", "SOAP::SOAPString", [0, 1]],
      ["mandateMaturationDate", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BankTransferRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BankTransferRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitValidateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitValidateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DirectDebitRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DirectDebitRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionCreateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionCreateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["subscriptionID", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["subscriptionID", "SOAP::SOAPString"],
      ["subscriptionIDNew", "SOAP::SOAPString"],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionEventUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionEventUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionRetrieveReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionRetrieveReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["approvalRequired", "SOAP::SOAPString", [0, 1]],
      ["automaticRenew", "SOAP::SOAPString", [0, 1]],
      ["cardAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["cardExpirationMonth", "SOAP::SOAPString", [0, 1]],
      ["cardExpirationYear", "SOAP::SOAPString", [0, 1]],
      ["cardIssueNumber", "SOAP::SOAPString", [0, 1]],
      ["cardStartMonth", "SOAP::SOAPString", [0, 1]],
      ["cardStartYear", "SOAP::SOAPString", [0, 1]],
      ["cardType", "SOAP::SOAPString", [0, 1]],
      ["checkAccountNumber", "SOAP::SOAPString", [0, 1]],
      ["checkAccountType", "SOAP::SOAPString", [0, 1]],
      ["checkBankTransitNumber", "SOAP::SOAPString", [0, 1]],
      ["checkSecCode", "SOAP::SOAPString", [0, 1]],
      ["checkAuthenticateID", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["companyName", "SOAP::SOAPString", [0, 1]],
      ["country", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["customerAccountID", "SOAP::SOAPString", [0, 1]],
      ["email", "SOAP::SOAPString", [0, 1]],
      ["endDate", "SOAP::SOAPString", [0, 1]],
      ["firstName", "SOAP::SOAPString", [0, 1]],
      ["frequency", "SOAP::SOAPString", [0, 1]],
      ["lastName", "SOAP::SOAPString", [0, 1]],
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["paymentMethod", "SOAP::SOAPString", [0, 1]],
      ["paymentsRemaining", "SOAP::SOAPString", [0, 1]],
      ["phoneNumber", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["recurringAmount", "SOAP::SOAPString", [0, 1]],
      ["setupAmount", "SOAP::SOAPString", [0, 1]],
      ["startDate", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["status", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["subscriptionID", "SOAP::SOAPString", [0, 1]],
      ["subscriptionIDNew", "SOAP::SOAPString"],
      ["title", "SOAP::SOAPString", [0, 1]],
      ["totalPayments", "SOAP::SOAPString", [0, 1]],
      ["shipToFirstName", "SOAP::SOAPString", [0, 1]],
      ["shipToLastName", "SOAP::SOAPString", [0, 1]],
      ["shipToStreet1", "SOAP::SOAPString", [0, 1]],
      ["shipToStreet2", "SOAP::SOAPString", [0, 1]],
      ["shipToCity", "SOAP::SOAPString", [0, 1]],
      ["shipToState", "SOAP::SOAPString", [0, 1]],
      ["shipToPostalCode", "SOAP::SOAPString", [0, 1]],
      ["shipToCompany", "SOAP::SOAPString", [0, 1]],
      ["shipToCountry", "SOAP::SOAPString", [0, 1]],
      ["billPayment", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField1", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField2", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField3", "SOAP::SOAPString", [0, 1]],
      ["merchantDefinedDataField4", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField1", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField2", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField3", "SOAP::SOAPString", [0, 1]],
      ["merchantSecureDataField4", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]],
      ["companyTaxID", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseNumber", "SOAP::SOAPString", [0, 1]],
      ["driversLicenseState", "SOAP::SOAPString", [0, 1]],
      ["dateOfBirth", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PaySubscriptionDeleteReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PaySubscriptionDeleteReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["subscriptionID", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["secureData", "SOAP::SOAPString", [0, 1]],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalCreditReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreditReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::VoidReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "VoidReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PinlessDebitReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["authorizationCode", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["receiptNumber", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["ownerMerchantID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PinlessDebitValidateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitValidateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["status", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PinlessDebitReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PinlessDebitReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["amount", nil, [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["processorResponse", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalButtonCreateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalButtonCreateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["encryptedFormData", "SOAP::SOAPString", [0, 1]],
      ["unencryptedFormData", "SOAP::SOAPString", [0, 1]],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["buttonType", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerName", "SOAP::SOAPString", [0, 1]],
      ["transactionType", "SOAP::SOAPString", [0, 1]],
      ["feeAmount", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["pendingReason", "SOAP::SOAPString", [0, 1]],
      ["paymentStatus", "SOAP::SOAPString", [0, 1]],
      ["mpStatus", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerID", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["transactionID", "SOAP::SOAPString", [0, 1]],
      ["desc", "SOAP::SOAPString", [0, 1]],
      ["mpMax", "SOAP::SOAPString", [0, 1]],
      ["paymentType", "SOAP::SOAPString", [0, 1]],
      ["paymentDate", "SOAP::SOAPString", [0, 1]],
      ["paymentGrossAmount", "SOAP::SOAPString", [0, 1]],
      ["settleAmount", "SOAP::SOAPString", [0, 1]],
      ["taxAmount", "SOAP::SOAPString", [0, 1]],
      ["exchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paymentSourceID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalPreapprovedUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalPreapprovedUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerName", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["mpStatus", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerID", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["desc", "SOAP::SOAPString", [0, 1]],
      ["mpMax", "SOAP::SOAPString", [0, 1]],
      ["paymentSourceID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcSetReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcSetReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcGetDetailsReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcGetDetailsReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerId", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerSalutation", "SOAP::SOAPString", [0, 1]],
      ["payerFirstname", "SOAP::SOAPString", [0, 1]],
      ["payerMiddlename", "SOAP::SOAPString", [0, 1]],
      ["payerLastname", "SOAP::SOAPString", [0, 1]],
      ["payerSuffix", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["shipToName", "SOAP::SOAPString", [0, 1]],
      ["shipToAddress1", "SOAP::SOAPString", [0, 1]],
      ["shipToAddress2", "SOAP::SOAPString", [0, 1]],
      ["shipToCity", "SOAP::SOAPString", [0, 1]],
      ["shipToState", "SOAP::SOAPString", [0, 1]],
      ["shipToCountry", "SOAP::SOAPString", [0, 1]],
      ["shipToZip", "SOAP::SOAPString", [0, 1]],
      ["addressStatus", "SOAP::SOAPString", [0, 1]],
      ["payerPhone", "SOAP::SOAPString", [0, 1]],
      ["avsCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["street1", "SOAP::SOAPString", [0, 1]],
      ["street2", "SOAP::SOAPString", [0, 1]],
      ["city", "SOAP::SOAPString", [0, 1]],
      ["state", "SOAP::SOAPString", [0, 1]],
      ["postalCode", "SOAP::SOAPString", [0, 1]],
      ["countryCode", "SOAP::SOAPString", [0, 1]],
      ["countryName", "SOAP::SOAPString", [0, 1]],
      ["addressID", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementAcceptedStatus", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcDoPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcDoPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactiontype", "SOAP::SOAPString", [0, 1]],
      ["paymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalPendingReason", "SOAP::SOAPString", [0, 1]],
      ["orderId", "SOAP::SOAPString", [0, 1]],
      ["paypalReasonCode", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalDoCaptureReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoCaptureReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["authorizationId", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["parentTransactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalReceiptId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactiontype", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentGrossAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalAuthReversalReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthReversalReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["authorizationId", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalNetRefundAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeRefundAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalGrossRefundAmount", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalEcOrderSetupReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalEcOrderSetupReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalToken", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactiontype", "SOAP::SOAPString", [0, 1]],
      ["paymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalFeeAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalPendingReason", "SOAP::SOAPString", [0, 1]],
      ["paypalReasonCode", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalAuthorizationReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalAuthorizationReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["protectionEligibility", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalUpdateAgreementReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalUpdateAgreementReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementDesc", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementCustom", "SOAP::SOAPString", [0, 1]],
      ["paypalBillingAgreementStatus", "SOAP::SOAPString", [0, 1]],
      ["payer", "SOAP::SOAPString", [0, 1]],
      ["payerId", "SOAP::SOAPString", [0, 1]],
      ["payerStatus", "SOAP::SOAPString", [0, 1]],
      ["payerCountry", "SOAP::SOAPString", [0, 1]],
      ["payerBusiness", "SOAP::SOAPString", [0, 1]],
      ["payerSalutation", "SOAP::SOAPString", [0, 1]],
      ["payerFirstname", "SOAP::SOAPString", [0, 1]],
      ["payerMiddlename", "SOAP::SOAPString", [0, 1]],
      ["payerLastname", "SOAP::SOAPString", [0, 1]],
      ["payerSuffix", "SOAP::SOAPString", [0, 1]],
      ["addressStatus", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalCreateAgreementReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalCreateAgreementReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::PayPalDoRefTransactionReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "PayPalDoRefTransactionReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["paypalBillingAgreementId", "SOAP::SOAPString", [0, 1]],
      ["transactionId", "SOAP::SOAPString", [0, 1]],
      ["paypalTransactionType", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentType", "SOAP::SOAPString", [0, 1]],
      ["paypalOrderTime", "SOAP::SOAPString", [0, 1]],
      ["paypalAmount", "SOAP::SOAPString", [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["paypalTaxAmount", "SOAP::SOAPString", [0, 1]],
      ["paypalExchangeRate", "SOAP::SOAPString", [0, 1]],
      ["paypalPaymentStatus", "SOAP::SOAPString", [0, 1]],
      ["paypalPendingReason", "SOAP::SOAPString", [0, 1]],
      ["paypalReasonCode", "SOAP::SOAPString", [0, 1]],
      ["errorCode", "SOAP::SOAPString", [0, 1]],
      ["correlationID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RiskUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "RiskUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FraudUpdateReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "FraudUpdateReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RuleResultItem,
    :schema_type => XSD::QName.new(NsTransactionData167, "RuleResultItem"),
    :schema_element => [
      ["name", "SOAP::SOAPString", [0, 1]],
      ["decision", "SOAP::SOAPString", [0, 1]],
      ["evaluation", "SOAP::SOAPString", [0, 1]],
      ["ruleID", "SOAP::SOAPInteger", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RuleResultItems,
    :schema_type => XSD::QName.new(NsTransactionData167, "RuleResultItems"),
    :schema_element => [
      ["ruleResultItem", "CyberSource::Soap::RuleResultItem[]", [0, nil]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::DecisionReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "DecisionReply"),
    :schema_element => [
      ["casePriority", "SOAP::SOAPInteger", [0, 1]],
      ["activeProfileReply", "CyberSource::Soap::ProfileReply", [0, 1]],
      ["velocityInfoCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ProfileReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ProfileReply"),
    :schema_element => [
      ["selectedBy", "SOAP::SOAPString", [0, 1]],
      ["name", "SOAP::SOAPString", [0, 1]],
      ["destinationQueue", "SOAP::SOAPString", [0, 1]],
      ["rulesTriggered", "CyberSource::Soap::RuleResultItems", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::CCDCCReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "CCDCCReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["dccSupported", nil, [0, 1]],
      ["validHours", "SOAP::SOAPString", [0, 1]],
      ["marginRatePercentage", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ChinaPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["formData", "SOAP::SOAPString", [0, 1]],
      ["verifyFailure", "SOAP::SOAPString", [0, 1]],
      ["verifyInProcess", "SOAP::SOAPString", [0, 1]],
      ["verifySuccess", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ChinaRefundReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "ChinaRefundReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["currency", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::BoletoPaymentReply,
    :schema_type => XSD::QName.new(NsTransactionData167, "BoletoPaymentReply"),
    :schema_element => [
      ["reasonCode", "SOAP::SOAPInteger"],
      ["requestDateTime", nil, [0, 1]],
      ["amount", nil, [0, 1]],
      ["reconciliationID", "SOAP::SOAPString", [0, 1]],
      ["boletoNumber", "SOAP::SOAPString", [0, 1]],
      ["expirationDate", "SOAP::SOAPString", [0, 1]],
      ["url", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ReplyMessage,
    :schema_type => XSD::QName.new(NsTransactionData167, "ReplyMessage"),
    :schema_element => [
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["requestID", "SOAP::SOAPString"],
      ["decision", "SOAP::SOAPString"],
      ["reasonCode", "SOAP::SOAPInteger"],
      ["missingField", "SOAP::SOAPString[]", [0, nil]],
      ["invalidField", "SOAP::SOAPString[]", [0, nil]],
      ["requestToken", "SOAP::SOAPString"],
      ["purchaseTotals", "CyberSource::Soap::PurchaseTotals", [0, 1]],
      ["deniedPartiesMatch", "CyberSource::Soap::DeniedPartiesMatch[]", [0, nil]],
      ["ccAuthReply", "CyberSource::Soap::CCAuthReply", [0, 1]],
      ["ccCaptureReply", "CyberSource::Soap::CCCaptureReply", [0, 1]],
      ["ccCreditReply", "CyberSource::Soap::CCCreditReply", [0, 1]],
      ["ccAuthReversalReply", "CyberSource::Soap::CCAuthReversalReply", [0, 1]],
      ["ccAutoAuthReversalReply", "CyberSource::Soap::CCAutoAuthReversalReply", [0, 1]],
      ["ccDCCReply", "CyberSource::Soap::CCDCCReply", [0, 1]],
      ["ecDebitReply", "CyberSource::Soap::ECDebitReply", [0, 1]],
      ["ecCreditReply", "CyberSource::Soap::ECCreditReply", [0, 1]],
      ["ecAuthenticateReply", "CyberSource::Soap::ECAuthenticateReply", [0, 1]],
      ["payerAuthEnrollReply", "CyberSource::Soap::PayerAuthEnrollReply", [0, 1]],
      ["payerAuthValidateReply", "CyberSource::Soap::PayerAuthValidateReply", [0, 1]],
      ["taxReply", "CyberSource::Soap::TaxReply", [0, 1]],
      ["afsReply", "CyberSource::Soap::AFSReply", [0, 1]],
      ["davReply", "CyberSource::Soap::DAVReply", [0, 1]],
      ["exportReply", "CyberSource::Soap::ExportReply", [0, 1]],
      ["fxRatesReply", "CyberSource::Soap::FXRatesReply", [0, 1]],
      ["bankTransferReply", "CyberSource::Soap::BankTransferReply", [0, 1]],
      ["bankTransferRefundReply", "CyberSource::Soap::BankTransferRefundReply", [0, 1]],
      ["bankTransferRealTimeReply", "CyberSource::Soap::BankTransferRealTimeReply", [0, 1]],
      ["directDebitMandateReply", "CyberSource::Soap::DirectDebitMandateReply", [0, 1]],
      ["directDebitReply", "CyberSource::Soap::DirectDebitReply", [0, 1]],
      ["directDebitValidateReply", "CyberSource::Soap::DirectDebitValidateReply", [0, 1]],
      ["directDebitRefundReply", "CyberSource::Soap::DirectDebitRefundReply", [0, 1]],
      ["paySubscriptionCreateReply", "CyberSource::Soap::PaySubscriptionCreateReply", [0, 1]],
      ["paySubscriptionUpdateReply", "CyberSource::Soap::PaySubscriptionUpdateReply", [0, 1]],
      ["paySubscriptionEventUpdateReply", "CyberSource::Soap::PaySubscriptionEventUpdateReply", [0, 1]],
      ["paySubscriptionRetrieveReply", "CyberSource::Soap::PaySubscriptionRetrieveReply", [0, 1]],
      ["paySubscriptionDeleteReply", "CyberSource::Soap::PaySubscriptionDeleteReply", [0, 1]],
      ["payPalPaymentReply", "CyberSource::Soap::PayPalPaymentReply", [0, 1]],
      ["payPalCreditReply", "CyberSource::Soap::PayPalCreditReply", [0, 1]],
      ["voidReply", "CyberSource::Soap::VoidReply", [0, 1]],
      ["pinlessDebitReply", "CyberSource::Soap::PinlessDebitReply", [0, 1]],
      ["pinlessDebitValidateReply", "CyberSource::Soap::PinlessDebitValidateReply", [0, 1]],
      ["pinlessDebitReversalReply", "CyberSource::Soap::PinlessDebitReversalReply", [0, 1]],
      ["payPalButtonCreateReply", "CyberSource::Soap::PayPalButtonCreateReply", [0, 1]],
      ["payPalPreapprovedPaymentReply", "CyberSource::Soap::PayPalPreapprovedPaymentReply", [0, 1]],
      ["payPalPreapprovedUpdateReply", "CyberSource::Soap::PayPalPreapprovedUpdateReply", [0, 1]],
      ["riskUpdateReply", "CyberSource::Soap::RiskUpdateReply", [0, 1]],
      ["fraudUpdateReply", "CyberSource::Soap::FraudUpdateReply", [0, 1]],
      ["decisionReply", "CyberSource::Soap::DecisionReply", [0, 1]],
      ["reserved", "CyberSource::Soap::ReplyReserved", [0, 1]],
      ["payPalRefundReply", "CyberSource::Soap::PayPalRefundReply", [0, 1]],
      ["payPalAuthReversalReply", "CyberSource::Soap::PayPalAuthReversalReply", [0, 1]],
      ["payPalDoCaptureReply", "CyberSource::Soap::PayPalDoCaptureReply", [0, 1]],
      ["payPalEcDoPaymentReply", "CyberSource::Soap::PayPalEcDoPaymentReply", [0, 1]],
      ["payPalEcGetDetailsReply", "CyberSource::Soap::PayPalEcGetDetailsReply", [0, 1]],
      ["payPalEcSetReply", "CyberSource::Soap::PayPalEcSetReply", [0, 1]],
      ["payPalAuthorizationReply", "CyberSource::Soap::PayPalAuthorizationReply", [0, 1]],
      ["payPalEcOrderSetupReply", "CyberSource::Soap::PayPalEcOrderSetupReply", [0, 1]],
      ["payPalUpdateAgreementReply", "CyberSource::Soap::PayPalUpdateAgreementReply", [0, 1]],
      ["payPalCreateAgreementReply", "CyberSource::Soap::PayPalCreateAgreementReply", [0, 1]],
      ["payPalDoRefTransactionReply", "CyberSource::Soap::PayPalDoRefTransactionReply", [0, 1]],
      ["chinaPaymentReply", "CyberSource::Soap::ChinaPaymentReply", [0, 1]],
      ["chinaRefundReply", "CyberSource::Soap::ChinaRefundReply", [0, 1]],
      ["boletoPaymentReply", "CyberSource::Soap::BoletoPaymentReply", [0, 1]],
      ["receiptNumber", "SOAP::SOAPString", [0, 1]],
      ["additionalData", "SOAP::SOAPString", [0, 1]],
      ["solutionProviderTransactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FaultDetails,
    :schema_type => XSD::QName.new(NsTransactionData167, "FaultDetails"),
    :schema_element => [
      ["requestID", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::AirlineData,
    :schema_type => XSD::QName.new(NsTransactionData167, "AirlineData"),
    :schema_element => [
      ["agentCode", "SOAP::SOAPString", [0, 1]],
      ["agentName", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerCity", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerState", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerPostalCode", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerCountry", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerAddress", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerCode", "SOAP::SOAPString", [0, 1]],
      ["ticketIssuerName", "SOAP::SOAPString", [0, 1]],
      ["ticketNumber", "SOAP::SOAPString", [0, 1]],
      ["checkDigit", "SOAP::SOAPInteger", [0, 1]],
      ["restrictedTicketIndicator", "SOAP::SOAPInteger", [0, 1]],
      ["transactionType", "SOAP::SOAPString", [0, 1]],
      ["extendedPaymentCode", "SOAP::SOAPString", [0, 1]],
      ["carrierName", "SOAP::SOAPString", [0, 1]],
      ["passengerName", "SOAP::SOAPString", [0, 1]],
      ["customerCode", "SOAP::SOAPString", [0, 1]],
      ["documentType", "SOAP::SOAPString", [0, 1]],
      ["documentNumber", "SOAP::SOAPString", [0, 1]],
      ["documentNumberOfParts", "SOAP::SOAPString", [0, 1]],
      ["invoiceNumber", "SOAP::SOAPString", [0, 1]],
      ["invoiceDate", "SOAP::SOAPString", [0, 1]],
      ["chargeDetails", "SOAP::SOAPString", [0, 1]],
      ["bookingReference", "SOAP::SOAPString", [0, 1]],
      ["totalFee", nil, [0, 1]],
      ["clearingSequence", "SOAP::SOAPString", [0, 1]],
      ["clearingCount", "SOAP::SOAPInteger", [0, 1]],
      ["totalClearingAmount", nil, [0, 1]],
      ["leg", "CyberSource::Soap::Leg[]", [0, nil]],
      ["numberOfPassengers", "SOAP::SOAPString", [0, 1]],
      ["reservationSystem", "SOAP::SOAPString", [0, 1]],
      ["processIdentifier", "SOAP::SOAPString", [0, 1]],
      ["iataNumericCode", "SOAP::SOAPString", [0, 1]],
      ["ticketIssueDate", "SOAP::SOAPString", [0, 1]],
      ["electronicTicket", "SOAP::SOAPString", [0, 1]],
      ["originalTicketNumber", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Leg,
    :schema_type => XSD::QName.new(NsTransactionData167, "Leg"),
    :schema_element => [
      ["carrierCode", "SOAP::SOAPString", [0, 1]],
      ["flightNumber", "SOAP::SOAPString", [0, 1]],
      ["originatingAirportCode", "SOAP::SOAPString", [0, 1]],
      ["v_class", ["SOAP::SOAPString", XSD::QName.new(NsTransactionData167, "class")], [0, 1]],
      ["stopoverCode", "SOAP::SOAPString", [0, 1]],
      ["departureDate", "SOAP::SOAPString", [0, 1]],
      ["destination", "SOAP::SOAPString", [0, 1]],
      ["fareBasis", "SOAP::SOAPString", [0, 1]],
      ["departTax", "SOAP::SOAPString", [0, 1]],
      ["conjunctionTicket", "SOAP::SOAPString", [0, 1]],
      ["exchangeTicket", "SOAP::SOAPString", [0, 1]],
      ["couponNumber", "SOAP::SOAPString", [0, 1]],
      ["departureTime", "SOAP::SOAPString", [0, 1]],
      ["departureTimeSegment", "SOAP::SOAPString", [0, 1]],
      ["arrivalTime", "SOAP::SOAPString", [0, 1]],
      ["arrivalTimeSegment", "SOAP::SOAPString", [0, 1]],
      ["endorsementsRestrictions", "SOAP::SOAPString", [0, 1]],
      ["fare", "SOAP::SOAPString", [0, 1]]
    ],
    :schema_attribute => {
      XSD::QName.new(nil, "id") => "SOAP::SOAPInteger"
    }
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Pos,
    :schema_type => XSD::QName.new(NsTransactionData167, "Pos"),
    :schema_element => [
      ["entryMode", "SOAP::SOAPString", [0, 1]],
      ["cardPresent", "SOAP::SOAPString", [0, 1]],
      ["terminalCapability", "SOAP::SOAPString", [0, 1]],
      ["trackData", "SOAP::SOAPString", [0, 1]],
      ["terminalID", "SOAP::SOAPString", [0, 1]],
      ["terminalType", "SOAP::SOAPString", [0, 1]],
      ["terminalLocation", "SOAP::SOAPString", [0, 1]],
      ["transactionSecurity", "SOAP::SOAPString", [0, 1]],
      ["catLevel", "SOAP::SOAPString", [0, 1]],
      ["conditionCode", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::Installment,
    :schema_type => XSD::QName.new(NsTransactionData167, "Installment"),
    :schema_element => [
      ["sequence", "SOAP::SOAPString", [0, 1]],
      ["totalCount", "SOAP::SOAPString", [0, 1]],
      ["totalAmount", "SOAP::SOAPString", [0, 1]],
      ["frequency", "SOAP::SOAPString", [0, 1]],
      ["amount", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::MerchantDefinedData,
    :schema_type => XSD::QName.new(NsTransactionData167, "MerchantDefinedData"),
    :schema_element => [
      ["field1", "SOAP::SOAPString", [0, 1]],
      ["field2", "SOAP::SOAPString", [0, 1]],
      ["field3", "SOAP::SOAPString", [0, 1]],
      ["field4", "SOAP::SOAPString", [0, 1]],
      ["field5", "SOAP::SOAPString", [0, 1]],
      ["field6", "SOAP::SOAPString", [0, 1]],
      ["field7", "SOAP::SOAPString", [0, 1]],
      ["field8", "SOAP::SOAPString", [0, 1]],
      ["field9", "SOAP::SOAPString", [0, 1]],
      ["field10", "SOAP::SOAPString", [0, 1]],
      ["field11", "SOAP::SOAPString", [0, 1]],
      ["field12", "SOAP::SOAPString", [0, 1]],
      ["field13", "SOAP::SOAPString", [0, 1]],
      ["field14", "SOAP::SOAPString", [0, 1]],
      ["field15", "SOAP::SOAPString", [0, 1]],
      ["field16", "SOAP::SOAPString", [0, 1]],
      ["field17", "SOAP::SOAPString", [0, 1]],
      ["field18", "SOAP::SOAPString", [0, 1]],
      ["field19", "SOAP::SOAPString", [0, 1]],
      ["field20", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::MerchantSecureData,
    :schema_type => XSD::QName.new(NsTransactionData167, "MerchantSecureData"),
    :schema_element => [
      ["field1", "SOAP::SOAPString", [0, 1]],
      ["field2", "SOAP::SOAPString", [0, 1]],
      ["field3", "SOAP::SOAPString", [0, 1]],
      ["field4", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ReplyReserved,
    :schema_type => XSD::QName.new(NsTransactionData167, "ReplyReserved"),
    :schema_element => [
      ["any", [nil, XSD::QName.new(NsXMLSchema, "anyType")]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RequestReserved,
    :schema_type => XSD::QName.new(NsTransactionData167, "RequestReserved"),
    :schema_element => [
      ["name", "SOAP::SOAPString"],
      ["value", "SOAP::SOAPString"]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::RequestMessage,
    :schema_name => XSD::QName.new(NsTransactionData167, "requestMessage"),
    :schema_element => [
      ["merchantID", "SOAP::SOAPString", [0, 1]],
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["debtIndicator", nil, [0, 1]],
      ["clientLibrary", "SOAP::SOAPString", [0, 1]],
      ["clientLibraryVersion", "SOAP::SOAPString", [0, 1]],
      ["clientEnvironment", "SOAP::SOAPString", [0, 1]],
      ["clientSecurityLibraryVersion", "SOAP::SOAPString", [0, 1]],
      ["clientApplication", "SOAP::SOAPString", [0, 1]],
      ["clientApplicationVersion", "SOAP::SOAPString", [0, 1]],
      ["clientApplicationUser", "SOAP::SOAPString", [0, 1]],
      ["routingCode", "SOAP::SOAPString", [0, 1]],
      ["comments", "SOAP::SOAPString", [0, 1]],
      ["returnURL", "SOAP::SOAPString", [0, 1]],
      ["invoiceHeader", "CyberSource::Soap::InvoiceHeader", [0, 1]],
      ["billTo", "CyberSource::Soap::BillTo", [0, 1]],
      ["shipTo", "CyberSource::Soap::ShipTo", [0, 1]],
      ["shipFrom", "CyberSource::Soap::ShipFrom", [0, 1]],
      ["item", "CyberSource::Soap::Item[]", [0, nil]],
      ["purchaseTotals", "CyberSource::Soap::PurchaseTotals", [0, 1]],
      ["fundingTotals", "CyberSource::Soap::FundingTotals", [0, 1]],
      ["dcc", "CyberSource::Soap::DCC", [0, 1]],
      ["pos", "CyberSource::Soap::Pos", [0, 1]],
      ["installment", "CyberSource::Soap::Installment", [0, 1]],
      ["card", "CyberSource::Soap::Card", [0, 1]],
      ["check", "CyberSource::Soap::Check", [0, 1]],
      ["bml", "CyberSource::Soap::BML", [0, 1]],
      ["gecc", "CyberSource::Soap::GECC", [0, 1]],
      ["ucaf", "CyberSource::Soap::UCAF", [0, 1]],
      ["fundTransfer", "CyberSource::Soap::FundTransfer", [0, 1]],
      ["bankInfo", "CyberSource::Soap::BankInfo", [0, 1]],
      ["subscription", "CyberSource::Soap::Subscription", [0, 1]],
      ["recurringSubscriptionInfo", "CyberSource::Soap::RecurringSubscriptionInfo", [0, 1]],
      ["decisionManager", "CyberSource::Soap::DecisionManager", [0, 1]],
      ["otherTax", "CyberSource::Soap::OtherTax", [0, 1]],
      ["paypal", "CyberSource::Soap::PayPal", [0, 1]],
      ["merchantDefinedData", "CyberSource::Soap::MerchantDefinedData", [0, 1]],
      ["merchantSecureData", "CyberSource::Soap::MerchantSecureData", [0, 1]],
      ["jpo", "CyberSource::Soap::JPO", [0, 1]],
      ["orderRequestToken", "SOAP::SOAPString", [0, 1]],
      ["linkToRequest", "SOAP::SOAPString", [0, 1]],
      ["ccAuthService", "CyberSource::Soap::CCAuthService", [0, 1]],
      ["ccCaptureService", "CyberSource::Soap::CCCaptureService", [0, 1]],
      ["ccCreditService", "CyberSource::Soap::CCCreditService", [0, 1]],
      ["ccAuthReversalService", "CyberSource::Soap::CCAuthReversalService", [0, 1]],
      ["ccAutoAuthReversalService", "CyberSource::Soap::CCAutoAuthReversalService", [0, 1]],
      ["ccDCCService", "CyberSource::Soap::CCDCCService", [0, 1]],
      ["ecDebitService", "CyberSource::Soap::ECDebitService", [0, 1]],
      ["ecCreditService", "CyberSource::Soap::ECCreditService", [0, 1]],
      ["ecAuthenticateService", "CyberSource::Soap::ECAuthenticateService", [0, 1]],
      ["payerAuthEnrollService", "CyberSource::Soap::PayerAuthEnrollService", [0, 1]],
      ["payerAuthValidateService", "CyberSource::Soap::PayerAuthValidateService", [0, 1]],
      ["taxService", "CyberSource::Soap::TaxService", [0, 1]],
      ["afsService", "CyberSource::Soap::AFSService", [0, 1]],
      ["davService", "CyberSource::Soap::DAVService", [0, 1]],
      ["exportService", "CyberSource::Soap::ExportService", [0, 1]],
      ["fxRatesService", "CyberSource::Soap::FXRatesService", [0, 1]],
      ["bankTransferService", "CyberSource::Soap::BankTransferService", [0, 1]],
      ["bankTransferRefundService", "CyberSource::Soap::BankTransferRefundService", [0, 1]],
      ["bankTransferRealTimeService", "CyberSource::Soap::BankTransferRealTimeService", [0, 1]],
      ["directDebitMandateService", "CyberSource::Soap::DirectDebitMandateService", [0, 1]],
      ["directDebitService", "CyberSource::Soap::DirectDebitService", [0, 1]],
      ["directDebitRefundService", "CyberSource::Soap::DirectDebitRefundService", [0, 1]],
      ["directDebitValidateService", "CyberSource::Soap::DirectDebitValidateService", [0, 1]],
      ["paySubscriptionCreateService", "CyberSource::Soap::PaySubscriptionCreateService", [0, 1]],
      ["paySubscriptionUpdateService", "CyberSource::Soap::PaySubscriptionUpdateService", [0, 1]],
      ["paySubscriptionEventUpdateService", "CyberSource::Soap::PaySubscriptionEventUpdateService", [0, 1]],
      ["paySubscriptionRetrieveService", "CyberSource::Soap::PaySubscriptionRetrieveService", [0, 1]],
      ["paySubscriptionDeleteService", "CyberSource::Soap::PaySubscriptionDeleteService", [0, 1]],
      ["payPalPaymentService", "CyberSource::Soap::PayPalPaymentService", [0, 1]],
      ["payPalCreditService", "CyberSource::Soap::PayPalCreditService", [0, 1]],
      ["voidService", "CyberSource::Soap::VoidService", [0, 1]],
      ["businessRules", "CyberSource::Soap::BusinessRules", [0, 1]],
      ["pinlessDebitService", "CyberSource::Soap::PinlessDebitService", [0, 1]],
      ["pinlessDebitValidateService", "CyberSource::Soap::PinlessDebitValidateService", [0, 1]],
      ["pinlessDebitReversalService", "CyberSource::Soap::PinlessDebitReversalService", [0, 1]],
      ["batch", "CyberSource::Soap::Batch", [0, 1]],
      ["airlineData", "CyberSource::Soap::AirlineData", [0, 1]],
      ["payPalButtonCreateService", "CyberSource::Soap::PayPalButtonCreateService", [0, 1]],
      ["payPalPreapprovedPaymentService", "CyberSource::Soap::PayPalPreapprovedPaymentService", [0, 1]],
      ["payPalPreapprovedUpdateService", "CyberSource::Soap::PayPalPreapprovedUpdateService", [0, 1]],
      ["riskUpdateService", "CyberSource::Soap::RiskUpdateService", [0, 1]],
      ["fraudUpdateService", "CyberSource::Soap::FraudUpdateService", [0, 1]],
      ["reserved", "CyberSource::Soap::RequestReserved[]", [0, nil]],
      ["deviceFingerprintID", "SOAP::SOAPString", [0, 1]],
      ["payPalRefundService", "CyberSource::Soap::PayPalRefundService", [0, 1]],
      ["payPalAuthReversalService", "CyberSource::Soap::PayPalAuthReversalService", [0, 1]],
      ["payPalDoCaptureService", "CyberSource::Soap::PayPalDoCaptureService", [0, 1]],
      ["payPalEcDoPaymentService", "CyberSource::Soap::PayPalEcDoPaymentService", [0, 1]],
      ["payPalEcGetDetailsService", "CyberSource::Soap::PayPalEcGetDetailsService", [0, 1]],
      ["payPalEcSetService", "CyberSource::Soap::PayPalEcSetService", [0, 1]],
      ["payPalEcOrderSetupService", "CyberSource::Soap::PayPalEcOrderSetupService", [0, 1]],
      ["payPalAuthorizationService", "CyberSource::Soap::PayPalAuthorizationService", [0, 1]],
      ["payPalUpdateAgreementService", "CyberSource::Soap::PayPalUpdateAgreementService", [0, 1]],
      ["payPalCreateAgreementService", "CyberSource::Soap::PayPalCreateAgreementService", [0, 1]],
      ["payPalDoRefTransactionService", "CyberSource::Soap::PayPalDoRefTransactionService", [0, 1]],
      ["chinaPaymentService", "CyberSource::Soap::ChinaPaymentService", [0, 1]],
      ["chinaRefundService", "CyberSource::Soap::ChinaRefundService", [0, 1]],
      ["boletoPaymentService", "CyberSource::Soap::BoletoPaymentService", [0, 1]],
      ["ignoreCardExpiration", nil, [0, 1]],
      ["reportGroup", "SOAP::SOAPString", [0, 1]],
      ["processorID", "SOAP::SOAPString", [0, 1]],
      ["solutionProviderTransactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::ReplyMessage,
    :schema_name => XSD::QName.new(NsTransactionData167, "replyMessage"),
    :schema_element => [
      ["merchantReferenceCode", "SOAP::SOAPString", [0, 1]],
      ["requestID", "SOAP::SOAPString"],
      ["decision", "SOAP::SOAPString"],
      ["reasonCode", "SOAP::SOAPInteger"],
      ["missingField", "SOAP::SOAPString[]", [0, nil]],
      ["invalidField", "SOAP::SOAPString[]", [0, nil]],
      ["requestToken", "SOAP::SOAPString"],
      ["purchaseTotals", "CyberSource::Soap::PurchaseTotals", [0, 1]],
      ["deniedPartiesMatch", "CyberSource::Soap::DeniedPartiesMatch[]", [0, nil]],
      ["ccAuthReply", "CyberSource::Soap::CCAuthReply", [0, 1]],
      ["ccCaptureReply", "CyberSource::Soap::CCCaptureReply", [0, 1]],
      ["ccCreditReply", "CyberSource::Soap::CCCreditReply", [0, 1]],
      ["ccAuthReversalReply", "CyberSource::Soap::CCAuthReversalReply", [0, 1]],
      ["ccAutoAuthReversalReply", "CyberSource::Soap::CCAutoAuthReversalReply", [0, 1]],
      ["ccDCCReply", "CyberSource::Soap::CCDCCReply", [0, 1]],
      ["ecDebitReply", "CyberSource::Soap::ECDebitReply", [0, 1]],
      ["ecCreditReply", "CyberSource::Soap::ECCreditReply", [0, 1]],
      ["ecAuthenticateReply", "CyberSource::Soap::ECAuthenticateReply", [0, 1]],
      ["payerAuthEnrollReply", "CyberSource::Soap::PayerAuthEnrollReply", [0, 1]],
      ["payerAuthValidateReply", "CyberSource::Soap::PayerAuthValidateReply", [0, 1]],
      ["taxReply", "CyberSource::Soap::TaxReply", [0, 1]],
      ["afsReply", "CyberSource::Soap::AFSReply", [0, 1]],
      ["davReply", "CyberSource::Soap::DAVReply", [0, 1]],
      ["exportReply", "CyberSource::Soap::ExportReply", [0, 1]],
      ["fxRatesReply", "CyberSource::Soap::FXRatesReply", [0, 1]],
      ["bankTransferReply", "CyberSource::Soap::BankTransferReply", [0, 1]],
      ["bankTransferRefundReply", "CyberSource::Soap::BankTransferRefundReply", [0, 1]],
      ["bankTransferRealTimeReply", "CyberSource::Soap::BankTransferRealTimeReply", [0, 1]],
      ["directDebitMandateReply", "CyberSource::Soap::DirectDebitMandateReply", [0, 1]],
      ["directDebitReply", "CyberSource::Soap::DirectDebitReply", [0, 1]],
      ["directDebitValidateReply", "CyberSource::Soap::DirectDebitValidateReply", [0, 1]],
      ["directDebitRefundReply", "CyberSource::Soap::DirectDebitRefundReply", [0, 1]],
      ["paySubscriptionCreateReply", "CyberSource::Soap::PaySubscriptionCreateReply", [0, 1]],
      ["paySubscriptionUpdateReply", "CyberSource::Soap::PaySubscriptionUpdateReply", [0, 1]],
      ["paySubscriptionEventUpdateReply", "CyberSource::Soap::PaySubscriptionEventUpdateReply", [0, 1]],
      ["paySubscriptionRetrieveReply", "CyberSource::Soap::PaySubscriptionRetrieveReply", [0, 1]],
      ["paySubscriptionDeleteReply", "CyberSource::Soap::PaySubscriptionDeleteReply", [0, 1]],
      ["payPalPaymentReply", "CyberSource::Soap::PayPalPaymentReply", [0, 1]],
      ["payPalCreditReply", "CyberSource::Soap::PayPalCreditReply", [0, 1]],
      ["voidReply", "CyberSource::Soap::VoidReply", [0, 1]],
      ["pinlessDebitReply", "CyberSource::Soap::PinlessDebitReply", [0, 1]],
      ["pinlessDebitValidateReply", "CyberSource::Soap::PinlessDebitValidateReply", [0, 1]],
      ["pinlessDebitReversalReply", "CyberSource::Soap::PinlessDebitReversalReply", [0, 1]],
      ["payPalButtonCreateReply", "CyberSource::Soap::PayPalButtonCreateReply", [0, 1]],
      ["payPalPreapprovedPaymentReply", "CyberSource::Soap::PayPalPreapprovedPaymentReply", [0, 1]],
      ["payPalPreapprovedUpdateReply", "CyberSource::Soap::PayPalPreapprovedUpdateReply", [0, 1]],
      ["riskUpdateReply", "CyberSource::Soap::RiskUpdateReply", [0, 1]],
      ["fraudUpdateReply", "CyberSource::Soap::FraudUpdateReply", [0, 1]],
      ["decisionReply", "CyberSource::Soap::DecisionReply", [0, 1]],
      ["reserved", "CyberSource::Soap::ReplyReserved", [0, 1]],
      ["payPalRefundReply", "CyberSource::Soap::PayPalRefundReply", [0, 1]],
      ["payPalAuthReversalReply", "CyberSource::Soap::PayPalAuthReversalReply", [0, 1]],
      ["payPalDoCaptureReply", "CyberSource::Soap::PayPalDoCaptureReply", [0, 1]],
      ["payPalEcDoPaymentReply", "CyberSource::Soap::PayPalEcDoPaymentReply", [0, 1]],
      ["payPalEcGetDetailsReply", "CyberSource::Soap::PayPalEcGetDetailsReply", [0, 1]],
      ["payPalEcSetReply", "CyberSource::Soap::PayPalEcSetReply", [0, 1]],
      ["payPalAuthorizationReply", "CyberSource::Soap::PayPalAuthorizationReply", [0, 1]],
      ["payPalEcOrderSetupReply", "CyberSource::Soap::PayPalEcOrderSetupReply", [0, 1]],
      ["payPalUpdateAgreementReply", "CyberSource::Soap::PayPalUpdateAgreementReply", [0, 1]],
      ["payPalCreateAgreementReply", "CyberSource::Soap::PayPalCreateAgreementReply", [0, 1]],
      ["payPalDoRefTransactionReply", "CyberSource::Soap::PayPalDoRefTransactionReply", [0, 1]],
      ["chinaPaymentReply", "CyberSource::Soap::ChinaPaymentReply", [0, 1]],
      ["chinaRefundReply", "CyberSource::Soap::ChinaRefundReply", [0, 1]],
      ["boletoPaymentReply", "CyberSource::Soap::BoletoPaymentReply", [0, 1]],
      ["receiptNumber", "SOAP::SOAPString", [0, 1]],
      ["additionalData", "SOAP::SOAPString", [0, 1]],
      ["solutionProviderTransactionID", "SOAP::SOAPString", [0, 1]]
    ]
  )

  LiteralRegistry.register(
    :class => CyberSource::Soap::FaultDetails,
    :schema_name => XSD::QName.new(NsTransactionData167, "faultDetails"),
    :schema_element => [
      ["requestID", "SOAP::SOAPString"]
    ]
  )
end

end; end
