require 'xsd/qname'

module CyberSource; module Soap


# {urn:schemas-cybersource-com:transaction-data-1.67}Item
#   unitPrice - (any)
#   quantity - SOAP::SOAPInteger
#   productCode - SOAP::SOAPString
#   productName - SOAP::SOAPString
#   productSKU - SOAP::SOAPString
#   productRisk - SOAP::SOAPString
#   taxAmount - (any)
#   cityOverrideAmount - (any)
#   cityOverrideRate - (any)
#   countyOverrideAmount - (any)
#   countyOverrideRate - (any)
#   districtOverrideAmount - (any)
#   districtOverrideRate - (any)
#   stateOverrideAmount - (any)
#   stateOverrideRate - (any)
#   countryOverrideAmount - (any)
#   countryOverrideRate - (any)
#   orderAcceptanceCity - SOAP::SOAPString
#   orderAcceptanceCounty - SOAP::SOAPString
#   orderAcceptanceCountry - SOAP::SOAPString
#   orderAcceptanceState - SOAP::SOAPString
#   orderAcceptancePostalCode - SOAP::SOAPString
#   orderOriginCity - SOAP::SOAPString
#   orderOriginCounty - SOAP::SOAPString
#   orderOriginCountry - SOAP::SOAPString
#   orderOriginState - SOAP::SOAPString
#   orderOriginPostalCode - SOAP::SOAPString
#   shipFromCity - SOAP::SOAPString
#   shipFromCounty - SOAP::SOAPString
#   shipFromCountry - SOAP::SOAPString
#   shipFromState - SOAP::SOAPString
#   shipFromPostalCode - SOAP::SOAPString
#   export - SOAP::SOAPString
#   noExport - SOAP::SOAPString
#   nationalTax - (any)
#   vatRate - (any)
#   sellerRegistration - SOAP::SOAPString
#   sellerRegistration0 - SOAP::SOAPString
#   sellerRegistration1 - SOAP::SOAPString
#   sellerRegistration2 - SOAP::SOAPString
#   sellerRegistration3 - SOAP::SOAPString
#   sellerRegistration4 - SOAP::SOAPString
#   sellerRegistration5 - SOAP::SOAPString
#   sellerRegistration6 - SOAP::SOAPString
#   sellerRegistration7 - SOAP::SOAPString
#   sellerRegistration8 - SOAP::SOAPString
#   sellerRegistration9 - SOAP::SOAPString
#   buyerRegistration - SOAP::SOAPString
#   middlemanRegistration - SOAP::SOAPString
#   pointOfTitleTransfer - SOAP::SOAPString
#   giftCategory - (any)
#   timeCategory - SOAP::SOAPString
#   hostHedge - SOAP::SOAPString
#   timeHedge - SOAP::SOAPString
#   velocityHedge - SOAP::SOAPString
#   nonsensicalHedge - SOAP::SOAPString
#   phoneHedge - SOAP::SOAPString
#   obscenitiesHedge - SOAP::SOAPString
#   unitOfMeasure - SOAP::SOAPString
#   taxRate - (any)
#   totalAmount - (any)
#   discountAmount - (any)
#   discountRate - (any)
#   commodityCode - SOAP::SOAPString
#   grossNetIndicator - SOAP::SOAPString
#   taxTypeApplied - SOAP::SOAPString
#   discountIndicator - SOAP::SOAPString
#   alternateTaxID - SOAP::SOAPString
#   alternateTaxAmount - (any)
#   alternateTaxTypeApplied - SOAP::SOAPString
#   alternateTaxRate - (any)
#   alternateTaxType - SOAP::SOAPString
#   localTax - (any)
#   zeroCostToCustomerIndicator - SOAP::SOAPString
#   passengerFirstName - SOAP::SOAPString
#   passengerLastName - SOAP::SOAPString
#   passengerID - SOAP::SOAPString
#   passengerStatus - SOAP::SOAPString
#   passengerType - SOAP::SOAPString
#   passengerEmail - SOAP::SOAPString
#   passengerPhone - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   xmlattr_id - SOAP::SOAPInteger
class Item
  AttrId = XSD::QName.new(nil, "id")

  attr_accessor :unitPrice
  attr_accessor :quantity
  attr_accessor :productCode
  attr_accessor :productName
  attr_accessor :productSKU
  attr_accessor :productRisk
  attr_accessor :taxAmount
  attr_accessor :cityOverrideAmount
  attr_accessor :cityOverrideRate
  attr_accessor :countyOverrideAmount
  attr_accessor :countyOverrideRate
  attr_accessor :districtOverrideAmount
  attr_accessor :districtOverrideRate
  attr_accessor :stateOverrideAmount
  attr_accessor :stateOverrideRate
  attr_accessor :countryOverrideAmount
  attr_accessor :countryOverrideRate
  attr_accessor :orderAcceptanceCity
  attr_accessor :orderAcceptanceCounty
  attr_accessor :orderAcceptanceCountry
  attr_accessor :orderAcceptanceState
  attr_accessor :orderAcceptancePostalCode
  attr_accessor :orderOriginCity
  attr_accessor :orderOriginCounty
  attr_accessor :orderOriginCountry
  attr_accessor :orderOriginState
  attr_accessor :orderOriginPostalCode
  attr_accessor :shipFromCity
  attr_accessor :shipFromCounty
  attr_accessor :shipFromCountry
  attr_accessor :shipFromState
  attr_accessor :shipFromPostalCode
  attr_accessor :export
  attr_accessor :noExport
  attr_accessor :nationalTax
  attr_accessor :vatRate
  attr_accessor :sellerRegistration
  attr_accessor :sellerRegistration0
  attr_accessor :sellerRegistration1
  attr_accessor :sellerRegistration2
  attr_accessor :sellerRegistration3
  attr_accessor :sellerRegistration4
  attr_accessor :sellerRegistration5
  attr_accessor :sellerRegistration6
  attr_accessor :sellerRegistration7
  attr_accessor :sellerRegistration8
  attr_accessor :sellerRegistration9
  attr_accessor :buyerRegistration
  attr_accessor :middlemanRegistration
  attr_accessor :pointOfTitleTransfer
  attr_accessor :giftCategory
  attr_accessor :timeCategory
  attr_accessor :hostHedge
  attr_accessor :timeHedge
  attr_accessor :velocityHedge
  attr_accessor :nonsensicalHedge
  attr_accessor :phoneHedge
  attr_accessor :obscenitiesHedge
  attr_accessor :unitOfMeasure
  attr_accessor :taxRate
  attr_accessor :totalAmount
  attr_accessor :discountAmount
  attr_accessor :discountRate
  attr_accessor :commodityCode
  attr_accessor :grossNetIndicator
  attr_accessor :taxTypeApplied
  attr_accessor :discountIndicator
  attr_accessor :alternateTaxID
  attr_accessor :alternateTaxAmount
  attr_accessor :alternateTaxTypeApplied
  attr_accessor :alternateTaxRate
  attr_accessor :alternateTaxType
  attr_accessor :localTax
  attr_accessor :zeroCostToCustomerIndicator
  attr_accessor :passengerFirstName
  attr_accessor :passengerLastName
  attr_accessor :passengerID
  attr_accessor :passengerStatus
  attr_accessor :passengerType
  attr_accessor :passengerEmail
  attr_accessor :passengerPhone
  attr_accessor :invoiceNumber

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_id
    __xmlattr[AttrId]
  end

  def xmlattr_id=(value)
    __xmlattr[AttrId] = value
  end

  def initialize(unitPrice = nil, quantity = nil, productCode = nil, productName = nil, productSKU = nil, productRisk = nil, taxAmount = nil, cityOverrideAmount = nil, cityOverrideRate = nil, countyOverrideAmount = nil, countyOverrideRate = nil, districtOverrideAmount = nil, districtOverrideRate = nil, stateOverrideAmount = nil, stateOverrideRate = nil, countryOverrideAmount = nil, countryOverrideRate = nil, orderAcceptanceCity = nil, orderAcceptanceCounty = nil, orderAcceptanceCountry = nil, orderAcceptanceState = nil, orderAcceptancePostalCode = nil, orderOriginCity = nil, orderOriginCounty = nil, orderOriginCountry = nil, orderOriginState = nil, orderOriginPostalCode = nil, shipFromCity = nil, shipFromCounty = nil, shipFromCountry = nil, shipFromState = nil, shipFromPostalCode = nil, export = nil, noExport = nil, nationalTax = nil, vatRate = nil, sellerRegistration = nil, sellerRegistration0 = nil, sellerRegistration1 = nil, sellerRegistration2 = nil, sellerRegistration3 = nil, sellerRegistration4 = nil, sellerRegistration5 = nil, sellerRegistration6 = nil, sellerRegistration7 = nil, sellerRegistration8 = nil, sellerRegistration9 = nil, buyerRegistration = nil, middlemanRegistration = nil, pointOfTitleTransfer = nil, giftCategory = nil, timeCategory = nil, hostHedge = nil, timeHedge = nil, velocityHedge = nil, nonsensicalHedge = nil, phoneHedge = nil, obscenitiesHedge = nil, unitOfMeasure = nil, taxRate = nil, totalAmount = nil, discountAmount = nil, discountRate = nil, commodityCode = nil, grossNetIndicator = nil, taxTypeApplied = nil, discountIndicator = nil, alternateTaxID = nil, alternateTaxAmount = nil, alternateTaxTypeApplied = nil, alternateTaxRate = nil, alternateTaxType = nil, localTax = nil, zeroCostToCustomerIndicator = nil, passengerFirstName = nil, passengerLastName = nil, passengerID = nil, passengerStatus = nil, passengerType = nil, passengerEmail = nil, passengerPhone = nil, invoiceNumber = nil)
    @unitPrice = unitPrice
    @quantity = quantity
    @productCode = productCode
    @productName = productName
    @productSKU = productSKU
    @productRisk = productRisk
    @taxAmount = taxAmount
    @cityOverrideAmount = cityOverrideAmount
    @cityOverrideRate = cityOverrideRate
    @countyOverrideAmount = countyOverrideAmount
    @countyOverrideRate = countyOverrideRate
    @districtOverrideAmount = districtOverrideAmount
    @districtOverrideRate = districtOverrideRate
    @stateOverrideAmount = stateOverrideAmount
    @stateOverrideRate = stateOverrideRate
    @countryOverrideAmount = countryOverrideAmount
    @countryOverrideRate = countryOverrideRate
    @orderAcceptanceCity = orderAcceptanceCity
    @orderAcceptanceCounty = orderAcceptanceCounty
    @orderAcceptanceCountry = orderAcceptanceCountry
    @orderAcceptanceState = orderAcceptanceState
    @orderAcceptancePostalCode = orderAcceptancePostalCode
    @orderOriginCity = orderOriginCity
    @orderOriginCounty = orderOriginCounty
    @orderOriginCountry = orderOriginCountry
    @orderOriginState = orderOriginState
    @orderOriginPostalCode = orderOriginPostalCode
    @shipFromCity = shipFromCity
    @shipFromCounty = shipFromCounty
    @shipFromCountry = shipFromCountry
    @shipFromState = shipFromState
    @shipFromPostalCode = shipFromPostalCode
    @export = export
    @noExport = noExport
    @nationalTax = nationalTax
    @vatRate = vatRate
    @sellerRegistration = sellerRegistration
    @sellerRegistration0 = sellerRegistration0
    @sellerRegistration1 = sellerRegistration1
    @sellerRegistration2 = sellerRegistration2
    @sellerRegistration3 = sellerRegistration3
    @sellerRegistration4 = sellerRegistration4
    @sellerRegistration5 = sellerRegistration5
    @sellerRegistration6 = sellerRegistration6
    @sellerRegistration7 = sellerRegistration7
    @sellerRegistration8 = sellerRegistration8
    @sellerRegistration9 = sellerRegistration9
    @buyerRegistration = buyerRegistration
    @middlemanRegistration = middlemanRegistration
    @pointOfTitleTransfer = pointOfTitleTransfer
    @giftCategory = giftCategory
    @timeCategory = timeCategory
    @hostHedge = hostHedge
    @timeHedge = timeHedge
    @velocityHedge = velocityHedge
    @nonsensicalHedge = nonsensicalHedge
    @phoneHedge = phoneHedge
    @obscenitiesHedge = obscenitiesHedge
    @unitOfMeasure = unitOfMeasure
    @taxRate = taxRate
    @totalAmount = totalAmount
    @discountAmount = discountAmount
    @discountRate = discountRate
    @commodityCode = commodityCode
    @grossNetIndicator = grossNetIndicator
    @taxTypeApplied = taxTypeApplied
    @discountIndicator = discountIndicator
    @alternateTaxID = alternateTaxID
    @alternateTaxAmount = alternateTaxAmount
    @alternateTaxTypeApplied = alternateTaxTypeApplied
    @alternateTaxRate = alternateTaxRate
    @alternateTaxType = alternateTaxType
    @localTax = localTax
    @zeroCostToCustomerIndicator = zeroCostToCustomerIndicator
    @passengerFirstName = passengerFirstName
    @passengerLastName = passengerLastName
    @passengerID = passengerID
    @passengerStatus = passengerStatus
    @passengerType = passengerType
    @passengerEmail = passengerEmail
    @passengerPhone = passengerPhone
    @invoiceNumber = invoiceNumber
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCAuthService
#   cavv - SOAP::SOAPString
#   cavvAlgorithm - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   eciRaw - SOAP::SOAPString
#   xid - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   avsLevel - SOAP::SOAPString
#   fxQuoteID - SOAP::SOAPString
#   returnAuthRecord - (any)
#   authType - SOAP::SOAPString
#   verbalAuthCode - SOAP::SOAPString
#   billPayment - (any)
#   authenticationXID - SOAP::SOAPString
#   authorizationXID - SOAP::SOAPString
#   industryDatatype - SOAP::SOAPString
#   traceNumber - SOAP::SOAPString
#   checksumKey - SOAP::SOAPString
#   aggregatorID - SOAP::SOAPString
#   splitTenderIndicator - SOAP::SOAPString
#   veresEnrolled - SOAP::SOAPString
#   paresStatus - SOAP::SOAPString
#   partialAuthIndicator - (any)
#   captureDate - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class CCAuthService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :cavv
  attr_accessor :cavvAlgorithm
  attr_accessor :commerceIndicator
  attr_accessor :eciRaw
  attr_accessor :xid
  attr_accessor :reconciliationID
  attr_accessor :avsLevel
  attr_accessor :fxQuoteID
  attr_accessor :returnAuthRecord
  attr_accessor :authType
  attr_accessor :verbalAuthCode
  attr_accessor :billPayment
  attr_accessor :authenticationXID
  attr_accessor :authorizationXID
  attr_accessor :industryDatatype
  attr_accessor :traceNumber
  attr_accessor :checksumKey
  attr_accessor :aggregatorID
  attr_accessor :splitTenderIndicator
  attr_accessor :veresEnrolled
  attr_accessor :paresStatus
  attr_accessor :partialAuthIndicator
  attr_accessor :captureDate

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(cavv = nil, cavvAlgorithm = nil, commerceIndicator = nil, eciRaw = nil, xid = nil, reconciliationID = nil, avsLevel = nil, fxQuoteID = nil, returnAuthRecord = nil, authType = nil, verbalAuthCode = nil, billPayment = nil, authenticationXID = nil, authorizationXID = nil, industryDatatype = nil, traceNumber = nil, checksumKey = nil, aggregatorID = nil, splitTenderIndicator = nil, veresEnrolled = nil, paresStatus = nil, partialAuthIndicator = nil, captureDate = nil)
    @cavv = cavv
    @cavvAlgorithm = cavvAlgorithm
    @commerceIndicator = commerceIndicator
    @eciRaw = eciRaw
    @xid = xid
    @reconciliationID = reconciliationID
    @avsLevel = avsLevel
    @fxQuoteID = fxQuoteID
    @returnAuthRecord = returnAuthRecord
    @authType = authType
    @verbalAuthCode = verbalAuthCode
    @billPayment = billPayment
    @authenticationXID = authenticationXID
    @authorizationXID = authorizationXID
    @industryDatatype = industryDatatype
    @traceNumber = traceNumber
    @checksumKey = checksumKey
    @aggregatorID = aggregatorID
    @splitTenderIndicator = splitTenderIndicator
    @veresEnrolled = veresEnrolled
    @paresStatus = paresStatus
    @partialAuthIndicator = partialAuthIndicator
    @captureDate = captureDate
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCCaptureService
#   authType - SOAP::SOAPString
#   verbalAuthCode - SOAP::SOAPString
#   authRequestID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   partialPaymentID - SOAP::SOAPString
#   purchasingLevel - SOAP::SOAPString
#   industryDatatype - SOAP::SOAPString
#   authRequestToken - SOAP::SOAPString
#   merchantReceiptNumber - SOAP::SOAPString
#   posData - SOAP::SOAPString
#   transactionID - SOAP::SOAPString
#   checksumKey - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class CCCaptureService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :authType
  attr_accessor :verbalAuthCode
  attr_accessor :authRequestID
  attr_accessor :reconciliationID
  attr_accessor :partialPaymentID
  attr_accessor :purchasingLevel
  attr_accessor :industryDatatype
  attr_accessor :authRequestToken
  attr_accessor :merchantReceiptNumber
  attr_accessor :posData
  attr_accessor :transactionID
  attr_accessor :checksumKey

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(authType = nil, verbalAuthCode = nil, authRequestID = nil, reconciliationID = nil, partialPaymentID = nil, purchasingLevel = nil, industryDatatype = nil, authRequestToken = nil, merchantReceiptNumber = nil, posData = nil, transactionID = nil, checksumKey = nil)
    @authType = authType
    @verbalAuthCode = verbalAuthCode
    @authRequestID = authRequestID
    @reconciliationID = reconciliationID
    @partialPaymentID = partialPaymentID
    @purchasingLevel = purchasingLevel
    @industryDatatype = industryDatatype
    @authRequestToken = authRequestToken
    @merchantReceiptNumber = merchantReceiptNumber
    @posData = posData
    @transactionID = transactionID
    @checksumKey = checksumKey
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCCreditService
#   captureRequestID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   partialPaymentID - SOAP::SOAPString
#   purchasingLevel - SOAP::SOAPString
#   industryDatatype - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   billPayment - (any)
#   authorizationXID - SOAP::SOAPString
#   occurrenceNumber - SOAP::SOAPString
#   authCode - SOAP::SOAPString
#   captureRequestToken - SOAP::SOAPString
#   merchantReceiptNumber - SOAP::SOAPString
#   checksumKey - SOAP::SOAPString
#   aggregatorID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class CCCreditService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :captureRequestID
  attr_accessor :reconciliationID
  attr_accessor :partialPaymentID
  attr_accessor :purchasingLevel
  attr_accessor :industryDatatype
  attr_accessor :commerceIndicator
  attr_accessor :billPayment
  attr_accessor :authorizationXID
  attr_accessor :occurrenceNumber
  attr_accessor :authCode
  attr_accessor :captureRequestToken
  attr_accessor :merchantReceiptNumber
  attr_accessor :checksumKey
  attr_accessor :aggregatorID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(captureRequestID = nil, reconciliationID = nil, partialPaymentID = nil, purchasingLevel = nil, industryDatatype = nil, commerceIndicator = nil, billPayment = nil, authorizationXID = nil, occurrenceNumber = nil, authCode = nil, captureRequestToken = nil, merchantReceiptNumber = nil, checksumKey = nil, aggregatorID = nil)
    @captureRequestID = captureRequestID
    @reconciliationID = reconciliationID
    @partialPaymentID = partialPaymentID
    @purchasingLevel = purchasingLevel
    @industryDatatype = industryDatatype
    @commerceIndicator = commerceIndicator
    @billPayment = billPayment
    @authorizationXID = authorizationXID
    @occurrenceNumber = occurrenceNumber
    @authCode = authCode
    @captureRequestToken = captureRequestToken
    @merchantReceiptNumber = merchantReceiptNumber
    @checksumKey = checksumKey
    @aggregatorID = aggregatorID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCAuthReversalService
#   authRequestID - SOAP::SOAPString
#   authRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class CCAuthReversalService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :authRequestID
  attr_accessor :authRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(authRequestID = nil, authRequestToken = nil)
    @authRequestID = authRequestID
    @authRequestToken = authRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCAutoAuthReversalService
#   authPaymentServiceData - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   authAmount - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   authRequestID - SOAP::SOAPString
#   billAmount - SOAP::SOAPString
#   authCode - SOAP::SOAPString
#   authType - SOAP::SOAPString
#   billPayment - (any)
#   dateAdded - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class CCAutoAuthReversalService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :authPaymentServiceData
  attr_accessor :reconciliationID
  attr_accessor :authAmount
  attr_accessor :commerceIndicator
  attr_accessor :authRequestID
  attr_accessor :billAmount
  attr_accessor :authCode
  attr_accessor :authType
  attr_accessor :billPayment
  attr_accessor :dateAdded

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(authPaymentServiceData = nil, reconciliationID = nil, authAmount = nil, commerceIndicator = nil, authRequestID = nil, billAmount = nil, authCode = nil, authType = nil, billPayment = nil, dateAdded = nil)
    @authPaymentServiceData = authPaymentServiceData
    @reconciliationID = reconciliationID
    @authAmount = authAmount
    @commerceIndicator = commerceIndicator
    @authRequestID = authRequestID
    @billAmount = billAmount
    @authCode = authCode
    @authType = authType
    @billPayment = billPayment
    @dateAdded = dateAdded
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCDCCService
#   xmlattr_run - SOAP::SOAPString
class CCDCCService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ECDebitService
#   paymentMode - SOAP::SOAPInteger
#   referenceNumber - SOAP::SOAPString
#   settlementMethod - SOAP::SOAPString
#   transactionToken - SOAP::SOAPString
#   verificationLevel - SOAP::SOAPInteger
#   partialPaymentID - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   debitRequestID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class ECDebitService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paymentMode
  attr_accessor :referenceNumber
  attr_accessor :settlementMethod
  attr_accessor :transactionToken
  attr_accessor :verificationLevel
  attr_accessor :partialPaymentID
  attr_accessor :commerceIndicator
  attr_accessor :debitRequestID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paymentMode = nil, referenceNumber = nil, settlementMethod = nil, transactionToken = nil, verificationLevel = nil, partialPaymentID = nil, commerceIndicator = nil, debitRequestID = nil)
    @paymentMode = paymentMode
    @referenceNumber = referenceNumber
    @settlementMethod = settlementMethod
    @transactionToken = transactionToken
    @verificationLevel = verificationLevel
    @partialPaymentID = partialPaymentID
    @commerceIndicator = commerceIndicator
    @debitRequestID = debitRequestID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ECCreditService
#   referenceNumber - SOAP::SOAPString
#   settlementMethod - SOAP::SOAPString
#   transactionToken - SOAP::SOAPString
#   debitRequestID - SOAP::SOAPString
#   partialPaymentID - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   debitRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class ECCreditService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :referenceNumber
  attr_accessor :settlementMethod
  attr_accessor :transactionToken
  attr_accessor :debitRequestID
  attr_accessor :partialPaymentID
  attr_accessor :commerceIndicator
  attr_accessor :debitRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(referenceNumber = nil, settlementMethod = nil, transactionToken = nil, debitRequestID = nil, partialPaymentID = nil, commerceIndicator = nil, debitRequestToken = nil)
    @referenceNumber = referenceNumber
    @settlementMethod = settlementMethod
    @transactionToken = transactionToken
    @debitRequestID = debitRequestID
    @partialPaymentID = partialPaymentID
    @commerceIndicator = commerceIndicator
    @debitRequestToken = debitRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ECAuthenticateService
#   referenceNumber - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class ECAuthenticateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :referenceNumber

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(referenceNumber = nil)
    @referenceNumber = referenceNumber
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayerAuthEnrollService
#   httpAccept - SOAP::SOAPString
#   httpUserAgent - SOAP::SOAPString
#   merchantName - SOAP::SOAPString
#   merchantURL - SOAP::SOAPString
#   purchaseDescription - SOAP::SOAPString
#   purchaseTime - (any)
#   countryCode - SOAP::SOAPString
#   acquirerBin - SOAP::SOAPString
#   loginID - SOAP::SOAPString
#   password - SOAP::SOAPString
#   merchantID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayerAuthEnrollService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :httpAccept
  attr_accessor :httpUserAgent
  attr_accessor :merchantName
  attr_accessor :merchantURL
  attr_accessor :purchaseDescription
  attr_accessor :purchaseTime
  attr_accessor :countryCode
  attr_accessor :acquirerBin
  attr_accessor :loginID
  attr_accessor :password
  attr_accessor :merchantID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(httpAccept = nil, httpUserAgent = nil, merchantName = nil, merchantURL = nil, purchaseDescription = nil, purchaseTime = nil, countryCode = nil, acquirerBin = nil, loginID = nil, password = nil, merchantID = nil)
    @httpAccept = httpAccept
    @httpUserAgent = httpUserAgent
    @merchantName = merchantName
    @merchantURL = merchantURL
    @purchaseDescription = purchaseDescription
    @purchaseTime = purchaseTime
    @countryCode = countryCode
    @acquirerBin = acquirerBin
    @loginID = loginID
    @password = password
    @merchantID = merchantID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayerAuthValidateService
#   signedPARes - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayerAuthValidateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :signedPARes

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(signedPARes = nil)
    @signedPARes = signedPARes
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}TaxService
#   nexus - SOAP::SOAPString
#   noNexus - SOAP::SOAPString
#   orderAcceptanceCity - SOAP::SOAPString
#   orderAcceptanceCounty - SOAP::SOAPString
#   orderAcceptanceCountry - SOAP::SOAPString
#   orderAcceptanceState - SOAP::SOAPString
#   orderAcceptancePostalCode - SOAP::SOAPString
#   orderOriginCity - SOAP::SOAPString
#   orderOriginCounty - SOAP::SOAPString
#   orderOriginCountry - SOAP::SOAPString
#   orderOriginState - SOAP::SOAPString
#   orderOriginPostalCode - SOAP::SOAPString
#   sellerRegistration - SOAP::SOAPString
#   sellerRegistration0 - SOAP::SOAPString
#   sellerRegistration1 - SOAP::SOAPString
#   sellerRegistration2 - SOAP::SOAPString
#   sellerRegistration3 - SOAP::SOAPString
#   sellerRegistration4 - SOAP::SOAPString
#   sellerRegistration5 - SOAP::SOAPString
#   sellerRegistration6 - SOAP::SOAPString
#   sellerRegistration7 - SOAP::SOAPString
#   sellerRegistration8 - SOAP::SOAPString
#   sellerRegistration9 - SOAP::SOAPString
#   buyerRegistration - SOAP::SOAPString
#   middlemanRegistration - SOAP::SOAPString
#   pointOfTitleTransfer - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class TaxService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :nexus
  attr_accessor :noNexus
  attr_accessor :orderAcceptanceCity
  attr_accessor :orderAcceptanceCounty
  attr_accessor :orderAcceptanceCountry
  attr_accessor :orderAcceptanceState
  attr_accessor :orderAcceptancePostalCode
  attr_accessor :orderOriginCity
  attr_accessor :orderOriginCounty
  attr_accessor :orderOriginCountry
  attr_accessor :orderOriginState
  attr_accessor :orderOriginPostalCode
  attr_accessor :sellerRegistration
  attr_accessor :sellerRegistration0
  attr_accessor :sellerRegistration1
  attr_accessor :sellerRegistration2
  attr_accessor :sellerRegistration3
  attr_accessor :sellerRegistration4
  attr_accessor :sellerRegistration5
  attr_accessor :sellerRegistration6
  attr_accessor :sellerRegistration7
  attr_accessor :sellerRegistration8
  attr_accessor :sellerRegistration9
  attr_accessor :buyerRegistration
  attr_accessor :middlemanRegistration
  attr_accessor :pointOfTitleTransfer

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(nexus = nil, noNexus = nil, orderAcceptanceCity = nil, orderAcceptanceCounty = nil, orderAcceptanceCountry = nil, orderAcceptanceState = nil, orderAcceptancePostalCode = nil, orderOriginCity = nil, orderOriginCounty = nil, orderOriginCountry = nil, orderOriginState = nil, orderOriginPostalCode = nil, sellerRegistration = nil, sellerRegistration0 = nil, sellerRegistration1 = nil, sellerRegistration2 = nil, sellerRegistration3 = nil, sellerRegistration4 = nil, sellerRegistration5 = nil, sellerRegistration6 = nil, sellerRegistration7 = nil, sellerRegistration8 = nil, sellerRegistration9 = nil, buyerRegistration = nil, middlemanRegistration = nil, pointOfTitleTransfer = nil)
    @nexus = nexus
    @noNexus = noNexus
    @orderAcceptanceCity = orderAcceptanceCity
    @orderAcceptanceCounty = orderAcceptanceCounty
    @orderAcceptanceCountry = orderAcceptanceCountry
    @orderAcceptanceState = orderAcceptanceState
    @orderAcceptancePostalCode = orderAcceptancePostalCode
    @orderOriginCity = orderOriginCity
    @orderOriginCounty = orderOriginCounty
    @orderOriginCountry = orderOriginCountry
    @orderOriginState = orderOriginState
    @orderOriginPostalCode = orderOriginPostalCode
    @sellerRegistration = sellerRegistration
    @sellerRegistration0 = sellerRegistration0
    @sellerRegistration1 = sellerRegistration1
    @sellerRegistration2 = sellerRegistration2
    @sellerRegistration3 = sellerRegistration3
    @sellerRegistration4 = sellerRegistration4
    @sellerRegistration5 = sellerRegistration5
    @sellerRegistration6 = sellerRegistration6
    @sellerRegistration7 = sellerRegistration7
    @sellerRegistration8 = sellerRegistration8
    @sellerRegistration9 = sellerRegistration9
    @buyerRegistration = buyerRegistration
    @middlemanRegistration = middlemanRegistration
    @pointOfTitleTransfer = pointOfTitleTransfer
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}AFSService
#   avsCode - SOAP::SOAPString
#   cvCode - SOAP::SOAPString
#   disableAVSScoring - (any)
#   customRiskModel - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class AFSService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :avsCode
  attr_accessor :cvCode
  attr_accessor :disableAVSScoring
  attr_accessor :customRiskModel

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(avsCode = nil, cvCode = nil, disableAVSScoring = nil, customRiskModel = nil)
    @avsCode = avsCode
    @cvCode = cvCode
    @disableAVSScoring = disableAVSScoring
    @customRiskModel = customRiskModel
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DAVService
#   xmlattr_run - SOAP::SOAPString
class DAVService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ExportService
#   addressOperator - SOAP::SOAPString
#   addressWeight - SOAP::SOAPString
#   companyWeight - SOAP::SOAPString
#   nameWeight - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class ExportService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :addressOperator
  attr_accessor :addressWeight
  attr_accessor :companyWeight
  attr_accessor :nameWeight

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(addressOperator = nil, addressWeight = nil, companyWeight = nil, nameWeight = nil)
    @addressOperator = addressOperator
    @addressWeight = addressWeight
    @companyWeight = companyWeight
    @nameWeight = nameWeight
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FXRatesService
#   xmlattr_run - SOAP::SOAPString
class FXRatesService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankTransferService
#   xmlattr_run - SOAP::SOAPString
class BankTransferService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankTransferRefundService
#   bankTransferRequestID - SOAP::SOAPString
#   bankTransferRealTimeRequestID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   bankTransferRealTimeReconciliationID - SOAP::SOAPString
#   bankTransferRequestToken - SOAP::SOAPString
#   bankTransferRealTimeRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class BankTransferRefundService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :bankTransferRequestID
  attr_accessor :bankTransferRealTimeRequestID
  attr_accessor :reconciliationID
  attr_accessor :bankTransferRealTimeReconciliationID
  attr_accessor :bankTransferRequestToken
  attr_accessor :bankTransferRealTimeRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(bankTransferRequestID = nil, bankTransferRealTimeRequestID = nil, reconciliationID = nil, bankTransferRealTimeReconciliationID = nil, bankTransferRequestToken = nil, bankTransferRealTimeRequestToken = nil)
    @bankTransferRequestID = bankTransferRequestID
    @bankTransferRealTimeRequestID = bankTransferRealTimeRequestID
    @reconciliationID = reconciliationID
    @bankTransferRealTimeReconciliationID = bankTransferRealTimeReconciliationID
    @bankTransferRequestToken = bankTransferRequestToken
    @bankTransferRealTimeRequestToken = bankTransferRealTimeRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankTransferRealTimeService
#   bankTransferRealTimeType - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class BankTransferRealTimeService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :bankTransferRealTimeType

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(bankTransferRealTimeType = nil)
    @bankTransferRealTimeType = bankTransferRealTimeType
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitMandateService
#   mandateDescriptor - SOAP::SOAPString
#   firstDebitDate - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class DirectDebitMandateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :mandateDescriptor
  attr_accessor :firstDebitDate

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(mandateDescriptor = nil, firstDebitDate = nil)
    @mandateDescriptor = mandateDescriptor
    @firstDebitDate = firstDebitDate
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitService
#   dateCollect - SOAP::SOAPString
#   directDebitText - SOAP::SOAPString
#   authorizationID - SOAP::SOAPString
#   transactionType - SOAP::SOAPString
#   directDebitType - SOAP::SOAPString
#   validateRequestID - SOAP::SOAPString
#   recurringType - SOAP::SOAPString
#   mandateID - SOAP::SOAPString
#   validateRequestToken - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   mandateAuthenticationDate - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class DirectDebitService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :dateCollect
  attr_accessor :directDebitText
  attr_accessor :authorizationID
  attr_accessor :transactionType
  attr_accessor :directDebitType
  attr_accessor :validateRequestID
  attr_accessor :recurringType
  attr_accessor :mandateID
  attr_accessor :validateRequestToken
  attr_accessor :reconciliationID
  attr_accessor :mandateAuthenticationDate

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(dateCollect = nil, directDebitText = nil, authorizationID = nil, transactionType = nil, directDebitType = nil, validateRequestID = nil, recurringType = nil, mandateID = nil, validateRequestToken = nil, reconciliationID = nil, mandateAuthenticationDate = nil)
    @dateCollect = dateCollect
    @directDebitText = directDebitText
    @authorizationID = authorizationID
    @transactionType = transactionType
    @directDebitType = directDebitType
    @validateRequestID = validateRequestID
    @recurringType = recurringType
    @mandateID = mandateID
    @validateRequestToken = validateRequestToken
    @reconciliationID = reconciliationID
    @mandateAuthenticationDate = mandateAuthenticationDate
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitRefundService
#   directDebitRequestID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   directDebitRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class DirectDebitRefundService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :directDebitRequestID
  attr_accessor :reconciliationID
  attr_accessor :directDebitRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(directDebitRequestID = nil, reconciliationID = nil, directDebitRequestToken = nil)
    @directDebitRequestID = directDebitRequestID
    @reconciliationID = reconciliationID
    @directDebitRequestToken = directDebitRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitValidateService
#   directDebitValidateText - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class DirectDebitValidateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :directDebitValidateText

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(directDebitValidateText = nil)
    @directDebitValidateText = directDebitValidateText
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionCreateService
#   paymentRequestID - SOAP::SOAPString
#   paymentRequestToken - SOAP::SOAPString
#   disableAutoAuth - (any)
#   xmlattr_run - SOAP::SOAPString
class PaySubscriptionCreateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paymentRequestID
  attr_accessor :paymentRequestToken
  attr_accessor :disableAutoAuth

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paymentRequestID = nil, paymentRequestToken = nil, disableAutoAuth = nil)
    @paymentRequestID = paymentRequestID
    @paymentRequestToken = paymentRequestToken
    @disableAutoAuth = disableAutoAuth
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionUpdateService
#   xmlattr_run - SOAP::SOAPString
class PaySubscriptionUpdateService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionEventUpdateService
#   action - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PaySubscriptionEventUpdateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :action

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(action = nil)
    @action = action
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionRetrieveService
#   xmlattr_run - SOAP::SOAPString
class PaySubscriptionRetrieveService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionDeleteService
#   xmlattr_run - SOAP::SOAPString
class PaySubscriptionDeleteService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalPaymentService
#   cancelURL - SOAP::SOAPString
#   successURL - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalPaymentService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :cancelURL
  attr_accessor :successURL
  attr_accessor :reconciliationID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(cancelURL = nil, successURL = nil, reconciliationID = nil)
    @cancelURL = cancelURL
    @successURL = successURL
    @reconciliationID = reconciliationID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalCreditService
#   payPalPaymentRequestID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   payPalPaymentRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalCreditService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :payPalPaymentRequestID
  attr_accessor :reconciliationID
  attr_accessor :payPalPaymentRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(payPalPaymentRequestID = nil, reconciliationID = nil, payPalPaymentRequestToken = nil)
    @payPalPaymentRequestID = payPalPaymentRequestID
    @reconciliationID = reconciliationID
    @payPalPaymentRequestToken = payPalPaymentRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcSetService
#   paypalReturn - SOAP::SOAPString
#   paypalCancelReturn - SOAP::SOAPString
#   paypalMaxamt - SOAP::SOAPString
#   paypalCustomerEmail - SOAP::SOAPString
#   paypalDesc - SOAP::SOAPString
#   paypalReqconfirmshipping - SOAP::SOAPString
#   paypalNoshipping - SOAP::SOAPString
#   paypalAddressOverride - SOAP::SOAPString
#   paypalToken - SOAP::SOAPString
#   paypalLc - SOAP::SOAPString
#   paypalPagestyle - SOAP::SOAPString
#   paypalHdrimg - SOAP::SOAPString
#   paypalHdrbordercolor - SOAP::SOAPString
#   paypalHdrbackcolor - SOAP::SOAPString
#   paypalPayflowcolor - SOAP::SOAPString
#   paypalEcSetRequestID - SOAP::SOAPString
#   paypalEcSetRequestToken - SOAP::SOAPString
#   promoCode0 - SOAP::SOAPString
#   requestBillingAddress - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   paypalBillingType - SOAP::SOAPString
#   paypalBillingAgreementDesc - SOAP::SOAPString
#   paypalPaymentType - SOAP::SOAPString
#   paypalBillingAgreementCustom - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalEcSetService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalReturn
  attr_accessor :paypalCancelReturn
  attr_accessor :paypalMaxamt
  attr_accessor :paypalCustomerEmail
  attr_accessor :paypalDesc
  attr_accessor :paypalReqconfirmshipping
  attr_accessor :paypalNoshipping
  attr_accessor :paypalAddressOverride
  attr_accessor :paypalToken
  attr_accessor :paypalLc
  attr_accessor :paypalPagestyle
  attr_accessor :paypalHdrimg
  attr_accessor :paypalHdrbordercolor
  attr_accessor :paypalHdrbackcolor
  attr_accessor :paypalPayflowcolor
  attr_accessor :paypalEcSetRequestID
  attr_accessor :paypalEcSetRequestToken
  attr_accessor :promoCode0
  attr_accessor :requestBillingAddress
  attr_accessor :invoiceNumber
  attr_accessor :paypalBillingType
  attr_accessor :paypalBillingAgreementDesc
  attr_accessor :paypalPaymentType
  attr_accessor :paypalBillingAgreementCustom

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalReturn = nil, paypalCancelReturn = nil, paypalMaxamt = nil, paypalCustomerEmail = nil, paypalDesc = nil, paypalReqconfirmshipping = nil, paypalNoshipping = nil, paypalAddressOverride = nil, paypalToken = nil, paypalLc = nil, paypalPagestyle = nil, paypalHdrimg = nil, paypalHdrbordercolor = nil, paypalHdrbackcolor = nil, paypalPayflowcolor = nil, paypalEcSetRequestID = nil, paypalEcSetRequestToken = nil, promoCode0 = nil, requestBillingAddress = nil, invoiceNumber = nil, paypalBillingType = nil, paypalBillingAgreementDesc = nil, paypalPaymentType = nil, paypalBillingAgreementCustom = nil)
    @paypalReturn = paypalReturn
    @paypalCancelReturn = paypalCancelReturn
    @paypalMaxamt = paypalMaxamt
    @paypalCustomerEmail = paypalCustomerEmail
    @paypalDesc = paypalDesc
    @paypalReqconfirmshipping = paypalReqconfirmshipping
    @paypalNoshipping = paypalNoshipping
    @paypalAddressOverride = paypalAddressOverride
    @paypalToken = paypalToken
    @paypalLc = paypalLc
    @paypalPagestyle = paypalPagestyle
    @paypalHdrimg = paypalHdrimg
    @paypalHdrbordercolor = paypalHdrbordercolor
    @paypalHdrbackcolor = paypalHdrbackcolor
    @paypalPayflowcolor = paypalPayflowcolor
    @paypalEcSetRequestID = paypalEcSetRequestID
    @paypalEcSetRequestToken = paypalEcSetRequestToken
    @promoCode0 = promoCode0
    @requestBillingAddress = requestBillingAddress
    @invoiceNumber = invoiceNumber
    @paypalBillingType = paypalBillingType
    @paypalBillingAgreementDesc = paypalBillingAgreementDesc
    @paypalPaymentType = paypalPaymentType
    @paypalBillingAgreementCustom = paypalBillingAgreementCustom
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcGetDetailsService
#   paypalToken - SOAP::SOAPString
#   paypalEcSetRequestID - SOAP::SOAPString
#   paypalEcSetRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalEcGetDetailsService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalToken
  attr_accessor :paypalEcSetRequestID
  attr_accessor :paypalEcSetRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalToken = nil, paypalEcSetRequestID = nil, paypalEcSetRequestToken = nil)
    @paypalToken = paypalToken
    @paypalEcSetRequestID = paypalEcSetRequestID
    @paypalEcSetRequestToken = paypalEcSetRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcDoPaymentService
#   paypalToken - SOAP::SOAPString
#   paypalPayerId - SOAP::SOAPString
#   paypalCustomerEmail - SOAP::SOAPString
#   paypalDesc - SOAP::SOAPString
#   paypalEcSetRequestID - SOAP::SOAPString
#   paypalEcSetRequestToken - SOAP::SOAPString
#   promoCode0 - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalEcDoPaymentService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalToken
  attr_accessor :paypalPayerId
  attr_accessor :paypalCustomerEmail
  attr_accessor :paypalDesc
  attr_accessor :paypalEcSetRequestID
  attr_accessor :paypalEcSetRequestToken
  attr_accessor :promoCode0
  attr_accessor :invoiceNumber

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalToken = nil, paypalPayerId = nil, paypalCustomerEmail = nil, paypalDesc = nil, paypalEcSetRequestID = nil, paypalEcSetRequestToken = nil, promoCode0 = nil, invoiceNumber = nil)
    @paypalToken = paypalToken
    @paypalPayerId = paypalPayerId
    @paypalCustomerEmail = paypalCustomerEmail
    @paypalDesc = paypalDesc
    @paypalEcSetRequestID = paypalEcSetRequestID
    @paypalEcSetRequestToken = paypalEcSetRequestToken
    @promoCode0 = promoCode0
    @invoiceNumber = invoiceNumber
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalDoCaptureService
#   paypalAuthorizationId - SOAP::SOAPString
#   completeType - SOAP::SOAPString
#   paypalEcDoPaymentRequestID - SOAP::SOAPString
#   paypalEcDoPaymentRequestToken - SOAP::SOAPString
#   paypalAuthorizationRequestID - SOAP::SOAPString
#   paypalAuthorizationRequestToken - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalDoCaptureService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalAuthorizationId
  attr_accessor :completeType
  attr_accessor :paypalEcDoPaymentRequestID
  attr_accessor :paypalEcDoPaymentRequestToken
  attr_accessor :paypalAuthorizationRequestID
  attr_accessor :paypalAuthorizationRequestToken
  attr_accessor :invoiceNumber

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalAuthorizationId = nil, completeType = nil, paypalEcDoPaymentRequestID = nil, paypalEcDoPaymentRequestToken = nil, paypalAuthorizationRequestID = nil, paypalAuthorizationRequestToken = nil, invoiceNumber = nil)
    @paypalAuthorizationId = paypalAuthorizationId
    @completeType = completeType
    @paypalEcDoPaymentRequestID = paypalEcDoPaymentRequestID
    @paypalEcDoPaymentRequestToken = paypalEcDoPaymentRequestToken
    @paypalAuthorizationRequestID = paypalAuthorizationRequestID
    @paypalAuthorizationRequestToken = paypalAuthorizationRequestToken
    @invoiceNumber = invoiceNumber
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalAuthReversalService
#   paypalAuthorizationId - SOAP::SOAPString
#   paypalEcDoPaymentRequestID - SOAP::SOAPString
#   paypalEcDoPaymentRequestToken - SOAP::SOAPString
#   paypalAuthorizationRequestID - SOAP::SOAPString
#   paypalAuthorizationRequestToken - SOAP::SOAPString
#   paypalEcOrderSetupRequestID - SOAP::SOAPString
#   paypalEcOrderSetupRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalAuthReversalService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalAuthorizationId
  attr_accessor :paypalEcDoPaymentRequestID
  attr_accessor :paypalEcDoPaymentRequestToken
  attr_accessor :paypalAuthorizationRequestID
  attr_accessor :paypalAuthorizationRequestToken
  attr_accessor :paypalEcOrderSetupRequestID
  attr_accessor :paypalEcOrderSetupRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalAuthorizationId = nil, paypalEcDoPaymentRequestID = nil, paypalEcDoPaymentRequestToken = nil, paypalAuthorizationRequestID = nil, paypalAuthorizationRequestToken = nil, paypalEcOrderSetupRequestID = nil, paypalEcOrderSetupRequestToken = nil)
    @paypalAuthorizationId = paypalAuthorizationId
    @paypalEcDoPaymentRequestID = paypalEcDoPaymentRequestID
    @paypalEcDoPaymentRequestToken = paypalEcDoPaymentRequestToken
    @paypalAuthorizationRequestID = paypalAuthorizationRequestID
    @paypalAuthorizationRequestToken = paypalAuthorizationRequestToken
    @paypalEcOrderSetupRequestID = paypalEcOrderSetupRequestID
    @paypalEcOrderSetupRequestToken = paypalEcOrderSetupRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalRefundService
#   paypalDoCaptureRequestID - SOAP::SOAPString
#   paypalDoCaptureRequestToken - SOAP::SOAPString
#   paypalCaptureId - SOAP::SOAPString
#   paypalNote - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalRefundService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalDoCaptureRequestID
  attr_accessor :paypalDoCaptureRequestToken
  attr_accessor :paypalCaptureId
  attr_accessor :paypalNote

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalDoCaptureRequestID = nil, paypalDoCaptureRequestToken = nil, paypalCaptureId = nil, paypalNote = nil)
    @paypalDoCaptureRequestID = paypalDoCaptureRequestID
    @paypalDoCaptureRequestToken = paypalDoCaptureRequestToken
    @paypalCaptureId = paypalCaptureId
    @paypalNote = paypalNote
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcOrderSetupService
#   paypalToken - SOAP::SOAPString
#   paypalPayerId - SOAP::SOAPString
#   paypalCustomerEmail - SOAP::SOAPString
#   paypalDesc - SOAP::SOAPString
#   paypalEcSetRequestID - SOAP::SOAPString
#   paypalEcSetRequestToken - SOAP::SOAPString
#   promoCode0 - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalEcOrderSetupService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalToken
  attr_accessor :paypalPayerId
  attr_accessor :paypalCustomerEmail
  attr_accessor :paypalDesc
  attr_accessor :paypalEcSetRequestID
  attr_accessor :paypalEcSetRequestToken
  attr_accessor :promoCode0
  attr_accessor :invoiceNumber

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalToken = nil, paypalPayerId = nil, paypalCustomerEmail = nil, paypalDesc = nil, paypalEcSetRequestID = nil, paypalEcSetRequestToken = nil, promoCode0 = nil, invoiceNumber = nil)
    @paypalToken = paypalToken
    @paypalPayerId = paypalPayerId
    @paypalCustomerEmail = paypalCustomerEmail
    @paypalDesc = paypalDesc
    @paypalEcSetRequestID = paypalEcSetRequestID
    @paypalEcSetRequestToken = paypalEcSetRequestToken
    @promoCode0 = promoCode0
    @invoiceNumber = invoiceNumber
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalAuthorizationService
#   paypalOrderId - SOAP::SOAPString
#   paypalEcOrderSetupRequestID - SOAP::SOAPString
#   paypalEcOrderSetupRequestToken - SOAP::SOAPString
#   paypalDoRefTransactionRequestID - SOAP::SOAPString
#   paypalDoRefTransactionRequestToken - SOAP::SOAPString
#   paypalCustomerEmail - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalAuthorizationService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalOrderId
  attr_accessor :paypalEcOrderSetupRequestID
  attr_accessor :paypalEcOrderSetupRequestToken
  attr_accessor :paypalDoRefTransactionRequestID
  attr_accessor :paypalDoRefTransactionRequestToken
  attr_accessor :paypalCustomerEmail

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalOrderId = nil, paypalEcOrderSetupRequestID = nil, paypalEcOrderSetupRequestToken = nil, paypalDoRefTransactionRequestID = nil, paypalDoRefTransactionRequestToken = nil, paypalCustomerEmail = nil)
    @paypalOrderId = paypalOrderId
    @paypalEcOrderSetupRequestID = paypalEcOrderSetupRequestID
    @paypalEcOrderSetupRequestToken = paypalEcOrderSetupRequestToken
    @paypalDoRefTransactionRequestID = paypalDoRefTransactionRequestID
    @paypalDoRefTransactionRequestToken = paypalDoRefTransactionRequestToken
    @paypalCustomerEmail = paypalCustomerEmail
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalUpdateAgreementService
#   paypalBillingAgreementId - SOAP::SOAPString
#   paypalBillingAgreementStatus - SOAP::SOAPString
#   paypalBillingAgreementDesc - SOAP::SOAPString
#   paypalBillingAgreementCustom - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalUpdateAgreementService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalBillingAgreementId
  attr_accessor :paypalBillingAgreementStatus
  attr_accessor :paypalBillingAgreementDesc
  attr_accessor :paypalBillingAgreementCustom

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalBillingAgreementId = nil, paypalBillingAgreementStatus = nil, paypalBillingAgreementDesc = nil, paypalBillingAgreementCustom = nil)
    @paypalBillingAgreementId = paypalBillingAgreementId
    @paypalBillingAgreementStatus = paypalBillingAgreementStatus
    @paypalBillingAgreementDesc = paypalBillingAgreementDesc
    @paypalBillingAgreementCustom = paypalBillingAgreementCustom
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalCreateAgreementService
#   paypalToken - SOAP::SOAPString
#   paypalEcSetRequestID - SOAP::SOAPString
#   paypalEcSetRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalCreateAgreementService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalToken
  attr_accessor :paypalEcSetRequestID
  attr_accessor :paypalEcSetRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalToken = nil, paypalEcSetRequestID = nil, paypalEcSetRequestToken = nil)
    @paypalToken = paypalToken
    @paypalEcSetRequestID = paypalEcSetRequestID
    @paypalEcSetRequestToken = paypalEcSetRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalDoRefTransactionService
#   paypalBillingAgreementId - SOAP::SOAPString
#   paypalPaymentType - SOAP::SOAPString
#   paypalReqconfirmshipping - SOAP::SOAPString
#   paypalReturnFmfDetails - SOAP::SOAPString
#   paypalSoftDescriptor - SOAP::SOAPString
#   paypalShippingdiscount - SOAP::SOAPString
#   paypalDesc - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   paypalEcNotifyUrl - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalDoRefTransactionService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paypalBillingAgreementId
  attr_accessor :paypalPaymentType
  attr_accessor :paypalReqconfirmshipping
  attr_accessor :paypalReturnFmfDetails
  attr_accessor :paypalSoftDescriptor
  attr_accessor :paypalShippingdiscount
  attr_accessor :paypalDesc
  attr_accessor :invoiceNumber
  attr_accessor :paypalEcNotifyUrl

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paypalBillingAgreementId = nil, paypalPaymentType = nil, paypalReqconfirmshipping = nil, paypalReturnFmfDetails = nil, paypalSoftDescriptor = nil, paypalShippingdiscount = nil, paypalDesc = nil, invoiceNumber = nil, paypalEcNotifyUrl = nil)
    @paypalBillingAgreementId = paypalBillingAgreementId
    @paypalPaymentType = paypalPaymentType
    @paypalReqconfirmshipping = paypalReqconfirmshipping
    @paypalReturnFmfDetails = paypalReturnFmfDetails
    @paypalSoftDescriptor = paypalSoftDescriptor
    @paypalShippingdiscount = paypalShippingdiscount
    @paypalDesc = paypalDesc
    @invoiceNumber = invoiceNumber
    @paypalEcNotifyUrl = paypalEcNotifyUrl
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}VoidService
#   voidRequestID - SOAP::SOAPString
#   voidRequestToken - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class VoidService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :voidRequestID
  attr_accessor :voidRequestToken

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(voidRequestID = nil, voidRequestToken = nil)
    @voidRequestID = voidRequestID
    @voidRequestToken = voidRequestToken
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PinlessDebitService
#   reconciliationID - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PinlessDebitService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :reconciliationID
  attr_accessor :commerceIndicator

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(reconciliationID = nil, commerceIndicator = nil)
    @reconciliationID = reconciliationID
    @commerceIndicator = commerceIndicator
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PinlessDebitValidateService
#   xmlattr_run - SOAP::SOAPString
class PinlessDebitValidateService
  AttrRun = XSD::QName.new(nil, "run")

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PinlessDebitReversalService
#   pinlessDebitRequestID - SOAP::SOAPString
#   pinlessDebitRequestToken - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PinlessDebitReversalService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :pinlessDebitRequestID
  attr_accessor :pinlessDebitRequestToken
  attr_accessor :reconciliationID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(pinlessDebitRequestID = nil, pinlessDebitRequestToken = nil, reconciliationID = nil)
    @pinlessDebitRequestID = pinlessDebitRequestID
    @pinlessDebitRequestToken = pinlessDebitRequestToken
    @reconciliationID = reconciliationID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalButtonCreateService
#   buttonType - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalButtonCreateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :buttonType
  attr_accessor :reconciliationID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(buttonType = nil, reconciliationID = nil)
    @buttonType = buttonType
    @reconciliationID = reconciliationID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalPreapprovedPaymentService
#   mpID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalPreapprovedPaymentService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :mpID
  attr_accessor :reconciliationID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(mpID = nil, reconciliationID = nil)
    @mpID = mpID
    @reconciliationID = reconciliationID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalPreapprovedUpdateService
#   mpID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class PayPalPreapprovedUpdateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :mpID
  attr_accessor :reconciliationID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(mpID = nil, reconciliationID = nil)
    @mpID = mpID
    @reconciliationID = reconciliationID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ChinaPaymentService
#   paymentMode - SOAP::SOAPString
#   returnURL - SOAP::SOAPString
#   pickUpAddress - SOAP::SOAPString
#   pickUpPhoneNumber - SOAP::SOAPString
#   pickUpPostalCode - SOAP::SOAPString
#   pickUpName - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class ChinaPaymentService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :paymentMode
  attr_accessor :returnURL
  attr_accessor :pickUpAddress
  attr_accessor :pickUpPhoneNumber
  attr_accessor :pickUpPostalCode
  attr_accessor :pickUpName

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(paymentMode = nil, returnURL = nil, pickUpAddress = nil, pickUpPhoneNumber = nil, pickUpPostalCode = nil, pickUpName = nil)
    @paymentMode = paymentMode
    @returnURL = returnURL
    @pickUpAddress = pickUpAddress
    @pickUpPhoneNumber = pickUpPhoneNumber
    @pickUpPostalCode = pickUpPostalCode
    @pickUpName = pickUpName
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ChinaRefundService
#   chinaPaymentRequestID - SOAP::SOAPString
#   chinaPaymentRequestToken - SOAP::SOAPString
#   refundReason - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class ChinaRefundService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :chinaPaymentRequestID
  attr_accessor :chinaPaymentRequestToken
  attr_accessor :refundReason

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(chinaPaymentRequestID = nil, chinaPaymentRequestToken = nil, refundReason = nil)
    @chinaPaymentRequestID = chinaPaymentRequestID
    @chinaPaymentRequestToken = chinaPaymentRequestToken
    @refundReason = refundReason
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BoletoPaymentService
#   instruction - SOAP::SOAPString
#   expirationDate - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class BoletoPaymentService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :instruction
  attr_accessor :expirationDate
  attr_accessor :reconciliationID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(instruction = nil, expirationDate = nil, reconciliationID = nil)
    @instruction = instruction
    @expirationDate = expirationDate
    @reconciliationID = reconciliationID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Address
#   street1 - SOAP::SOAPString
#   street2 - SOAP::SOAPString
#   city - SOAP::SOAPString
#   state - SOAP::SOAPString
#   postalCode - SOAP::SOAPString
#   country - SOAP::SOAPString
class Address
  attr_accessor :street1
  attr_accessor :street2
  attr_accessor :city
  attr_accessor :state
  attr_accessor :postalCode
  attr_accessor :country

  def initialize(street1 = nil, street2 = nil, city = nil, state = nil, postalCode = nil, country = nil)
    @street1 = street1
    @street2 = street2
    @city = city
    @state = state
    @postalCode = postalCode
    @country = country
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RiskUpdateService
#   actionCode - SOAP::SOAPString
#   recordID - SOAP::SOAPString
#   recordName - SOAP::SOAPString
#   negativeAddress - CyberSource::Soap::Address
#   markingReason - SOAP::SOAPString
#   markingNotes - SOAP::SOAPString
#   markingRequestID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class RiskUpdateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :actionCode
  attr_accessor :recordID
  attr_accessor :recordName
  attr_accessor :negativeAddress
  attr_accessor :markingReason
  attr_accessor :markingNotes
  attr_accessor :markingRequestID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(actionCode = nil, recordID = nil, recordName = nil, negativeAddress = nil, markingReason = nil, markingNotes = nil, markingRequestID = nil)
    @actionCode = actionCode
    @recordID = recordID
    @recordName = recordName
    @negativeAddress = negativeAddress
    @markingReason = markingReason
    @markingNotes = markingNotes
    @markingRequestID = markingRequestID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FraudUpdateService
#   actionCode - SOAP::SOAPString
#   markedData - SOAP::SOAPString
#   markingReason - SOAP::SOAPString
#   markingNotes - SOAP::SOAPString
#   markingRequestID - SOAP::SOAPString
#   xmlattr_run - SOAP::SOAPString
class FraudUpdateService
  AttrRun = XSD::QName.new(nil, "run")

  attr_accessor :actionCode
  attr_accessor :markedData
  attr_accessor :markingReason
  attr_accessor :markingNotes
  attr_accessor :markingRequestID

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_run
    __xmlattr[AttrRun]
  end

  def xmlattr_run=(value)
    __xmlattr[AttrRun] = value
  end

  def initialize(actionCode = nil, markedData = nil, markingReason = nil, markingNotes = nil, markingRequestID = nil)
    @actionCode = actionCode
    @markedData = markedData
    @markingReason = markingReason
    @markingNotes = markingNotes
    @markingRequestID = markingRequestID
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}InvoiceHeader
#   merchantDescriptor - SOAP::SOAPString
#   merchantDescriptorContact - SOAP::SOAPString
#   merchantDescriptorAlternate - SOAP::SOAPString
#   merchantDescriptorStreet - SOAP::SOAPString
#   merchantDescriptorCity - SOAP::SOAPString
#   merchantDescriptorState - SOAP::SOAPString
#   merchantDescriptorPostalCode - SOAP::SOAPString
#   merchantDescriptorCountry - SOAP::SOAPString
#   isGift - (any)
#   returnsAccepted - (any)
#   tenderType - SOAP::SOAPString
#   merchantVATRegistrationNumber - SOAP::SOAPString
#   purchaserOrderDate - SOAP::SOAPString
#   purchaserVATRegistrationNumber - SOAP::SOAPString
#   vatInvoiceReferenceNumber - SOAP::SOAPString
#   summaryCommodityCode - SOAP::SOAPString
#   supplierOrderReference - SOAP::SOAPString
#   userPO - SOAP::SOAPString
#   costCenter - SOAP::SOAPString
#   purchaserCode - SOAP::SOAPString
#   taxable - (any)
#   amexDataTAA1 - SOAP::SOAPString
#   amexDataTAA2 - SOAP::SOAPString
#   amexDataTAA3 - SOAP::SOAPString
#   amexDataTAA4 - SOAP::SOAPString
#   invoiceDate - SOAP::SOAPString
class InvoiceHeader
  attr_accessor :merchantDescriptor
  attr_accessor :merchantDescriptorContact
  attr_accessor :merchantDescriptorAlternate
  attr_accessor :merchantDescriptorStreet
  attr_accessor :merchantDescriptorCity
  attr_accessor :merchantDescriptorState
  attr_accessor :merchantDescriptorPostalCode
  attr_accessor :merchantDescriptorCountry
  attr_accessor :isGift
  attr_accessor :returnsAccepted
  attr_accessor :tenderType
  attr_accessor :merchantVATRegistrationNumber
  attr_accessor :purchaserOrderDate
  attr_accessor :purchaserVATRegistrationNumber
  attr_accessor :vatInvoiceReferenceNumber
  attr_accessor :summaryCommodityCode
  attr_accessor :supplierOrderReference
  attr_accessor :userPO
  attr_accessor :costCenter
  attr_accessor :purchaserCode
  attr_accessor :taxable
  attr_accessor :amexDataTAA1
  attr_accessor :amexDataTAA2
  attr_accessor :amexDataTAA3
  attr_accessor :amexDataTAA4
  attr_accessor :invoiceDate

  def initialize(merchantDescriptor = nil, merchantDescriptorContact = nil, merchantDescriptorAlternate = nil, merchantDescriptorStreet = nil, merchantDescriptorCity = nil, merchantDescriptorState = nil, merchantDescriptorPostalCode = nil, merchantDescriptorCountry = nil, isGift = nil, returnsAccepted = nil, tenderType = nil, merchantVATRegistrationNumber = nil, purchaserOrderDate = nil, purchaserVATRegistrationNumber = nil, vatInvoiceReferenceNumber = nil, summaryCommodityCode = nil, supplierOrderReference = nil, userPO = nil, costCenter = nil, purchaserCode = nil, taxable = nil, amexDataTAA1 = nil, amexDataTAA2 = nil, amexDataTAA3 = nil, amexDataTAA4 = nil, invoiceDate = nil)
    @merchantDescriptor = merchantDescriptor
    @merchantDescriptorContact = merchantDescriptorContact
    @merchantDescriptorAlternate = merchantDescriptorAlternate
    @merchantDescriptorStreet = merchantDescriptorStreet
    @merchantDescriptorCity = merchantDescriptorCity
    @merchantDescriptorState = merchantDescriptorState
    @merchantDescriptorPostalCode = merchantDescriptorPostalCode
    @merchantDescriptorCountry = merchantDescriptorCountry
    @isGift = isGift
    @returnsAccepted = returnsAccepted
    @tenderType = tenderType
    @merchantVATRegistrationNumber = merchantVATRegistrationNumber
    @purchaserOrderDate = purchaserOrderDate
    @purchaserVATRegistrationNumber = purchaserVATRegistrationNumber
    @vatInvoiceReferenceNumber = vatInvoiceReferenceNumber
    @summaryCommodityCode = summaryCommodityCode
    @supplierOrderReference = supplierOrderReference
    @userPO = userPO
    @costCenter = costCenter
    @purchaserCode = purchaserCode
    @taxable = taxable
    @amexDataTAA1 = amexDataTAA1
    @amexDataTAA2 = amexDataTAA2
    @amexDataTAA3 = amexDataTAA3
    @amexDataTAA4 = amexDataTAA4
    @invoiceDate = invoiceDate
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BusinessRules
#   ignoreAVSResult - (any)
#   ignoreCVResult - (any)
#   ignoreDAVResult - (any)
#   ignoreExportResult - (any)
#   ignoreValidateResult - (any)
#   declineAVSFlags - SOAP::SOAPString
#   scoreThreshold - SOAP::SOAPInteger
class BusinessRules
  attr_accessor :ignoreAVSResult
  attr_accessor :ignoreCVResult
  attr_accessor :ignoreDAVResult
  attr_accessor :ignoreExportResult
  attr_accessor :ignoreValidateResult
  attr_accessor :declineAVSFlags
  attr_accessor :scoreThreshold

  def initialize(ignoreAVSResult = nil, ignoreCVResult = nil, ignoreDAVResult = nil, ignoreExportResult = nil, ignoreValidateResult = nil, declineAVSFlags = nil, scoreThreshold = nil)
    @ignoreAVSResult = ignoreAVSResult
    @ignoreCVResult = ignoreCVResult
    @ignoreDAVResult = ignoreDAVResult
    @ignoreExportResult = ignoreExportResult
    @ignoreValidateResult = ignoreValidateResult
    @declineAVSFlags = declineAVSFlags
    @scoreThreshold = scoreThreshold
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BillTo
#   title - SOAP::SOAPString
#   firstName - SOAP::SOAPString
#   middleName - SOAP::SOAPString
#   lastName - SOAP::SOAPString
#   suffix - SOAP::SOAPString
#   buildingNumber - SOAP::SOAPString
#   street1 - SOAP::SOAPString
#   street2 - SOAP::SOAPString
#   street3 - SOAP::SOAPString
#   street4 - SOAP::SOAPString
#   city - SOAP::SOAPString
#   county - SOAP::SOAPString
#   state - SOAP::SOAPString
#   postalCode - SOAP::SOAPString
#   country - SOAP::SOAPString
#   company - SOAP::SOAPString
#   companyTaxID - SOAP::SOAPString
#   phoneNumber - SOAP::SOAPString
#   email - SOAP::SOAPString
#   ipAddress - SOAP::SOAPString
#   customerPassword - SOAP::SOAPString
#   ipNetworkAddress - SOAP::SOAPString
#   hostname - SOAP::SOAPString
#   domainName - SOAP::SOAPString
#   dateOfBirth - SOAP::SOAPString
#   driversLicenseNumber - SOAP::SOAPString
#   driversLicenseState - SOAP::SOAPString
#   ssn - SOAP::SOAPString
#   customerID - SOAP::SOAPString
#   httpBrowserType - SOAP::SOAPString
#   httpBrowserEmail - SOAP::SOAPString
#   httpBrowserCookiesAccepted - (any)
#   nif - SOAP::SOAPString
#   personalID - SOAP::SOAPString
#   language - SOAP::SOAPString
class BillTo
  attr_accessor :title
  attr_accessor :firstName
  attr_accessor :middleName
  attr_accessor :lastName
  attr_accessor :suffix
  attr_accessor :buildingNumber
  attr_accessor :street1
  attr_accessor :street2
  attr_accessor :street3
  attr_accessor :street4
  attr_accessor :city
  attr_accessor :county
  attr_accessor :state
  attr_accessor :postalCode
  attr_accessor :country
  attr_accessor :company
  attr_accessor :companyTaxID
  attr_accessor :phoneNumber
  attr_accessor :email
  attr_accessor :ipAddress
  attr_accessor :customerPassword
  attr_accessor :ipNetworkAddress
  attr_accessor :hostname
  attr_accessor :domainName
  attr_accessor :dateOfBirth
  attr_accessor :driversLicenseNumber
  attr_accessor :driversLicenseState
  attr_accessor :ssn
  attr_accessor :customerID
  attr_accessor :httpBrowserType
  attr_accessor :httpBrowserEmail
  attr_accessor :httpBrowserCookiesAccepted
  attr_accessor :nif
  attr_accessor :personalID
  attr_accessor :language

  def initialize(title = nil, firstName = nil, middleName = nil, lastName = nil, suffix = nil, buildingNumber = nil, street1 = nil, street2 = nil, street3 = nil, street4 = nil, city = nil, county = nil, state = nil, postalCode = nil, country = nil, company = nil, companyTaxID = nil, phoneNumber = nil, email = nil, ipAddress = nil, customerPassword = nil, ipNetworkAddress = nil, hostname = nil, domainName = nil, dateOfBirth = nil, driversLicenseNumber = nil, driversLicenseState = nil, ssn = nil, customerID = nil, httpBrowserType = nil, httpBrowserEmail = nil, httpBrowserCookiesAccepted = nil, nif = nil, personalID = nil, language = nil)
    @title = title
    @firstName = firstName
    @middleName = middleName
    @lastName = lastName
    @suffix = suffix
    @buildingNumber = buildingNumber
    @street1 = street1
    @street2 = street2
    @street3 = street3
    @street4 = street4
    @city = city
    @county = county
    @state = state
    @postalCode = postalCode
    @country = country
    @company = company
    @companyTaxID = companyTaxID
    @phoneNumber = phoneNumber
    @email = email
    @ipAddress = ipAddress
    @customerPassword = customerPassword
    @ipNetworkAddress = ipNetworkAddress
    @hostname = hostname
    @domainName = domainName
    @dateOfBirth = dateOfBirth
    @driversLicenseNumber = driversLicenseNumber
    @driversLicenseState = driversLicenseState
    @ssn = ssn
    @customerID = customerID
    @httpBrowserType = httpBrowserType
    @httpBrowserEmail = httpBrowserEmail
    @httpBrowserCookiesAccepted = httpBrowserCookiesAccepted
    @nif = nif
    @personalID = personalID
    @language = language
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ShipTo
#   title - SOAP::SOAPString
#   firstName - SOAP::SOAPString
#   middleName - SOAP::SOAPString
#   lastName - SOAP::SOAPString
#   suffix - SOAP::SOAPString
#   street1 - SOAP::SOAPString
#   street2 - SOAP::SOAPString
#   street3 - SOAP::SOAPString
#   street4 - SOAP::SOAPString
#   city - SOAP::SOAPString
#   county - SOAP::SOAPString
#   state - SOAP::SOAPString
#   postalCode - SOAP::SOAPString
#   country - SOAP::SOAPString
#   company - SOAP::SOAPString
#   phoneNumber - SOAP::SOAPString
#   email - SOAP::SOAPString
#   shippingMethod - SOAP::SOAPString
class ShipTo
  attr_accessor :title
  attr_accessor :firstName
  attr_accessor :middleName
  attr_accessor :lastName
  attr_accessor :suffix
  attr_accessor :street1
  attr_accessor :street2
  attr_accessor :street3
  attr_accessor :street4
  attr_accessor :city
  attr_accessor :county
  attr_accessor :state
  attr_accessor :postalCode
  attr_accessor :country
  attr_accessor :company
  attr_accessor :phoneNumber
  attr_accessor :email
  attr_accessor :shippingMethod

  def initialize(title = nil, firstName = nil, middleName = nil, lastName = nil, suffix = nil, street1 = nil, street2 = nil, street3 = nil, street4 = nil, city = nil, county = nil, state = nil, postalCode = nil, country = nil, company = nil, phoneNumber = nil, email = nil, shippingMethod = nil)
    @title = title
    @firstName = firstName
    @middleName = middleName
    @lastName = lastName
    @suffix = suffix
    @street1 = street1
    @street2 = street2
    @street3 = street3
    @street4 = street4
    @city = city
    @county = county
    @state = state
    @postalCode = postalCode
    @country = country
    @company = company
    @phoneNumber = phoneNumber
    @email = email
    @shippingMethod = shippingMethod
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ShipFrom
#   title - SOAP::SOAPString
#   firstName - SOAP::SOAPString
#   middleName - SOAP::SOAPString
#   lastName - SOAP::SOAPString
#   suffix - SOAP::SOAPString
#   street1 - SOAP::SOAPString
#   street2 - SOAP::SOAPString
#   street3 - SOAP::SOAPString
#   street4 - SOAP::SOAPString
#   city - SOAP::SOAPString
#   county - SOAP::SOAPString
#   state - SOAP::SOAPString
#   postalCode - SOAP::SOAPString
#   country - SOAP::SOAPString
#   company - SOAP::SOAPString
#   phoneNumber - SOAP::SOAPString
#   email - SOAP::SOAPString
class ShipFrom
  attr_accessor :title
  attr_accessor :firstName
  attr_accessor :middleName
  attr_accessor :lastName
  attr_accessor :suffix
  attr_accessor :street1
  attr_accessor :street2
  attr_accessor :street3
  attr_accessor :street4
  attr_accessor :city
  attr_accessor :county
  attr_accessor :state
  attr_accessor :postalCode
  attr_accessor :country
  attr_accessor :company
  attr_accessor :phoneNumber
  attr_accessor :email

  def initialize(title = nil, firstName = nil, middleName = nil, lastName = nil, suffix = nil, street1 = nil, street2 = nil, street3 = nil, street4 = nil, city = nil, county = nil, state = nil, postalCode = nil, country = nil, company = nil, phoneNumber = nil, email = nil)
    @title = title
    @firstName = firstName
    @middleName = middleName
    @lastName = lastName
    @suffix = suffix
    @street1 = street1
    @street2 = street2
    @street3 = street3
    @street4 = street4
    @city = city
    @county = county
    @state = state
    @postalCode = postalCode
    @country = country
    @company = company
    @phoneNumber = phoneNumber
    @email = email
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Card
#   fullName - SOAP::SOAPString
#   accountNumber - SOAP::SOAPString
#   expirationMonth - SOAP::SOAPInteger
#   expirationYear - SOAP::SOAPInteger
#   cvIndicator - SOAP::SOAPString
#   cvNumber - SOAP::SOAPString
#   cardType - SOAP::SOAPString
#   issueNumber - SOAP::SOAPString
#   startMonth - SOAP::SOAPInteger
#   startYear - SOAP::SOAPInteger
#   pin - SOAP::SOAPString
#   accountEncoderID - SOAP::SOAPString
#   bin - SOAP::SOAPString
class Card
  attr_accessor :fullName
  attr_accessor :accountNumber
  attr_accessor :expirationMonth
  attr_accessor :expirationYear
  attr_accessor :cvIndicator
  attr_accessor :cvNumber
  attr_accessor :cardType
  attr_accessor :issueNumber
  attr_accessor :startMonth
  attr_accessor :startYear
  attr_accessor :pin
  attr_accessor :accountEncoderID
  attr_accessor :bin

  def initialize(fullName = nil, accountNumber = nil, expirationMonth = nil, expirationYear = nil, cvIndicator = nil, cvNumber = nil, cardType = nil, issueNumber = nil, startMonth = nil, startYear = nil, pin = nil, accountEncoderID = nil, bin = nil)
    @fullName = fullName
    @accountNumber = accountNumber
    @expirationMonth = expirationMonth
    @expirationYear = expirationYear
    @cvIndicator = cvIndicator
    @cvNumber = cvNumber
    @cardType = cardType
    @issueNumber = issueNumber
    @startMonth = startMonth
    @startYear = startYear
    @pin = pin
    @accountEncoderID = accountEncoderID
    @bin = bin
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Check
#   fullName - SOAP::SOAPString
#   accountNumber - SOAP::SOAPString
#   accountType - SOAP::SOAPString
#   bankTransitNumber - SOAP::SOAPString
#   checkNumber - SOAP::SOAPString
#   secCode - SOAP::SOAPString
#   accountEncoderID - SOAP::SOAPString
#   authenticateID - SOAP::SOAPString
#   paymentInfo - SOAP::SOAPString
class Check
  attr_accessor :fullName
  attr_accessor :accountNumber
  attr_accessor :accountType
  attr_accessor :bankTransitNumber
  attr_accessor :checkNumber
  attr_accessor :secCode
  attr_accessor :accountEncoderID
  attr_accessor :authenticateID
  attr_accessor :paymentInfo

  def initialize(fullName = nil, accountNumber = nil, accountType = nil, bankTransitNumber = nil, checkNumber = nil, secCode = nil, accountEncoderID = nil, authenticateID = nil, paymentInfo = nil)
    @fullName = fullName
    @accountNumber = accountNumber
    @accountType = accountType
    @bankTransitNumber = bankTransitNumber
    @checkNumber = checkNumber
    @secCode = secCode
    @accountEncoderID = accountEncoderID
    @authenticateID = authenticateID
    @paymentInfo = paymentInfo
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BML
#   customerBillingAddressChange - (any)
#   customerEmailChange - (any)
#   customerHasCheckingAccount - (any)
#   customerHasSavingsAccount - (any)
#   customerPasswordChange - (any)
#   customerPhoneChange - (any)
#   customerRegistrationDate - SOAP::SOAPString
#   customerTypeFlag - SOAP::SOAPString
#   grossHouseholdIncome - (any)
#   householdIncomeCurrency - SOAP::SOAPString
#   itemCategory - SOAP::SOAPString
#   merchantPromotionCode - SOAP::SOAPString
#   preapprovalNumber - SOAP::SOAPString
#   productDeliveryTypeIndicator - SOAP::SOAPString
#   residenceStatus - SOAP::SOAPString
#   tcVersion - SOAP::SOAPString
#   yearsAtCurrentResidence - SOAP::SOAPInteger
#   yearsWithCurrentEmployer - SOAP::SOAPInteger
#   employerStreet1 - SOAP::SOAPString
#   employerStreet2 - SOAP::SOAPString
#   employerCity - SOAP::SOAPString
#   employerCompanyName - SOAP::SOAPString
#   employerCountry - SOAP::SOAPString
#   employerPhoneNumber - SOAP::SOAPString
#   employerPhoneType - SOAP::SOAPString
#   employerState - SOAP::SOAPString
#   employerPostalCode - SOAP::SOAPString
#   shipToPhoneType - SOAP::SOAPString
#   billToPhoneType - SOAP::SOAPString
#   methodOfPayment - SOAP::SOAPString
#   productType - SOAP::SOAPString
#   customerAuthenticatedByMerchant - SOAP::SOAPString
#   backOfficeIndicator - SOAP::SOAPString
#   shipToEqualsBillToNameIndicator - SOAP::SOAPString
#   shipToEqualsBillToAddressIndicator - SOAP::SOAPString
#   alternateIPAddress - SOAP::SOAPString
#   businessLegalName - SOAP::SOAPString
#   dbaName - SOAP::SOAPString
#   businessAddress1 - SOAP::SOAPString
#   businessAddress2 - SOAP::SOAPString
#   businessCity - SOAP::SOAPString
#   businessState - SOAP::SOAPString
#   businessPostalCode - SOAP::SOAPString
#   businessCountry - SOAP::SOAPString
#   businessMainPhone - SOAP::SOAPString
#   userID - SOAP::SOAPString
#   pin - SOAP::SOAPString
#   adminLastName - SOAP::SOAPString
#   adminFirstName - SOAP::SOAPString
#   adminPhone - SOAP::SOAPString
#   adminFax - SOAP::SOAPString
#   adminEmailAddress - SOAP::SOAPString
#   adminTitle - SOAP::SOAPString
#   supervisorLastName - SOAP::SOAPString
#   supervisorFirstName - SOAP::SOAPString
#   supervisorEmailAddress - SOAP::SOAPString
#   businessDAndBNumber - SOAP::SOAPString
#   businessTaxID - SOAP::SOAPString
#   businessNAICSCode - SOAP::SOAPString
#   businessType - SOAP::SOAPString
#   businessYearsInBusiness - SOAP::SOAPString
#   businessNumberOfEmployees - SOAP::SOAPString
#   businessPONumber - SOAP::SOAPString
#   businessLoanType - SOAP::SOAPString
#   businessApplicationID - SOAP::SOAPString
#   businessProductCode - SOAP::SOAPString
#   pgLastName - SOAP::SOAPString
#   pgFirstName - SOAP::SOAPString
#   pgSSN - SOAP::SOAPString
#   pgDateOfBirth - SOAP::SOAPString
#   pgAnnualIncome - SOAP::SOAPString
#   pgIncomeCurrencyType - SOAP::SOAPString
#   pgResidenceStatus - SOAP::SOAPString
#   pgCheckingAccountIndicator - SOAP::SOAPString
#   pgSavingsAccountIndicator - SOAP::SOAPString
#   pgYearsAtEmployer - SOAP::SOAPString
#   pgYearsAtResidence - SOAP::SOAPString
#   pgHomeAddress1 - SOAP::SOAPString
#   pgHomeAddress2 - SOAP::SOAPString
#   pgHomeCity - SOAP::SOAPString
#   pgHomeState - SOAP::SOAPString
#   pgHomePostalCode - SOAP::SOAPString
#   pgHomeCountry - SOAP::SOAPString
#   pgEmailAddress - SOAP::SOAPString
#   pgHomePhone - SOAP::SOAPString
#   pgTitle - SOAP::SOAPString
class BML
  attr_accessor :customerBillingAddressChange
  attr_accessor :customerEmailChange
  attr_accessor :customerHasCheckingAccount
  attr_accessor :customerHasSavingsAccount
  attr_accessor :customerPasswordChange
  attr_accessor :customerPhoneChange
  attr_accessor :customerRegistrationDate
  attr_accessor :customerTypeFlag
  attr_accessor :grossHouseholdIncome
  attr_accessor :householdIncomeCurrency
  attr_accessor :itemCategory
  attr_accessor :merchantPromotionCode
  attr_accessor :preapprovalNumber
  attr_accessor :productDeliveryTypeIndicator
  attr_accessor :residenceStatus
  attr_accessor :tcVersion
  attr_accessor :yearsAtCurrentResidence
  attr_accessor :yearsWithCurrentEmployer
  attr_accessor :employerStreet1
  attr_accessor :employerStreet2
  attr_accessor :employerCity
  attr_accessor :employerCompanyName
  attr_accessor :employerCountry
  attr_accessor :employerPhoneNumber
  attr_accessor :employerPhoneType
  attr_accessor :employerState
  attr_accessor :employerPostalCode
  attr_accessor :shipToPhoneType
  attr_accessor :billToPhoneType
  attr_accessor :methodOfPayment
  attr_accessor :productType
  attr_accessor :customerAuthenticatedByMerchant
  attr_accessor :backOfficeIndicator
  attr_accessor :shipToEqualsBillToNameIndicator
  attr_accessor :shipToEqualsBillToAddressIndicator
  attr_accessor :alternateIPAddress
  attr_accessor :businessLegalName
  attr_accessor :dbaName
  attr_accessor :businessAddress1
  attr_accessor :businessAddress2
  attr_accessor :businessCity
  attr_accessor :businessState
  attr_accessor :businessPostalCode
  attr_accessor :businessCountry
  attr_accessor :businessMainPhone
  attr_accessor :userID
  attr_accessor :pin
  attr_accessor :adminLastName
  attr_accessor :adminFirstName
  attr_accessor :adminPhone
  attr_accessor :adminFax
  attr_accessor :adminEmailAddress
  attr_accessor :adminTitle
  attr_accessor :supervisorLastName
  attr_accessor :supervisorFirstName
  attr_accessor :supervisorEmailAddress
  attr_accessor :businessDAndBNumber
  attr_accessor :businessTaxID
  attr_accessor :businessNAICSCode
  attr_accessor :businessType
  attr_accessor :businessYearsInBusiness
  attr_accessor :businessNumberOfEmployees
  attr_accessor :businessPONumber
  attr_accessor :businessLoanType
  attr_accessor :businessApplicationID
  attr_accessor :businessProductCode
  attr_accessor :pgLastName
  attr_accessor :pgFirstName
  attr_accessor :pgSSN
  attr_accessor :pgDateOfBirth
  attr_accessor :pgAnnualIncome
  attr_accessor :pgIncomeCurrencyType
  attr_accessor :pgResidenceStatus
  attr_accessor :pgCheckingAccountIndicator
  attr_accessor :pgSavingsAccountIndicator
  attr_accessor :pgYearsAtEmployer
  attr_accessor :pgYearsAtResidence
  attr_accessor :pgHomeAddress1
  attr_accessor :pgHomeAddress2
  attr_accessor :pgHomeCity
  attr_accessor :pgHomeState
  attr_accessor :pgHomePostalCode
  attr_accessor :pgHomeCountry
  attr_accessor :pgEmailAddress
  attr_accessor :pgHomePhone
  attr_accessor :pgTitle

  def initialize(customerBillingAddressChange = nil, customerEmailChange = nil, customerHasCheckingAccount = nil, customerHasSavingsAccount = nil, customerPasswordChange = nil, customerPhoneChange = nil, customerRegistrationDate = nil, customerTypeFlag = nil, grossHouseholdIncome = nil, householdIncomeCurrency = nil, itemCategory = nil, merchantPromotionCode = nil, preapprovalNumber = nil, productDeliveryTypeIndicator = nil, residenceStatus = nil, tcVersion = nil, yearsAtCurrentResidence = nil, yearsWithCurrentEmployer = nil, employerStreet1 = nil, employerStreet2 = nil, employerCity = nil, employerCompanyName = nil, employerCountry = nil, employerPhoneNumber = nil, employerPhoneType = nil, employerState = nil, employerPostalCode = nil, shipToPhoneType = nil, billToPhoneType = nil, methodOfPayment = nil, productType = nil, customerAuthenticatedByMerchant = nil, backOfficeIndicator = nil, shipToEqualsBillToNameIndicator = nil, shipToEqualsBillToAddressIndicator = nil, alternateIPAddress = nil, businessLegalName = nil, dbaName = nil, businessAddress1 = nil, businessAddress2 = nil, businessCity = nil, businessState = nil, businessPostalCode = nil, businessCountry = nil, businessMainPhone = nil, userID = nil, pin = nil, adminLastName = nil, adminFirstName = nil, adminPhone = nil, adminFax = nil, adminEmailAddress = nil, adminTitle = nil, supervisorLastName = nil, supervisorFirstName = nil, supervisorEmailAddress = nil, businessDAndBNumber = nil, businessTaxID = nil, businessNAICSCode = nil, businessType = nil, businessYearsInBusiness = nil, businessNumberOfEmployees = nil, businessPONumber = nil, businessLoanType = nil, businessApplicationID = nil, businessProductCode = nil, pgLastName = nil, pgFirstName = nil, pgSSN = nil, pgDateOfBirth = nil, pgAnnualIncome = nil, pgIncomeCurrencyType = nil, pgResidenceStatus = nil, pgCheckingAccountIndicator = nil, pgSavingsAccountIndicator = nil, pgYearsAtEmployer = nil, pgYearsAtResidence = nil, pgHomeAddress1 = nil, pgHomeAddress2 = nil, pgHomeCity = nil, pgHomeState = nil, pgHomePostalCode = nil, pgHomeCountry = nil, pgEmailAddress = nil, pgHomePhone = nil, pgTitle = nil)
    @customerBillingAddressChange = customerBillingAddressChange
    @customerEmailChange = customerEmailChange
    @customerHasCheckingAccount = customerHasCheckingAccount
    @customerHasSavingsAccount = customerHasSavingsAccount
    @customerPasswordChange = customerPasswordChange
    @customerPhoneChange = customerPhoneChange
    @customerRegistrationDate = customerRegistrationDate
    @customerTypeFlag = customerTypeFlag
    @grossHouseholdIncome = grossHouseholdIncome
    @householdIncomeCurrency = householdIncomeCurrency
    @itemCategory = itemCategory
    @merchantPromotionCode = merchantPromotionCode
    @preapprovalNumber = preapprovalNumber
    @productDeliveryTypeIndicator = productDeliveryTypeIndicator
    @residenceStatus = residenceStatus
    @tcVersion = tcVersion
    @yearsAtCurrentResidence = yearsAtCurrentResidence
    @yearsWithCurrentEmployer = yearsWithCurrentEmployer
    @employerStreet1 = employerStreet1
    @employerStreet2 = employerStreet2
    @employerCity = employerCity
    @employerCompanyName = employerCompanyName
    @employerCountry = employerCountry
    @employerPhoneNumber = employerPhoneNumber
    @employerPhoneType = employerPhoneType
    @employerState = employerState
    @employerPostalCode = employerPostalCode
    @shipToPhoneType = shipToPhoneType
    @billToPhoneType = billToPhoneType
    @methodOfPayment = methodOfPayment
    @productType = productType
    @customerAuthenticatedByMerchant = customerAuthenticatedByMerchant
    @backOfficeIndicator = backOfficeIndicator
    @shipToEqualsBillToNameIndicator = shipToEqualsBillToNameIndicator
    @shipToEqualsBillToAddressIndicator = shipToEqualsBillToAddressIndicator
    @alternateIPAddress = alternateIPAddress
    @businessLegalName = businessLegalName
    @dbaName = dbaName
    @businessAddress1 = businessAddress1
    @businessAddress2 = businessAddress2
    @businessCity = businessCity
    @businessState = businessState
    @businessPostalCode = businessPostalCode
    @businessCountry = businessCountry
    @businessMainPhone = businessMainPhone
    @userID = userID
    @pin = pin
    @adminLastName = adminLastName
    @adminFirstName = adminFirstName
    @adminPhone = adminPhone
    @adminFax = adminFax
    @adminEmailAddress = adminEmailAddress
    @adminTitle = adminTitle
    @supervisorLastName = supervisorLastName
    @supervisorFirstName = supervisorFirstName
    @supervisorEmailAddress = supervisorEmailAddress
    @businessDAndBNumber = businessDAndBNumber
    @businessTaxID = businessTaxID
    @businessNAICSCode = businessNAICSCode
    @businessType = businessType
    @businessYearsInBusiness = businessYearsInBusiness
    @businessNumberOfEmployees = businessNumberOfEmployees
    @businessPONumber = businessPONumber
    @businessLoanType = businessLoanType
    @businessApplicationID = businessApplicationID
    @businessProductCode = businessProductCode
    @pgLastName = pgLastName
    @pgFirstName = pgFirstName
    @pgSSN = pgSSN
    @pgDateOfBirth = pgDateOfBirth
    @pgAnnualIncome = pgAnnualIncome
    @pgIncomeCurrencyType = pgIncomeCurrencyType
    @pgResidenceStatus = pgResidenceStatus
    @pgCheckingAccountIndicator = pgCheckingAccountIndicator
    @pgSavingsAccountIndicator = pgSavingsAccountIndicator
    @pgYearsAtEmployer = pgYearsAtEmployer
    @pgYearsAtResidence = pgYearsAtResidence
    @pgHomeAddress1 = pgHomeAddress1
    @pgHomeAddress2 = pgHomeAddress2
    @pgHomeCity = pgHomeCity
    @pgHomeState = pgHomeState
    @pgHomePostalCode = pgHomePostalCode
    @pgHomeCountry = pgHomeCountry
    @pgEmailAddress = pgEmailAddress
    @pgHomePhone = pgHomePhone
    @pgTitle = pgTitle
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}OtherTax
#   vatTaxAmount - (any)
#   vatTaxRate - (any)
#   alternateTaxAmount - (any)
#   alternateTaxIndicator - (any)
#   alternateTaxID - SOAP::SOAPString
#   localTaxAmount - (any)
#   localTaxIndicator - SOAP::SOAPInteger
#   nationalTaxAmount - (any)
#   nationalTaxIndicator - SOAP::SOAPInteger
class OtherTax
  attr_accessor :vatTaxAmount
  attr_accessor :vatTaxRate
  attr_accessor :alternateTaxAmount
  attr_accessor :alternateTaxIndicator
  attr_accessor :alternateTaxID
  attr_accessor :localTaxAmount
  attr_accessor :localTaxIndicator
  attr_accessor :nationalTaxAmount
  attr_accessor :nationalTaxIndicator

  def initialize(vatTaxAmount = nil, vatTaxRate = nil, alternateTaxAmount = nil, alternateTaxIndicator = nil, alternateTaxID = nil, localTaxAmount = nil, localTaxIndicator = nil, nationalTaxAmount = nil, nationalTaxIndicator = nil)
    @vatTaxAmount = vatTaxAmount
    @vatTaxRate = vatTaxRate
    @alternateTaxAmount = alternateTaxAmount
    @alternateTaxIndicator = alternateTaxIndicator
    @alternateTaxID = alternateTaxID
    @localTaxAmount = localTaxAmount
    @localTaxIndicator = localTaxIndicator
    @nationalTaxAmount = nationalTaxAmount
    @nationalTaxIndicator = nationalTaxIndicator
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PurchaseTotals
#   currency - SOAP::SOAPString
#   discountAmount - (any)
#   taxAmount - (any)
#   dutyAmount - (any)
#   grandTotalAmount - (any)
#   freightAmount - (any)
#   foreignAmount - (any)
#   foreignCurrency - SOAP::SOAPString
#   exchangeRate - (any)
#   exchangeRateTimeStamp - SOAP::SOAPString
class PurchaseTotals
  attr_accessor :currency
  attr_accessor :discountAmount
  attr_accessor :taxAmount
  attr_accessor :dutyAmount
  attr_accessor :grandTotalAmount
  attr_accessor :freightAmount
  attr_accessor :foreignAmount
  attr_accessor :foreignCurrency
  attr_accessor :exchangeRate
  attr_accessor :exchangeRateTimeStamp

  def initialize(currency = nil, discountAmount = nil, taxAmount = nil, dutyAmount = nil, grandTotalAmount = nil, freightAmount = nil, foreignAmount = nil, foreignCurrency = nil, exchangeRate = nil, exchangeRateTimeStamp = nil)
    @currency = currency
    @discountAmount = discountAmount
    @taxAmount = taxAmount
    @dutyAmount = dutyAmount
    @grandTotalAmount = grandTotalAmount
    @freightAmount = freightAmount
    @foreignAmount = foreignAmount
    @foreignCurrency = foreignCurrency
    @exchangeRate = exchangeRate
    @exchangeRateTimeStamp = exchangeRateTimeStamp
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FundingTotals
#   currency - SOAP::SOAPString
#   grandTotalAmount - (any)
class FundingTotals
  attr_accessor :currency
  attr_accessor :grandTotalAmount

  def initialize(currency = nil, grandTotalAmount = nil)
    @currency = currency
    @grandTotalAmount = grandTotalAmount
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}GECC
#   saleType - SOAP::SOAPString
#   planNumber - SOAP::SOAPString
#   sequenceNumber - SOAP::SOAPString
#   promotionEndDate - SOAP::SOAPString
#   promotionPlan - SOAP::SOAPString
#   line - SOAP::SOAPString
class GECC
  attr_accessor :saleType
  attr_accessor :planNumber
  attr_accessor :sequenceNumber
  attr_accessor :promotionEndDate
  attr_accessor :promotionPlan
  attr_accessor :line

  def initialize(saleType = nil, planNumber = nil, sequenceNumber = nil, promotionEndDate = nil, promotionPlan = nil, line = [])
    @saleType = saleType
    @planNumber = planNumber
    @sequenceNumber = sequenceNumber
    @promotionEndDate = promotionEndDate
    @promotionPlan = promotionPlan
    @line = line
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}UCAF
#   authenticationData - SOAP::SOAPString
#   collectionIndicator - SOAP::SOAPString
class UCAF
  attr_accessor :authenticationData
  attr_accessor :collectionIndicator

  def initialize(authenticationData = nil, collectionIndicator = nil)
    @authenticationData = authenticationData
    @collectionIndicator = collectionIndicator
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FundTransfer
#   accountNumber - SOAP::SOAPString
#   accountName - SOAP::SOAPString
#   bankCheckDigit - SOAP::SOAPString
#   iban - SOAP::SOAPString
class FundTransfer
  attr_accessor :accountNumber
  attr_accessor :accountName
  attr_accessor :bankCheckDigit
  attr_accessor :iban

  def initialize(accountNumber = nil, accountName = nil, bankCheckDigit = nil, iban = nil)
    @accountNumber = accountNumber
    @accountName = accountName
    @bankCheckDigit = bankCheckDigit
    @iban = iban
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankInfo
#   bankCode - SOAP::SOAPString
#   name - SOAP::SOAPString
#   address - SOAP::SOAPString
#   city - SOAP::SOAPString
#   country - SOAP::SOAPString
#   branchCode - SOAP::SOAPString
#   swiftCode - SOAP::SOAPString
#   sortCode - SOAP::SOAPString
#   issuerID - SOAP::SOAPString
class BankInfo
  attr_accessor :bankCode
  attr_accessor :name
  attr_accessor :address
  attr_accessor :city
  attr_accessor :country
  attr_accessor :branchCode
  attr_accessor :swiftCode
  attr_accessor :sortCode
  attr_accessor :issuerID

  def initialize(bankCode = nil, name = nil, address = nil, city = nil, country = nil, branchCode = nil, swiftCode = nil, sortCode = nil, issuerID = nil)
    @bankCode = bankCode
    @name = name
    @address = address
    @city = city
    @country = country
    @branchCode = branchCode
    @swiftCode = swiftCode
    @sortCode = sortCode
    @issuerID = issuerID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RecurringSubscriptionInfo
#   subscriptionID - SOAP::SOAPString
#   status - SOAP::SOAPString
#   amount - (any)
#   numberOfPayments - SOAP::SOAPInteger
#   numberOfPaymentsToAdd - SOAP::SOAPInteger
#   automaticRenew - (any)
#   frequency - SOAP::SOAPString
#   startDate - SOAP::SOAPString
#   endDate - SOAP::SOAPString
#   approvalRequired - (any)
#   event - CyberSource::Soap::PaySubscriptionEvent
#   billPayment - (any)
class RecurringSubscriptionInfo
  attr_accessor :subscriptionID
  attr_accessor :status
  attr_accessor :amount
  attr_accessor :numberOfPayments
  attr_accessor :numberOfPaymentsToAdd
  attr_accessor :automaticRenew
  attr_accessor :frequency
  attr_accessor :startDate
  attr_accessor :endDate
  attr_accessor :approvalRequired
  attr_accessor :event
  attr_accessor :billPayment

  def initialize(subscriptionID = nil, status = nil, amount = nil, numberOfPayments = nil, numberOfPaymentsToAdd = nil, automaticRenew = nil, frequency = nil, startDate = nil, endDate = nil, approvalRequired = nil, event = nil, billPayment = nil)
    @subscriptionID = subscriptionID
    @status = status
    @amount = amount
    @numberOfPayments = numberOfPayments
    @numberOfPaymentsToAdd = numberOfPaymentsToAdd
    @automaticRenew = automaticRenew
    @frequency = frequency
    @startDate = startDate
    @endDate = endDate
    @approvalRequired = approvalRequired
    @event = event
    @billPayment = billPayment
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionEvent
#   amount - (any)
#   approvedBy - SOAP::SOAPString
#   number - SOAP::SOAPInteger
class PaySubscriptionEvent
  attr_accessor :amount
  attr_accessor :approvedBy
  attr_accessor :number

  def initialize(amount = nil, approvedBy = nil, number = nil)
    @amount = amount
    @approvedBy = approvedBy
    @number = number
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Subscription
#   title - SOAP::SOAPString
#   paymentMethod - SOAP::SOAPString
class Subscription
  attr_accessor :title
  attr_accessor :paymentMethod

  def initialize(title = nil, paymentMethod = nil)
    @title = title
    @paymentMethod = paymentMethod
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DecisionManager
#   enabled - (any)
#   profile - SOAP::SOAPString
#   travelData - CyberSource::Soap::DecisionManagerTravelData
class DecisionManager
  attr_accessor :enabled
  attr_accessor :profile
  attr_accessor :travelData

  def initialize(enabled = nil, profile = nil, travelData = nil)
    @enabled = enabled
    @profile = profile
    @travelData = travelData
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DecisionManagerTravelData
#   leg - CyberSource::Soap::DecisionManagerTravelLeg
#   departureDateTime - (any)
#   completeRoute - SOAP::SOAPString
#   journeyType - SOAP::SOAPString
class DecisionManagerTravelData
  attr_accessor :leg
  attr_accessor :departureDateTime
  attr_accessor :completeRoute
  attr_accessor :journeyType

  def initialize(leg = [], departureDateTime = nil, completeRoute = nil, journeyType = nil)
    @leg = leg
    @departureDateTime = departureDateTime
    @completeRoute = completeRoute
    @journeyType = journeyType
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DecisionManagerTravelLeg
#   origin - SOAP::SOAPString
#   destination - SOAP::SOAPString
#   xmlattr_id - SOAP::SOAPInteger
class DecisionManagerTravelLeg
  AttrId = XSD::QName.new(nil, "id")

  attr_accessor :origin
  attr_accessor :destination

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_id
    __xmlattr[AttrId]
  end

  def xmlattr_id=(value)
    __xmlattr[AttrId] = value
  end

  def initialize(origin = nil, destination = nil)
    @origin = origin
    @destination = destination
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Batch
#   batchID - SOAP::SOAPString
#   recordID - SOAP::SOAPString
class Batch
  attr_accessor :batchID
  attr_accessor :recordID

  def initialize(batchID = nil, recordID = nil)
    @batchID = batchID
    @recordID = recordID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPal
class PayPal
  attr_reader :__xmlele_any

  def set_any(elements)
    @__xmlele_any = elements
  end

  def initialize
    @__xmlele_any = nil
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}JPO
#   paymentMethod - SOAP::SOAPInteger
#   bonusAmount - (any)
#   bonuses - SOAP::SOAPInteger
#   installments - SOAP::SOAPInteger
class JPO
  attr_accessor :paymentMethod
  attr_accessor :bonusAmount
  attr_accessor :bonuses
  attr_accessor :installments

  def initialize(paymentMethod = nil, bonusAmount = nil, bonuses = nil, installments = nil)
    @paymentMethod = paymentMethod
    @bonusAmount = bonusAmount
    @bonuses = bonuses
    @installments = installments
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RequestMessage
#   merchantID - SOAP::SOAPString
#   merchantReferenceCode - SOAP::SOAPString
#   debtIndicator - (any)
#   clientLibrary - SOAP::SOAPString
#   clientLibraryVersion - SOAP::SOAPString
#   clientEnvironment - SOAP::SOAPString
#   clientSecurityLibraryVersion - SOAP::SOAPString
#   clientApplication - SOAP::SOAPString
#   clientApplicationVersion - SOAP::SOAPString
#   clientApplicationUser - SOAP::SOAPString
#   routingCode - SOAP::SOAPString
#   comments - SOAP::SOAPString
#   returnURL - SOAP::SOAPString
#   invoiceHeader - CyberSource::Soap::InvoiceHeader
#   billTo - CyberSource::Soap::BillTo
#   shipTo - CyberSource::Soap::ShipTo
#   shipFrom - CyberSource::Soap::ShipFrom
#   item - CyberSource::Soap::Item
#   purchaseTotals - CyberSource::Soap::PurchaseTotals
#   fundingTotals - CyberSource::Soap::FundingTotals
#   dcc - CyberSource::Soap::DCC
#   pos - CyberSource::Soap::Pos
#   installment - CyberSource::Soap::Installment
#   card - CyberSource::Soap::Card
#   check - CyberSource::Soap::Check
#   bml - CyberSource::Soap::BML
#   gecc - CyberSource::Soap::GECC
#   ucaf - CyberSource::Soap::UCAF
#   fundTransfer - CyberSource::Soap::FundTransfer
#   bankInfo - CyberSource::Soap::BankInfo
#   subscription - CyberSource::Soap::Subscription
#   recurringSubscriptionInfo - CyberSource::Soap::RecurringSubscriptionInfo
#   decisionManager - CyberSource::Soap::DecisionManager
#   otherTax - CyberSource::Soap::OtherTax
#   paypal - CyberSource::Soap::PayPal
#   merchantDefinedData - CyberSource::Soap::MerchantDefinedData
#   merchantSecureData - CyberSource::Soap::MerchantSecureData
#   jpo - CyberSource::Soap::JPO
#   orderRequestToken - SOAP::SOAPString
#   linkToRequest - SOAP::SOAPString
#   ccAuthService - CyberSource::Soap::CCAuthService
#   ccCaptureService - CyberSource::Soap::CCCaptureService
#   ccCreditService - CyberSource::Soap::CCCreditService
#   ccAuthReversalService - CyberSource::Soap::CCAuthReversalService
#   ccAutoAuthReversalService - CyberSource::Soap::CCAutoAuthReversalService
#   ccDCCService - CyberSource::Soap::CCDCCService
#   ecDebitService - CyberSource::Soap::ECDebitService
#   ecCreditService - CyberSource::Soap::ECCreditService
#   ecAuthenticateService - CyberSource::Soap::ECAuthenticateService
#   payerAuthEnrollService - CyberSource::Soap::PayerAuthEnrollService
#   payerAuthValidateService - CyberSource::Soap::PayerAuthValidateService
#   taxService - CyberSource::Soap::TaxService
#   afsService - CyberSource::Soap::AFSService
#   davService - CyberSource::Soap::DAVService
#   exportService - CyberSource::Soap::ExportService
#   fxRatesService - CyberSource::Soap::FXRatesService
#   bankTransferService - CyberSource::Soap::BankTransferService
#   bankTransferRefundService - CyberSource::Soap::BankTransferRefundService
#   bankTransferRealTimeService - CyberSource::Soap::BankTransferRealTimeService
#   directDebitMandateService - CyberSource::Soap::DirectDebitMandateService
#   directDebitService - CyberSource::Soap::DirectDebitService
#   directDebitRefundService - CyberSource::Soap::DirectDebitRefundService
#   directDebitValidateService - CyberSource::Soap::DirectDebitValidateService
#   paySubscriptionCreateService - CyberSource::Soap::PaySubscriptionCreateService
#   paySubscriptionUpdateService - CyberSource::Soap::PaySubscriptionUpdateService
#   paySubscriptionEventUpdateService - CyberSource::Soap::PaySubscriptionEventUpdateService
#   paySubscriptionRetrieveService - CyberSource::Soap::PaySubscriptionRetrieveService
#   paySubscriptionDeleteService - CyberSource::Soap::PaySubscriptionDeleteService
#   payPalPaymentService - CyberSource::Soap::PayPalPaymentService
#   payPalCreditService - CyberSource::Soap::PayPalCreditService
#   voidService - CyberSource::Soap::VoidService
#   businessRules - CyberSource::Soap::BusinessRules
#   pinlessDebitService - CyberSource::Soap::PinlessDebitService
#   pinlessDebitValidateService - CyberSource::Soap::PinlessDebitValidateService
#   pinlessDebitReversalService - CyberSource::Soap::PinlessDebitReversalService
#   batch - CyberSource::Soap::Batch
#   airlineData - CyberSource::Soap::AirlineData
#   payPalButtonCreateService - CyberSource::Soap::PayPalButtonCreateService
#   payPalPreapprovedPaymentService - CyberSource::Soap::PayPalPreapprovedPaymentService
#   payPalPreapprovedUpdateService - CyberSource::Soap::PayPalPreapprovedUpdateService
#   riskUpdateService - CyberSource::Soap::RiskUpdateService
#   fraudUpdateService - CyberSource::Soap::FraudUpdateService
#   reserved - CyberSource::Soap::RequestReserved
#   deviceFingerprintID - SOAP::SOAPString
#   payPalRefundService - CyberSource::Soap::PayPalRefundService
#   payPalAuthReversalService - CyberSource::Soap::PayPalAuthReversalService
#   payPalDoCaptureService - CyberSource::Soap::PayPalDoCaptureService
#   payPalEcDoPaymentService - CyberSource::Soap::PayPalEcDoPaymentService
#   payPalEcGetDetailsService - CyberSource::Soap::PayPalEcGetDetailsService
#   payPalEcSetService - CyberSource::Soap::PayPalEcSetService
#   payPalEcOrderSetupService - CyberSource::Soap::PayPalEcOrderSetupService
#   payPalAuthorizationService - CyberSource::Soap::PayPalAuthorizationService
#   payPalUpdateAgreementService - CyberSource::Soap::PayPalUpdateAgreementService
#   payPalCreateAgreementService - CyberSource::Soap::PayPalCreateAgreementService
#   payPalDoRefTransactionService - CyberSource::Soap::PayPalDoRefTransactionService
#   chinaPaymentService - CyberSource::Soap::ChinaPaymentService
#   chinaRefundService - CyberSource::Soap::ChinaRefundService
#   boletoPaymentService - CyberSource::Soap::BoletoPaymentService
#   ignoreCardExpiration - (any)
#   reportGroup - SOAP::SOAPString
#   processorID - SOAP::SOAPString
#   solutionProviderTransactionID - SOAP::SOAPString
class RequestMessage
  attr_accessor :merchantID
  attr_accessor :merchantReferenceCode
  attr_accessor :debtIndicator
  attr_accessor :clientLibrary
  attr_accessor :clientLibraryVersion
  attr_accessor :clientEnvironment
  attr_accessor :clientSecurityLibraryVersion
  attr_accessor :clientApplication
  attr_accessor :clientApplicationVersion
  attr_accessor :clientApplicationUser
  attr_accessor :routingCode
  attr_accessor :comments
  attr_accessor :returnURL
  attr_accessor :invoiceHeader
  attr_accessor :billTo
  attr_accessor :shipTo
  attr_accessor :shipFrom
  attr_accessor :item
  attr_accessor :purchaseTotals
  attr_accessor :fundingTotals
  attr_accessor :dcc
  attr_accessor :pos
  attr_accessor :installment
  attr_accessor :card
  attr_accessor :check
  attr_accessor :bml
  attr_accessor :gecc
  attr_accessor :ucaf
  attr_accessor :fundTransfer
  attr_accessor :bankInfo
  attr_accessor :subscription
  attr_accessor :recurringSubscriptionInfo
  attr_accessor :decisionManager
  attr_accessor :otherTax
  attr_accessor :paypal
  attr_accessor :merchantDefinedData
  attr_accessor :merchantSecureData
  attr_accessor :jpo
  attr_accessor :orderRequestToken
  attr_accessor :linkToRequest
  attr_accessor :ccAuthService
  attr_accessor :ccCaptureService
  attr_accessor :ccCreditService
  attr_accessor :ccAuthReversalService
  attr_accessor :ccAutoAuthReversalService
  attr_accessor :ccDCCService
  attr_accessor :ecDebitService
  attr_accessor :ecCreditService
  attr_accessor :ecAuthenticateService
  attr_accessor :payerAuthEnrollService
  attr_accessor :payerAuthValidateService
  attr_accessor :taxService
  attr_accessor :afsService
  attr_accessor :davService
  attr_accessor :exportService
  attr_accessor :fxRatesService
  attr_accessor :bankTransferService
  attr_accessor :bankTransferRefundService
  attr_accessor :bankTransferRealTimeService
  attr_accessor :directDebitMandateService
  attr_accessor :directDebitService
  attr_accessor :directDebitRefundService
  attr_accessor :directDebitValidateService
  attr_accessor :paySubscriptionCreateService
  attr_accessor :paySubscriptionUpdateService
  attr_accessor :paySubscriptionEventUpdateService
  attr_accessor :paySubscriptionRetrieveService
  attr_accessor :paySubscriptionDeleteService
  attr_accessor :payPalPaymentService
  attr_accessor :payPalCreditService
  attr_accessor :voidService
  attr_accessor :businessRules
  attr_accessor :pinlessDebitService
  attr_accessor :pinlessDebitValidateService
  attr_accessor :pinlessDebitReversalService
  attr_accessor :batch
  attr_accessor :airlineData
  attr_accessor :payPalButtonCreateService
  attr_accessor :payPalPreapprovedPaymentService
  attr_accessor :payPalPreapprovedUpdateService
  attr_accessor :riskUpdateService
  attr_accessor :fraudUpdateService
  attr_accessor :reserved
  attr_accessor :deviceFingerprintID
  attr_accessor :payPalRefundService
  attr_accessor :payPalAuthReversalService
  attr_accessor :payPalDoCaptureService
  attr_accessor :payPalEcDoPaymentService
  attr_accessor :payPalEcGetDetailsService
  attr_accessor :payPalEcSetService
  attr_accessor :payPalEcOrderSetupService
  attr_accessor :payPalAuthorizationService
  attr_accessor :payPalUpdateAgreementService
  attr_accessor :payPalCreateAgreementService
  attr_accessor :payPalDoRefTransactionService
  attr_accessor :chinaPaymentService
  attr_accessor :chinaRefundService
  attr_accessor :boletoPaymentService
  attr_accessor :ignoreCardExpiration
  attr_accessor :reportGroup
  attr_accessor :processorID
  attr_accessor :solutionProviderTransactionID

  def initialize(merchantID = nil, merchantReferenceCode = nil, debtIndicator = nil, clientLibrary = nil, clientLibraryVersion = nil, clientEnvironment = nil, clientSecurityLibraryVersion = nil, clientApplication = nil, clientApplicationVersion = nil, clientApplicationUser = nil, routingCode = nil, comments = nil, returnURL = nil, invoiceHeader = nil, billTo = nil, shipTo = nil, shipFrom = nil, item = [], purchaseTotals = nil, fundingTotals = nil, dcc = nil, pos = nil, installment = nil, card = nil, check = nil, bml = nil, gecc = nil, ucaf = nil, fundTransfer = nil, bankInfo = nil, subscription = nil, recurringSubscriptionInfo = nil, decisionManager = nil, otherTax = nil, paypal = nil, merchantDefinedData = nil, merchantSecureData = nil, jpo = nil, orderRequestToken = nil, linkToRequest = nil, ccAuthService = nil, ccCaptureService = nil, ccCreditService = nil, ccAuthReversalService = nil, ccAutoAuthReversalService = nil, ccDCCService = nil, ecDebitService = nil, ecCreditService = nil, ecAuthenticateService = nil, payerAuthEnrollService = nil, payerAuthValidateService = nil, taxService = nil, afsService = nil, davService = nil, exportService = nil, fxRatesService = nil, bankTransferService = nil, bankTransferRefundService = nil, bankTransferRealTimeService = nil, directDebitMandateService = nil, directDebitService = nil, directDebitRefundService = nil, directDebitValidateService = nil, paySubscriptionCreateService = nil, paySubscriptionUpdateService = nil, paySubscriptionEventUpdateService = nil, paySubscriptionRetrieveService = nil, paySubscriptionDeleteService = nil, payPalPaymentService = nil, payPalCreditService = nil, voidService = nil, businessRules = nil, pinlessDebitService = nil, pinlessDebitValidateService = nil, pinlessDebitReversalService = nil, batch = nil, airlineData = nil, payPalButtonCreateService = nil, payPalPreapprovedPaymentService = nil, payPalPreapprovedUpdateService = nil, riskUpdateService = nil, fraudUpdateService = nil, reserved = [], deviceFingerprintID = nil, payPalRefundService = nil, payPalAuthReversalService = nil, payPalDoCaptureService = nil, payPalEcDoPaymentService = nil, payPalEcGetDetailsService = nil, payPalEcSetService = nil, payPalEcOrderSetupService = nil, payPalAuthorizationService = nil, payPalUpdateAgreementService = nil, payPalCreateAgreementService = nil, payPalDoRefTransactionService = nil, chinaPaymentService = nil, chinaRefundService = nil, boletoPaymentService = nil, ignoreCardExpiration = nil, reportGroup = nil, processorID = nil, solutionProviderTransactionID = nil)
    @merchantID = merchantID
    @merchantReferenceCode = merchantReferenceCode
    @debtIndicator = debtIndicator
    @clientLibrary = clientLibrary
    @clientLibraryVersion = clientLibraryVersion
    @clientEnvironment = clientEnvironment
    @clientSecurityLibraryVersion = clientSecurityLibraryVersion
    @clientApplication = clientApplication
    @clientApplicationVersion = clientApplicationVersion
    @clientApplicationUser = clientApplicationUser
    @routingCode = routingCode
    @comments = comments
    @returnURL = returnURL
    @invoiceHeader = invoiceHeader
    @billTo = billTo
    @shipTo = shipTo
    @shipFrom = shipFrom
    @item = item
    @purchaseTotals = purchaseTotals
    @fundingTotals = fundingTotals
    @dcc = dcc
    @pos = pos
    @installment = installment
    @card = card
    @check = check
    @bml = bml
    @gecc = gecc
    @ucaf = ucaf
    @fundTransfer = fundTransfer
    @bankInfo = bankInfo
    @subscription = subscription
    @recurringSubscriptionInfo = recurringSubscriptionInfo
    @decisionManager = decisionManager
    @otherTax = otherTax
    @paypal = paypal
    @merchantDefinedData = merchantDefinedData
    @merchantSecureData = merchantSecureData
    @jpo = jpo
    @orderRequestToken = orderRequestToken
    @linkToRequest = linkToRequest
    @ccAuthService = ccAuthService
    @ccCaptureService = ccCaptureService
    @ccCreditService = ccCreditService
    @ccAuthReversalService = ccAuthReversalService
    @ccAutoAuthReversalService = ccAutoAuthReversalService
    @ccDCCService = ccDCCService
    @ecDebitService = ecDebitService
    @ecCreditService = ecCreditService
    @ecAuthenticateService = ecAuthenticateService
    @payerAuthEnrollService = payerAuthEnrollService
    @payerAuthValidateService = payerAuthValidateService
    @taxService = taxService
    @afsService = afsService
    @davService = davService
    @exportService = exportService
    @fxRatesService = fxRatesService
    @bankTransferService = bankTransferService
    @bankTransferRefundService = bankTransferRefundService
    @bankTransferRealTimeService = bankTransferRealTimeService
    @directDebitMandateService = directDebitMandateService
    @directDebitService = directDebitService
    @directDebitRefundService = directDebitRefundService
    @directDebitValidateService = directDebitValidateService
    @paySubscriptionCreateService = paySubscriptionCreateService
    @paySubscriptionUpdateService = paySubscriptionUpdateService
    @paySubscriptionEventUpdateService = paySubscriptionEventUpdateService
    @paySubscriptionRetrieveService = paySubscriptionRetrieveService
    @paySubscriptionDeleteService = paySubscriptionDeleteService
    @payPalPaymentService = payPalPaymentService
    @payPalCreditService = payPalCreditService
    @voidService = voidService
    @businessRules = businessRules
    @pinlessDebitService = pinlessDebitService
    @pinlessDebitValidateService = pinlessDebitValidateService
    @pinlessDebitReversalService = pinlessDebitReversalService
    @batch = batch
    @airlineData = airlineData
    @payPalButtonCreateService = payPalButtonCreateService
    @payPalPreapprovedPaymentService = payPalPreapprovedPaymentService
    @payPalPreapprovedUpdateService = payPalPreapprovedUpdateService
    @riskUpdateService = riskUpdateService
    @fraudUpdateService = fraudUpdateService
    @reserved = reserved
    @deviceFingerprintID = deviceFingerprintID
    @payPalRefundService = payPalRefundService
    @payPalAuthReversalService = payPalAuthReversalService
    @payPalDoCaptureService = payPalDoCaptureService
    @payPalEcDoPaymentService = payPalEcDoPaymentService
    @payPalEcGetDetailsService = payPalEcGetDetailsService
    @payPalEcSetService = payPalEcSetService
    @payPalEcOrderSetupService = payPalEcOrderSetupService
    @payPalAuthorizationService = payPalAuthorizationService
    @payPalUpdateAgreementService = payPalUpdateAgreementService
    @payPalCreateAgreementService = payPalCreateAgreementService
    @payPalDoRefTransactionService = payPalDoRefTransactionService
    @chinaPaymentService = chinaPaymentService
    @chinaRefundService = chinaRefundService
    @boletoPaymentService = boletoPaymentService
    @ignoreCardExpiration = ignoreCardExpiration
    @reportGroup = reportGroup
    @processorID = processorID
    @solutionProviderTransactionID = solutionProviderTransactionID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DCC
#   dccIndicator - SOAP::SOAPInteger
class DCC
  attr_accessor :dccIndicator

  def initialize(dccIndicator = nil)
    @dccIndicator = dccIndicator
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCAuthReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   authorizationCode - SOAP::SOAPString
#   avsCode - SOAP::SOAPString
#   avsCodeRaw - SOAP::SOAPString
#   cvCode - SOAP::SOAPString
#   cvCodeRaw - SOAP::SOAPString
#   personalIDCode - SOAP::SOAPString
#   authorizedDateTime - (any)
#   processorResponse - SOAP::SOAPString
#   bmlAccountNumber - SOAP::SOAPString
#   authFactorCode - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   fundingTotals - CyberSource::Soap::FundingTotals
#   fxQuoteID - SOAP::SOAPString
#   fxQuoteRate - (any)
#   fxQuoteType - SOAP::SOAPString
#   fxQuoteExpirationDateTime - (any)
#   authRecord - SOAP::SOAPString
#   merchantAdviceCode - SOAP::SOAPString
#   merchantAdviceCodeRaw - SOAP::SOAPString
#   cavvResponseCode - SOAP::SOAPString
#   cavvResponseCodeRaw - SOAP::SOAPString
#   authenticationXID - SOAP::SOAPString
#   authorizationXID - SOAP::SOAPString
#   processorCardType - SOAP::SOAPString
#   accountBalance - (any)
#   forwardCode - SOAP::SOAPString
#   enhancedDataEnabled - SOAP::SOAPString
#   referralResponseNumber - SOAP::SOAPString
#   subResponseCode - SOAP::SOAPString
#   approvedAmount - SOAP::SOAPString
#   creditLine - SOAP::SOAPString
#   approvedTerms - SOAP::SOAPString
#   paymentNetworkTransactionID - SOAP::SOAPString
#   cardCategory - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
#   requestAmount - (any)
#   requestCurrency - SOAP::SOAPString
#   accountBalanceCurrency - SOAP::SOAPString
#   accountBalanceSign - SOAP::SOAPString
#   affluenceIndicator - SOAP::SOAPString
#   evEmail - SOAP::SOAPString
#   evPhoneNumber - SOAP::SOAPString
#   evPostalCode - SOAP::SOAPString
#   evName - SOAP::SOAPString
#   evStreet - SOAP::SOAPString
#   evEmailRaw - SOAP::SOAPString
#   evPhoneNumberRaw - SOAP::SOAPString
#   evPostalCodeRaw - SOAP::SOAPString
#   evNameRaw - SOAP::SOAPString
#   evStreetRaw - SOAP::SOAPString
#   cardGroup - SOAP::SOAPString
#   posData - SOAP::SOAPString
#   transactionID - SOAP::SOAPString
class CCAuthReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :authorizationCode
  attr_accessor :avsCode
  attr_accessor :avsCodeRaw
  attr_accessor :cvCode
  attr_accessor :cvCodeRaw
  attr_accessor :personalIDCode
  attr_accessor :authorizedDateTime
  attr_accessor :processorResponse
  attr_accessor :bmlAccountNumber
  attr_accessor :authFactorCode
  attr_accessor :reconciliationID
  attr_accessor :fundingTotals
  attr_accessor :fxQuoteID
  attr_accessor :fxQuoteRate
  attr_accessor :fxQuoteType
  attr_accessor :fxQuoteExpirationDateTime
  attr_accessor :authRecord
  attr_accessor :merchantAdviceCode
  attr_accessor :merchantAdviceCodeRaw
  attr_accessor :cavvResponseCode
  attr_accessor :cavvResponseCodeRaw
  attr_accessor :authenticationXID
  attr_accessor :authorizationXID
  attr_accessor :processorCardType
  attr_accessor :accountBalance
  attr_accessor :forwardCode
  attr_accessor :enhancedDataEnabled
  attr_accessor :referralResponseNumber
  attr_accessor :subResponseCode
  attr_accessor :approvedAmount
  attr_accessor :creditLine
  attr_accessor :approvedTerms
  attr_accessor :paymentNetworkTransactionID
  attr_accessor :cardCategory
  attr_accessor :ownerMerchantID
  attr_accessor :requestAmount
  attr_accessor :requestCurrency
  attr_accessor :accountBalanceCurrency
  attr_accessor :accountBalanceSign
  attr_accessor :affluenceIndicator
  attr_accessor :evEmail
  attr_accessor :evPhoneNumber
  attr_accessor :evPostalCode
  attr_accessor :evName
  attr_accessor :evStreet
  attr_accessor :evEmailRaw
  attr_accessor :evPhoneNumberRaw
  attr_accessor :evPostalCodeRaw
  attr_accessor :evNameRaw
  attr_accessor :evStreetRaw
  attr_accessor :cardGroup
  attr_accessor :posData
  attr_accessor :transactionID

  def initialize(reasonCode = nil, amount = nil, authorizationCode = nil, avsCode = nil, avsCodeRaw = nil, cvCode = nil, cvCodeRaw = nil, personalIDCode = nil, authorizedDateTime = nil, processorResponse = nil, bmlAccountNumber = nil, authFactorCode = nil, reconciliationID = nil, fundingTotals = nil, fxQuoteID = nil, fxQuoteRate = nil, fxQuoteType = nil, fxQuoteExpirationDateTime = nil, authRecord = nil, merchantAdviceCode = nil, merchantAdviceCodeRaw = nil, cavvResponseCode = nil, cavvResponseCodeRaw = nil, authenticationXID = nil, authorizationXID = nil, processorCardType = nil, accountBalance = nil, forwardCode = nil, enhancedDataEnabled = nil, referralResponseNumber = nil, subResponseCode = nil, approvedAmount = nil, creditLine = nil, approvedTerms = nil, paymentNetworkTransactionID = nil, cardCategory = nil, ownerMerchantID = nil, requestAmount = nil, requestCurrency = nil, accountBalanceCurrency = nil, accountBalanceSign = nil, affluenceIndicator = nil, evEmail = nil, evPhoneNumber = nil, evPostalCode = nil, evName = nil, evStreet = nil, evEmailRaw = nil, evPhoneNumberRaw = nil, evPostalCodeRaw = nil, evNameRaw = nil, evStreetRaw = nil, cardGroup = nil, posData = nil, transactionID = nil)
    @reasonCode = reasonCode
    @amount = amount
    @authorizationCode = authorizationCode
    @avsCode = avsCode
    @avsCodeRaw = avsCodeRaw
    @cvCode = cvCode
    @cvCodeRaw = cvCodeRaw
    @personalIDCode = personalIDCode
    @authorizedDateTime = authorizedDateTime
    @processorResponse = processorResponse
    @bmlAccountNumber = bmlAccountNumber
    @authFactorCode = authFactorCode
    @reconciliationID = reconciliationID
    @fundingTotals = fundingTotals
    @fxQuoteID = fxQuoteID
    @fxQuoteRate = fxQuoteRate
    @fxQuoteType = fxQuoteType
    @fxQuoteExpirationDateTime = fxQuoteExpirationDateTime
    @authRecord = authRecord
    @merchantAdviceCode = merchantAdviceCode
    @merchantAdviceCodeRaw = merchantAdviceCodeRaw
    @cavvResponseCode = cavvResponseCode
    @cavvResponseCodeRaw = cavvResponseCodeRaw
    @authenticationXID = authenticationXID
    @authorizationXID = authorizationXID
    @processorCardType = processorCardType
    @accountBalance = accountBalance
    @forwardCode = forwardCode
    @enhancedDataEnabled = enhancedDataEnabled
    @referralResponseNumber = referralResponseNumber
    @subResponseCode = subResponseCode
    @approvedAmount = approvedAmount
    @creditLine = creditLine
    @approvedTerms = approvedTerms
    @paymentNetworkTransactionID = paymentNetworkTransactionID
    @cardCategory = cardCategory
    @ownerMerchantID = ownerMerchantID
    @requestAmount = requestAmount
    @requestCurrency = requestCurrency
    @accountBalanceCurrency = accountBalanceCurrency
    @accountBalanceSign = accountBalanceSign
    @affluenceIndicator = affluenceIndicator
    @evEmail = evEmail
    @evPhoneNumber = evPhoneNumber
    @evPostalCode = evPostalCode
    @evName = evName
    @evStreet = evStreet
    @evEmailRaw = evEmailRaw
    @evPhoneNumberRaw = evPhoneNumberRaw
    @evPostalCodeRaw = evPostalCodeRaw
    @evNameRaw = evNameRaw
    @evStreetRaw = evStreetRaw
    @cardGroup = cardGroup
    @posData = posData
    @transactionID = transactionID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCCaptureReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   amount - (any)
#   reconciliationID - SOAP::SOAPString
#   fundingTotals - CyberSource::Soap::FundingTotals
#   fxQuoteID - SOAP::SOAPString
#   fxQuoteRate - (any)
#   fxQuoteType - SOAP::SOAPString
#   fxQuoteExpirationDateTime - (any)
#   purchasingLevel3Enabled - SOAP::SOAPString
#   enhancedDataEnabled - SOAP::SOAPString
class CCCaptureReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :reconciliationID
  attr_accessor :fundingTotals
  attr_accessor :fxQuoteID
  attr_accessor :fxQuoteRate
  attr_accessor :fxQuoteType
  attr_accessor :fxQuoteExpirationDateTime
  attr_accessor :purchasingLevel3Enabled
  attr_accessor :enhancedDataEnabled

  def initialize(reasonCode = nil, requestDateTime = nil, amount = nil, reconciliationID = nil, fundingTotals = nil, fxQuoteID = nil, fxQuoteRate = nil, fxQuoteType = nil, fxQuoteExpirationDateTime = nil, purchasingLevel3Enabled = nil, enhancedDataEnabled = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @amount = amount
    @reconciliationID = reconciliationID
    @fundingTotals = fundingTotals
    @fxQuoteID = fxQuoteID
    @fxQuoteRate = fxQuoteRate
    @fxQuoteType = fxQuoteType
    @fxQuoteExpirationDateTime = fxQuoteExpirationDateTime
    @purchasingLevel3Enabled = purchasingLevel3Enabled
    @enhancedDataEnabled = enhancedDataEnabled
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCCreditReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   amount - (any)
#   reconciliationID - SOAP::SOAPString
#   purchasingLevel3Enabled - SOAP::SOAPString
#   enhancedDataEnabled - SOAP::SOAPString
#   authorizationXID - SOAP::SOAPString
#   forwardCode - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
class CCCreditReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :reconciliationID
  attr_accessor :purchasingLevel3Enabled
  attr_accessor :enhancedDataEnabled
  attr_accessor :authorizationXID
  attr_accessor :forwardCode
  attr_accessor :ownerMerchantID

  def initialize(reasonCode = nil, requestDateTime = nil, amount = nil, reconciliationID = nil, purchasingLevel3Enabled = nil, enhancedDataEnabled = nil, authorizationXID = nil, forwardCode = nil, ownerMerchantID = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @amount = amount
    @reconciliationID = reconciliationID
    @purchasingLevel3Enabled = purchasingLevel3Enabled
    @enhancedDataEnabled = enhancedDataEnabled
    @authorizationXID = authorizationXID
    @forwardCode = forwardCode
    @ownerMerchantID = ownerMerchantID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCAuthReversalReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   authorizationCode - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
#   requestDateTime - (any)
#   forwardCode - SOAP::SOAPString
class CCAuthReversalReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :authorizationCode
  attr_accessor :processorResponse
  attr_accessor :requestDateTime
  attr_accessor :forwardCode

  def initialize(reasonCode = nil, amount = nil, authorizationCode = nil, processorResponse = nil, requestDateTime = nil, forwardCode = nil)
    @reasonCode = reasonCode
    @amount = amount
    @authorizationCode = authorizationCode
    @processorResponse = processorResponse
    @requestDateTime = requestDateTime
    @forwardCode = forwardCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCAutoAuthReversalReply
#   reasonCode - SOAP::SOAPInteger
#   processorResponse - SOAP::SOAPString
#   result - SOAP::SOAPString
class CCAutoAuthReversalReply
  attr_accessor :reasonCode
  attr_accessor :processorResponse
  attr_accessor :result

  def initialize(reasonCode = nil, processorResponse = nil, result = nil)
    @reasonCode = reasonCode
    @processorResponse = processorResponse
    @result = result
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ECDebitReply
#   reasonCode - SOAP::SOAPInteger
#   settlementMethod - SOAP::SOAPString
#   requestDateTime - (any)
#   amount - (any)
#   verificationLevel - SOAP::SOAPInteger
#   processorTransactionID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
#   avsCode - SOAP::SOAPString
#   avsCodeRaw - SOAP::SOAPString
#   verificationCode - SOAP::SOAPString
#   verificationCodeRaw - SOAP::SOAPString
#   correctedAccountNumber - SOAP::SOAPString
#   correctedRoutingNumber - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
class ECDebitReply
  attr_accessor :reasonCode
  attr_accessor :settlementMethod
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :verificationLevel
  attr_accessor :processorTransactionID
  attr_accessor :reconciliationID
  attr_accessor :processorResponse
  attr_accessor :avsCode
  attr_accessor :avsCodeRaw
  attr_accessor :verificationCode
  attr_accessor :verificationCodeRaw
  attr_accessor :correctedAccountNumber
  attr_accessor :correctedRoutingNumber
  attr_accessor :ownerMerchantID

  def initialize(reasonCode = nil, settlementMethod = nil, requestDateTime = nil, amount = nil, verificationLevel = nil, processorTransactionID = nil, reconciliationID = nil, processorResponse = nil, avsCode = nil, avsCodeRaw = nil, verificationCode = nil, verificationCodeRaw = nil, correctedAccountNumber = nil, correctedRoutingNumber = nil, ownerMerchantID = nil)
    @reasonCode = reasonCode
    @settlementMethod = settlementMethod
    @requestDateTime = requestDateTime
    @amount = amount
    @verificationLevel = verificationLevel
    @processorTransactionID = processorTransactionID
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
    @avsCode = avsCode
    @avsCodeRaw = avsCodeRaw
    @verificationCode = verificationCode
    @verificationCodeRaw = verificationCodeRaw
    @correctedAccountNumber = correctedAccountNumber
    @correctedRoutingNumber = correctedRoutingNumber
    @ownerMerchantID = ownerMerchantID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ECCreditReply
#   reasonCode - SOAP::SOAPInteger
#   settlementMethod - SOAP::SOAPString
#   requestDateTime - (any)
#   amount - (any)
#   processorTransactionID - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
#   verificationCode - SOAP::SOAPString
#   verificationCodeRaw - SOAP::SOAPString
#   correctedAccountNumber - SOAP::SOAPString
#   correctedRoutingNumber - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
class ECCreditReply
  attr_accessor :reasonCode
  attr_accessor :settlementMethod
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :processorTransactionID
  attr_accessor :reconciliationID
  attr_accessor :processorResponse
  attr_accessor :verificationCode
  attr_accessor :verificationCodeRaw
  attr_accessor :correctedAccountNumber
  attr_accessor :correctedRoutingNumber
  attr_accessor :ownerMerchantID

  def initialize(reasonCode = nil, settlementMethod = nil, requestDateTime = nil, amount = nil, processorTransactionID = nil, reconciliationID = nil, processorResponse = nil, verificationCode = nil, verificationCodeRaw = nil, correctedAccountNumber = nil, correctedRoutingNumber = nil, ownerMerchantID = nil)
    @reasonCode = reasonCode
    @settlementMethod = settlementMethod
    @requestDateTime = requestDateTime
    @amount = amount
    @processorTransactionID = processorTransactionID
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
    @verificationCode = verificationCode
    @verificationCodeRaw = verificationCodeRaw
    @correctedAccountNumber = correctedAccountNumber
    @correctedRoutingNumber = correctedRoutingNumber
    @ownerMerchantID = ownerMerchantID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ECAuthenticateReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   processorResponse - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   checkpointSummary - SOAP::SOAPString
#   fraudShieldIndicators - SOAP::SOAPString
class ECAuthenticateReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :processorResponse
  attr_accessor :reconciliationID
  attr_accessor :checkpointSummary
  attr_accessor :fraudShieldIndicators

  def initialize(reasonCode = nil, requestDateTime = nil, processorResponse = nil, reconciliationID = nil, checkpointSummary = nil, fraudShieldIndicators = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @processorResponse = processorResponse
    @reconciliationID = reconciliationID
    @checkpointSummary = checkpointSummary
    @fraudShieldIndicators = fraudShieldIndicators
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayerAuthEnrollReply
#   reasonCode - SOAP::SOAPInteger
#   acsURL - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   eci - SOAP::SOAPString
#   paReq - SOAP::SOAPString
#   proxyPAN - SOAP::SOAPString
#   xid - SOAP::SOAPString
#   proofXML - SOAP::SOAPString
#   ucafCollectionIndicator - SOAP::SOAPString
#   veresEnrolled - SOAP::SOAPString
#   authenticationPath - SOAP::SOAPString
class PayerAuthEnrollReply
  attr_accessor :reasonCode
  attr_accessor :acsURL
  attr_accessor :commerceIndicator
  attr_accessor :eci
  attr_accessor :paReq
  attr_accessor :proxyPAN
  attr_accessor :xid
  attr_accessor :proofXML
  attr_accessor :ucafCollectionIndicator
  attr_accessor :veresEnrolled
  attr_accessor :authenticationPath

  def initialize(reasonCode = nil, acsURL = nil, commerceIndicator = nil, eci = nil, paReq = nil, proxyPAN = nil, xid = nil, proofXML = nil, ucafCollectionIndicator = nil, veresEnrolled = nil, authenticationPath = nil)
    @reasonCode = reasonCode
    @acsURL = acsURL
    @commerceIndicator = commerceIndicator
    @eci = eci
    @paReq = paReq
    @proxyPAN = proxyPAN
    @xid = xid
    @proofXML = proofXML
    @ucafCollectionIndicator = ucafCollectionIndicator
    @veresEnrolled = veresEnrolled
    @authenticationPath = authenticationPath
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayerAuthValidateReply
#   reasonCode - SOAP::SOAPInteger
#   authenticationResult - SOAP::SOAPString
#   authenticationStatusMessage - SOAP::SOAPString
#   cavv - SOAP::SOAPString
#   cavvAlgorithm - SOAP::SOAPString
#   commerceIndicator - SOAP::SOAPString
#   eci - SOAP::SOAPString
#   eciRaw - SOAP::SOAPString
#   xid - SOAP::SOAPString
#   ucafAuthenticationData - SOAP::SOAPString
#   ucafCollectionIndicator - SOAP::SOAPString
#   paresStatus - SOAP::SOAPString
class PayerAuthValidateReply
  attr_accessor :reasonCode
  attr_accessor :authenticationResult
  attr_accessor :authenticationStatusMessage
  attr_accessor :cavv
  attr_accessor :cavvAlgorithm
  attr_accessor :commerceIndicator
  attr_accessor :eci
  attr_accessor :eciRaw
  attr_accessor :xid
  attr_accessor :ucafAuthenticationData
  attr_accessor :ucafCollectionIndicator
  attr_accessor :paresStatus

  def initialize(reasonCode = nil, authenticationResult = nil, authenticationStatusMessage = nil, cavv = nil, cavvAlgorithm = nil, commerceIndicator = nil, eci = nil, eciRaw = nil, xid = nil, ucafAuthenticationData = nil, ucafCollectionIndicator = nil, paresStatus = nil)
    @reasonCode = reasonCode
    @authenticationResult = authenticationResult
    @authenticationStatusMessage = authenticationStatusMessage
    @cavv = cavv
    @cavvAlgorithm = cavvAlgorithm
    @commerceIndicator = commerceIndicator
    @eci = eci
    @eciRaw = eciRaw
    @xid = xid
    @ucafAuthenticationData = ucafAuthenticationData
    @ucafCollectionIndicator = ucafCollectionIndicator
    @paresStatus = paresStatus
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}TaxReplyItem
#   cityTaxAmount - (any)
#   countyTaxAmount - (any)
#   districtTaxAmount - (any)
#   stateTaxAmount - (any)
#   totalTaxAmount - (any)
#   xmlattr_id - SOAP::SOAPInteger
class TaxReplyItem
  AttrId = XSD::QName.new(nil, "id")

  attr_accessor :cityTaxAmount
  attr_accessor :countyTaxAmount
  attr_accessor :districtTaxAmount
  attr_accessor :stateTaxAmount
  attr_accessor :totalTaxAmount

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_id
    __xmlattr[AttrId]
  end

  def xmlattr_id=(value)
    __xmlattr[AttrId] = value
  end

  def initialize(cityTaxAmount = nil, countyTaxAmount = nil, districtTaxAmount = nil, stateTaxAmount = nil, totalTaxAmount = nil)
    @cityTaxAmount = cityTaxAmount
    @countyTaxAmount = countyTaxAmount
    @districtTaxAmount = districtTaxAmount
    @stateTaxAmount = stateTaxAmount
    @totalTaxAmount = totalTaxAmount
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}TaxReply
#   reasonCode - SOAP::SOAPInteger
#   currency - SOAP::SOAPString
#   grandTotalAmount - (any)
#   totalCityTaxAmount - (any)
#   city - SOAP::SOAPString
#   totalCountyTaxAmount - (any)
#   county - SOAP::SOAPString
#   totalDistrictTaxAmount - (any)
#   totalStateTaxAmount - (any)
#   state - SOAP::SOAPString
#   totalTaxAmount - (any)
#   postalCode - SOAP::SOAPString
#   geocode - SOAP::SOAPString
#   item - CyberSource::Soap::TaxReplyItem
class TaxReply
  attr_accessor :reasonCode
  attr_accessor :currency
  attr_accessor :grandTotalAmount
  attr_accessor :totalCityTaxAmount
  attr_accessor :city
  attr_accessor :totalCountyTaxAmount
  attr_accessor :county
  attr_accessor :totalDistrictTaxAmount
  attr_accessor :totalStateTaxAmount
  attr_accessor :state
  attr_accessor :totalTaxAmount
  attr_accessor :postalCode
  attr_accessor :geocode
  attr_accessor :item

  def initialize(reasonCode = nil, currency = nil, grandTotalAmount = nil, totalCityTaxAmount = nil, city = nil, totalCountyTaxAmount = nil, county = nil, totalDistrictTaxAmount = nil, totalStateTaxAmount = nil, state = nil, totalTaxAmount = nil, postalCode = nil, geocode = nil, item = [])
    @reasonCode = reasonCode
    @currency = currency
    @grandTotalAmount = grandTotalAmount
    @totalCityTaxAmount = totalCityTaxAmount
    @city = city
    @totalCountyTaxAmount = totalCountyTaxAmount
    @county = county
    @totalDistrictTaxAmount = totalDistrictTaxAmount
    @totalStateTaxAmount = totalStateTaxAmount
    @state = state
    @totalTaxAmount = totalTaxAmount
    @postalCode = postalCode
    @geocode = geocode
    @item = item
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DeviceFingerprint
#   cookiesEnabled - (any)
#   flashEnabled - (any)
#   hash - SOAP::SOAPString
#   imagesEnabled - (any)
#   javascriptEnabled - (any)
#   proxyIPAddress - SOAP::SOAPString
#   proxyIPAddressActivities - SOAP::SOAPString
#   proxyIPAddressAttributes - SOAP::SOAPString
#   proxyServerType - SOAP::SOAPString
#   trueIPAddress - SOAP::SOAPString
#   trueIPAddressActivities - SOAP::SOAPString
#   trueIPAddressAttributes - SOAP::SOAPString
#   trueIPAddressCity - SOAP::SOAPString
#   trueIPAddressCountry - SOAP::SOAPString
#   smartID - SOAP::SOAPString
#   smartIDConfidenceLevel - SOAP::SOAPString
#   screenResolution - SOAP::SOAPString
#   browserLanguage - SOAP::SOAPString
class DeviceFingerprint
  attr_accessor :cookiesEnabled
  attr_accessor :flashEnabled
  attr_accessor :hash
  attr_accessor :imagesEnabled
  attr_accessor :javascriptEnabled
  attr_accessor :proxyIPAddress
  attr_accessor :proxyIPAddressActivities
  attr_accessor :proxyIPAddressAttributes
  attr_accessor :proxyServerType
  attr_accessor :trueIPAddress
  attr_accessor :trueIPAddressActivities
  attr_accessor :trueIPAddressAttributes
  attr_accessor :trueIPAddressCity
  attr_accessor :trueIPAddressCountry
  attr_accessor :smartID
  attr_accessor :smartIDConfidenceLevel
  attr_accessor :screenResolution
  attr_accessor :browserLanguage

  def initialize(cookiesEnabled = nil, flashEnabled = nil, hash = nil, imagesEnabled = nil, javascriptEnabled = nil, proxyIPAddress = nil, proxyIPAddressActivities = nil, proxyIPAddressAttributes = nil, proxyServerType = nil, trueIPAddress = nil, trueIPAddressActivities = nil, trueIPAddressAttributes = nil, trueIPAddressCity = nil, trueIPAddressCountry = nil, smartID = nil, smartIDConfidenceLevel = nil, screenResolution = nil, browserLanguage = nil)
    @cookiesEnabled = cookiesEnabled
    @flashEnabled = flashEnabled
    @hash = hash
    @imagesEnabled = imagesEnabled
    @javascriptEnabled = javascriptEnabled
    @proxyIPAddress = proxyIPAddress
    @proxyIPAddressActivities = proxyIPAddressActivities
    @proxyIPAddressAttributes = proxyIPAddressAttributes
    @proxyServerType = proxyServerType
    @trueIPAddress = trueIPAddress
    @trueIPAddressActivities = trueIPAddressActivities
    @trueIPAddressAttributes = trueIPAddressAttributes
    @trueIPAddressCity = trueIPAddressCity
    @trueIPAddressCountry = trueIPAddressCountry
    @smartID = smartID
    @smartIDConfidenceLevel = smartIDConfidenceLevel
    @screenResolution = screenResolution
    @browserLanguage = browserLanguage
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}AFSReply
#   reasonCode - SOAP::SOAPInteger
#   afsResult - SOAP::SOAPInteger
#   hostSeverity - SOAP::SOAPInteger
#   consumerLocalTime - SOAP::SOAPString
#   afsFactorCode - SOAP::SOAPString
#   addressInfoCode - SOAP::SOAPString
#   hotlistInfoCode - SOAP::SOAPString
#   internetInfoCode - SOAP::SOAPString
#   phoneInfoCode - SOAP::SOAPString
#   suspiciousInfoCode - SOAP::SOAPString
#   velocityInfoCode - SOAP::SOAPString
#   identityInfoCode - SOAP::SOAPString
#   ipCountry - SOAP::SOAPString
#   ipState - SOAP::SOAPString
#   ipCity - SOAP::SOAPString
#   ipRoutingMethod - SOAP::SOAPString
#   scoreModelUsed - SOAP::SOAPString
#   binCountry - SOAP::SOAPString
#   cardAccountType - SOAP::SOAPString
#   cardScheme - SOAP::SOAPString
#   cardIssuer - SOAP::SOAPString
#   deviceFingerprint - CyberSource::Soap::DeviceFingerprint
class AFSReply
  attr_accessor :reasonCode
  attr_accessor :afsResult
  attr_accessor :hostSeverity
  attr_accessor :consumerLocalTime
  attr_accessor :afsFactorCode
  attr_accessor :addressInfoCode
  attr_accessor :hotlistInfoCode
  attr_accessor :internetInfoCode
  attr_accessor :phoneInfoCode
  attr_accessor :suspiciousInfoCode
  attr_accessor :velocityInfoCode
  attr_accessor :identityInfoCode
  attr_accessor :ipCountry
  attr_accessor :ipState
  attr_accessor :ipCity
  attr_accessor :ipRoutingMethod
  attr_accessor :scoreModelUsed
  attr_accessor :binCountry
  attr_accessor :cardAccountType
  attr_accessor :cardScheme
  attr_accessor :cardIssuer
  attr_accessor :deviceFingerprint

  def initialize(reasonCode = nil, afsResult = nil, hostSeverity = nil, consumerLocalTime = nil, afsFactorCode = nil, addressInfoCode = nil, hotlistInfoCode = nil, internetInfoCode = nil, phoneInfoCode = nil, suspiciousInfoCode = nil, velocityInfoCode = nil, identityInfoCode = nil, ipCountry = nil, ipState = nil, ipCity = nil, ipRoutingMethod = nil, scoreModelUsed = nil, binCountry = nil, cardAccountType = nil, cardScheme = nil, cardIssuer = nil, deviceFingerprint = nil)
    @reasonCode = reasonCode
    @afsResult = afsResult
    @hostSeverity = hostSeverity
    @consumerLocalTime = consumerLocalTime
    @afsFactorCode = afsFactorCode
    @addressInfoCode = addressInfoCode
    @hotlistInfoCode = hotlistInfoCode
    @internetInfoCode = internetInfoCode
    @phoneInfoCode = phoneInfoCode
    @suspiciousInfoCode = suspiciousInfoCode
    @velocityInfoCode = velocityInfoCode
    @identityInfoCode = identityInfoCode
    @ipCountry = ipCountry
    @ipState = ipState
    @ipCity = ipCity
    @ipRoutingMethod = ipRoutingMethod
    @scoreModelUsed = scoreModelUsed
    @binCountry = binCountry
    @cardAccountType = cardAccountType
    @cardScheme = cardScheme
    @cardIssuer = cardIssuer
    @deviceFingerprint = deviceFingerprint
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DAVReply
#   reasonCode - SOAP::SOAPInteger
#   addressType - SOAP::SOAPString
#   apartmentInfo - SOAP::SOAPString
#   barCode - SOAP::SOAPString
#   barCodeCheckDigit - SOAP::SOAPString
#   careOf - SOAP::SOAPString
#   cityInfo - SOAP::SOAPString
#   countryInfo - SOAP::SOAPString
#   directionalInfo - SOAP::SOAPString
#   lvrInfo - SOAP::SOAPString
#   matchScore - SOAP::SOAPInteger
#   standardizedAddress1 - SOAP::SOAPString
#   standardizedAddress2 - SOAP::SOAPString
#   standardizedAddress3 - SOAP::SOAPString
#   standardizedAddress4 - SOAP::SOAPString
#   standardizedAddressNoApt - SOAP::SOAPString
#   standardizedCity - SOAP::SOAPString
#   standardizedCounty - SOAP::SOAPString
#   standardizedCSP - SOAP::SOAPString
#   standardizedState - SOAP::SOAPString
#   standardizedPostalCode - SOAP::SOAPString
#   standardizedCountry - SOAP::SOAPString
#   standardizedISOCountry - SOAP::SOAPString
#   stateInfo - SOAP::SOAPString
#   streetInfo - SOAP::SOAPString
#   suffixInfo - SOAP::SOAPString
#   postalCodeInfo - SOAP::SOAPString
#   overallInfo - SOAP::SOAPString
#   usInfo - SOAP::SOAPString
#   caInfo - SOAP::SOAPString
#   intlInfo - SOAP::SOAPString
#   usErrorInfo - SOAP::SOAPString
#   caErrorInfo - SOAP::SOAPString
#   intlErrorInfo - SOAP::SOAPString
class DAVReply
  attr_accessor :reasonCode
  attr_accessor :addressType
  attr_accessor :apartmentInfo
  attr_accessor :barCode
  attr_accessor :barCodeCheckDigit
  attr_accessor :careOf
  attr_accessor :cityInfo
  attr_accessor :countryInfo
  attr_accessor :directionalInfo
  attr_accessor :lvrInfo
  attr_accessor :matchScore
  attr_accessor :standardizedAddress1
  attr_accessor :standardizedAddress2
  attr_accessor :standardizedAddress3
  attr_accessor :standardizedAddress4
  attr_accessor :standardizedAddressNoApt
  attr_accessor :standardizedCity
  attr_accessor :standardizedCounty
  attr_accessor :standardizedCSP
  attr_accessor :standardizedState
  attr_accessor :standardizedPostalCode
  attr_accessor :standardizedCountry
  attr_accessor :standardizedISOCountry
  attr_accessor :stateInfo
  attr_accessor :streetInfo
  attr_accessor :suffixInfo
  attr_accessor :postalCodeInfo
  attr_accessor :overallInfo
  attr_accessor :usInfo
  attr_accessor :caInfo
  attr_accessor :intlInfo
  attr_accessor :usErrorInfo
  attr_accessor :caErrorInfo
  attr_accessor :intlErrorInfo

  def initialize(reasonCode = nil, addressType = nil, apartmentInfo = nil, barCode = nil, barCodeCheckDigit = nil, careOf = nil, cityInfo = nil, countryInfo = nil, directionalInfo = nil, lvrInfo = nil, matchScore = nil, standardizedAddress1 = nil, standardizedAddress2 = nil, standardizedAddress3 = nil, standardizedAddress4 = nil, standardizedAddressNoApt = nil, standardizedCity = nil, standardizedCounty = nil, standardizedCSP = nil, standardizedState = nil, standardizedPostalCode = nil, standardizedCountry = nil, standardizedISOCountry = nil, stateInfo = nil, streetInfo = nil, suffixInfo = nil, postalCodeInfo = nil, overallInfo = nil, usInfo = nil, caInfo = nil, intlInfo = nil, usErrorInfo = nil, caErrorInfo = nil, intlErrorInfo = nil)
    @reasonCode = reasonCode
    @addressType = addressType
    @apartmentInfo = apartmentInfo
    @barCode = barCode
    @barCodeCheckDigit = barCodeCheckDigit
    @careOf = careOf
    @cityInfo = cityInfo
    @countryInfo = countryInfo
    @directionalInfo = directionalInfo
    @lvrInfo = lvrInfo
    @matchScore = matchScore
    @standardizedAddress1 = standardizedAddress1
    @standardizedAddress2 = standardizedAddress2
    @standardizedAddress3 = standardizedAddress3
    @standardizedAddress4 = standardizedAddress4
    @standardizedAddressNoApt = standardizedAddressNoApt
    @standardizedCity = standardizedCity
    @standardizedCounty = standardizedCounty
    @standardizedCSP = standardizedCSP
    @standardizedState = standardizedState
    @standardizedPostalCode = standardizedPostalCode
    @standardizedCountry = standardizedCountry
    @standardizedISOCountry = standardizedISOCountry
    @stateInfo = stateInfo
    @streetInfo = streetInfo
    @suffixInfo = suffixInfo
    @postalCodeInfo = postalCodeInfo
    @overallInfo = overallInfo
    @usInfo = usInfo
    @caInfo = caInfo
    @intlInfo = intlInfo
    @usErrorInfo = usErrorInfo
    @caErrorInfo = caErrorInfo
    @intlErrorInfo = intlErrorInfo
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DeniedPartiesMatch
#   list - SOAP::SOAPString
#   name - SOAP::SOAPString
#   address - SOAP::SOAPString
#   program - SOAP::SOAPString
class DeniedPartiesMatch
  attr_accessor :list
  attr_accessor :name
  attr_accessor :address
  attr_accessor :program

  def initialize(list = nil, name = [], address = [], program = [])
    @list = list
    @name = name
    @address = address
    @program = program
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ExportReply
#   reasonCode - SOAP::SOAPInteger
#   ipCountryConfidence - SOAP::SOAPInteger
#   infoCode - SOAP::SOAPString
class ExportReply
  attr_accessor :reasonCode
  attr_accessor :ipCountryConfidence
  attr_accessor :infoCode

  def initialize(reasonCode = nil, ipCountryConfidence = nil, infoCode = nil)
    @reasonCode = reasonCode
    @ipCountryConfidence = ipCountryConfidence
    @infoCode = infoCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FXQuote
#   id - SOAP::SOAPString
#   rate - SOAP::SOAPString
#   type - SOAP::SOAPString
#   expirationDateTime - (any)
#   currency - SOAP::SOAPString
#   fundingCurrency - SOAP::SOAPString
#   receivedDateTime - (any)
class FXQuote
  attr_accessor :id
  attr_accessor :rate
  attr_accessor :type
  attr_accessor :expirationDateTime
  attr_accessor :currency
  attr_accessor :fundingCurrency
  attr_accessor :receivedDateTime

  def initialize(id = nil, rate = nil, type = nil, expirationDateTime = nil, currency = nil, fundingCurrency = nil, receivedDateTime = nil)
    @id = id
    @rate = rate
    @type = type
    @expirationDateTime = expirationDateTime
    @currency = currency
    @fundingCurrency = fundingCurrency
    @receivedDateTime = receivedDateTime
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FXRatesReply
#   reasonCode - SOAP::SOAPInteger
#   quote - CyberSource::Soap::FXQuote
class FXRatesReply
  attr_accessor :reasonCode
  attr_accessor :quote

  def initialize(reasonCode = nil, quote = [])
    @reasonCode = reasonCode
    @quote = quote
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankTransferReply
#   reasonCode - SOAP::SOAPInteger
#   accountHolder - SOAP::SOAPString
#   accountNumber - SOAP::SOAPString
#   amount - (any)
#   bankName - SOAP::SOAPString
#   bankCity - SOAP::SOAPString
#   bankCountry - SOAP::SOAPString
#   paymentReference - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
#   bankSwiftCode - SOAP::SOAPString
#   bankSpecialID - SOAP::SOAPString
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   iban - SOAP::SOAPString
#   bankCode - SOAP::SOAPString
#   branchCode - SOAP::SOAPString
class BankTransferReply
  attr_accessor :reasonCode
  attr_accessor :accountHolder
  attr_accessor :accountNumber
  attr_accessor :amount
  attr_accessor :bankName
  attr_accessor :bankCity
  attr_accessor :bankCountry
  attr_accessor :paymentReference
  attr_accessor :processorResponse
  attr_accessor :bankSwiftCode
  attr_accessor :bankSpecialID
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :iban
  attr_accessor :bankCode
  attr_accessor :branchCode

  def initialize(reasonCode = nil, accountHolder = nil, accountNumber = nil, amount = nil, bankName = nil, bankCity = nil, bankCountry = nil, paymentReference = nil, processorResponse = nil, bankSwiftCode = nil, bankSpecialID = nil, requestDateTime = nil, reconciliationID = nil, iban = nil, bankCode = nil, branchCode = nil)
    @reasonCode = reasonCode
    @accountHolder = accountHolder
    @accountNumber = accountNumber
    @amount = amount
    @bankName = bankName
    @bankCity = bankCity
    @bankCountry = bankCountry
    @paymentReference = paymentReference
    @processorResponse = processorResponse
    @bankSwiftCode = bankSwiftCode
    @bankSpecialID = bankSpecialID
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @iban = iban
    @bankCode = bankCode
    @branchCode = branchCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankTransferRealTimeReply
#   reasonCode - SOAP::SOAPInteger
#   formMethod - SOAP::SOAPString
#   formAction - SOAP::SOAPString
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   paymentReference - SOAP::SOAPString
#   amount - (any)
class BankTransferRealTimeReply
  attr_accessor :reasonCode
  attr_accessor :formMethod
  attr_accessor :formAction
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :paymentReference
  attr_accessor :amount

  def initialize(reasonCode = nil, formMethod = nil, formAction = nil, requestDateTime = nil, reconciliationID = nil, paymentReference = nil, amount = nil)
    @reasonCode = reasonCode
    @formMethod = formMethod
    @formAction = formAction
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @paymentReference = paymentReference
    @amount = amount
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitMandateReply
#   reasonCode - SOAP::SOAPInteger
#   mandateID - SOAP::SOAPString
#   mandateMaturationDate - SOAP::SOAPString
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
class DirectDebitMandateReply
  attr_accessor :reasonCode
  attr_accessor :mandateID
  attr_accessor :mandateMaturationDate
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :processorResponse

  def initialize(reasonCode = nil, mandateID = nil, mandateMaturationDate = nil, requestDateTime = nil, reconciliationID = nil, processorResponse = nil)
    @reasonCode = reasonCode
    @mandateID = mandateID
    @mandateMaturationDate = mandateMaturationDate
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BankTransferRefundReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
class BankTransferRefundReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :processorResponse

  def initialize(reasonCode = nil, amount = nil, requestDateTime = nil, reconciliationID = nil, processorResponse = nil)
    @reasonCode = reasonCode
    @amount = amount
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
class DirectDebitReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :processorResponse

  def initialize(reasonCode = nil, amount = nil, requestDateTime = nil, reconciliationID = nil, processorResponse = nil)
    @reasonCode = reasonCode
    @amount = amount
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitValidateReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
class DirectDebitValidateReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :processorResponse

  def initialize(reasonCode = nil, amount = nil, requestDateTime = nil, reconciliationID = nil, processorResponse = nil)
    @reasonCode = reasonCode
    @amount = amount
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DirectDebitRefundReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
class DirectDebitRefundReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :processorResponse

  def initialize(reasonCode = nil, amount = nil, requestDateTime = nil, reconciliationID = nil, processorResponse = nil)
    @reasonCode = reasonCode
    @amount = amount
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionCreateReply
#   reasonCode - SOAP::SOAPInteger
#   subscriptionID - SOAP::SOAPString
class PaySubscriptionCreateReply
  attr_accessor :reasonCode
  attr_accessor :subscriptionID

  def initialize(reasonCode = nil, subscriptionID = nil)
    @reasonCode = reasonCode
    @subscriptionID = subscriptionID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionUpdateReply
#   reasonCode - SOAP::SOAPInteger
#   subscriptionID - SOAP::SOAPString
#   subscriptionIDNew - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
class PaySubscriptionUpdateReply
  attr_accessor :reasonCode
  attr_accessor :subscriptionID
  attr_accessor :subscriptionIDNew
  attr_accessor :ownerMerchantID

  def initialize(reasonCode = nil, subscriptionID = nil, subscriptionIDNew = nil, ownerMerchantID = nil)
    @reasonCode = reasonCode
    @subscriptionID = subscriptionID
    @subscriptionIDNew = subscriptionIDNew
    @ownerMerchantID = ownerMerchantID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionEventUpdateReply
#   reasonCode - SOAP::SOAPInteger
#   ownerMerchantID - SOAP::SOAPString
class PaySubscriptionEventUpdateReply
  attr_accessor :reasonCode
  attr_accessor :ownerMerchantID

  def initialize(reasonCode = nil, ownerMerchantID = nil)
    @reasonCode = reasonCode
    @ownerMerchantID = ownerMerchantID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionRetrieveReply
#   reasonCode - SOAP::SOAPInteger
#   approvalRequired - SOAP::SOAPString
#   automaticRenew - SOAP::SOAPString
#   cardAccountNumber - SOAP::SOAPString
#   cardExpirationMonth - SOAP::SOAPString
#   cardExpirationYear - SOAP::SOAPString
#   cardIssueNumber - SOAP::SOAPString
#   cardStartMonth - SOAP::SOAPString
#   cardStartYear - SOAP::SOAPString
#   cardType - SOAP::SOAPString
#   checkAccountNumber - SOAP::SOAPString
#   checkAccountType - SOAP::SOAPString
#   checkBankTransitNumber - SOAP::SOAPString
#   checkSecCode - SOAP::SOAPString
#   checkAuthenticateID - SOAP::SOAPString
#   city - SOAP::SOAPString
#   comments - SOAP::SOAPString
#   companyName - SOAP::SOAPString
#   country - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   customerAccountID - SOAP::SOAPString
#   email - SOAP::SOAPString
#   endDate - SOAP::SOAPString
#   firstName - SOAP::SOAPString
#   frequency - SOAP::SOAPString
#   lastName - SOAP::SOAPString
#   merchantReferenceCode - SOAP::SOAPString
#   paymentMethod - SOAP::SOAPString
#   paymentsRemaining - SOAP::SOAPString
#   phoneNumber - SOAP::SOAPString
#   postalCode - SOAP::SOAPString
#   recurringAmount - SOAP::SOAPString
#   setupAmount - SOAP::SOAPString
#   startDate - SOAP::SOAPString
#   state - SOAP::SOAPString
#   status - SOAP::SOAPString
#   street1 - SOAP::SOAPString
#   street2 - SOAP::SOAPString
#   subscriptionID - SOAP::SOAPString
#   subscriptionIDNew - SOAP::SOAPString
#   title - SOAP::SOAPString
#   totalPayments - SOAP::SOAPString
#   shipToFirstName - SOAP::SOAPString
#   shipToLastName - SOAP::SOAPString
#   shipToStreet1 - SOAP::SOAPString
#   shipToStreet2 - SOAP::SOAPString
#   shipToCity - SOAP::SOAPString
#   shipToState - SOAP::SOAPString
#   shipToPostalCode - SOAP::SOAPString
#   shipToCompany - SOAP::SOAPString
#   shipToCountry - SOAP::SOAPString
#   billPayment - SOAP::SOAPString
#   merchantDefinedDataField1 - SOAP::SOAPString
#   merchantDefinedDataField2 - SOAP::SOAPString
#   merchantDefinedDataField3 - SOAP::SOAPString
#   merchantDefinedDataField4 - SOAP::SOAPString
#   merchantSecureDataField1 - SOAP::SOAPString
#   merchantSecureDataField2 - SOAP::SOAPString
#   merchantSecureDataField3 - SOAP::SOAPString
#   merchantSecureDataField4 - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
#   companyTaxID - SOAP::SOAPString
#   driversLicenseNumber - SOAP::SOAPString
#   driversLicenseState - SOAP::SOAPString
#   dateOfBirth - SOAP::SOAPString
class PaySubscriptionRetrieveReply
  attr_accessor :reasonCode
  attr_accessor :approvalRequired
  attr_accessor :automaticRenew
  attr_accessor :cardAccountNumber
  attr_accessor :cardExpirationMonth
  attr_accessor :cardExpirationYear
  attr_accessor :cardIssueNumber
  attr_accessor :cardStartMonth
  attr_accessor :cardStartYear
  attr_accessor :cardType
  attr_accessor :checkAccountNumber
  attr_accessor :checkAccountType
  attr_accessor :checkBankTransitNumber
  attr_accessor :checkSecCode
  attr_accessor :checkAuthenticateID
  attr_accessor :city
  attr_accessor :comments
  attr_accessor :companyName
  attr_accessor :country
  attr_accessor :currency
  attr_accessor :customerAccountID
  attr_accessor :email
  attr_accessor :endDate
  attr_accessor :firstName
  attr_accessor :frequency
  attr_accessor :lastName
  attr_accessor :merchantReferenceCode
  attr_accessor :paymentMethod
  attr_accessor :paymentsRemaining
  attr_accessor :phoneNumber
  attr_accessor :postalCode
  attr_accessor :recurringAmount
  attr_accessor :setupAmount
  attr_accessor :startDate
  attr_accessor :state
  attr_accessor :status
  attr_accessor :street1
  attr_accessor :street2
  attr_accessor :subscriptionID
  attr_accessor :subscriptionIDNew
  attr_accessor :title
  attr_accessor :totalPayments
  attr_accessor :shipToFirstName
  attr_accessor :shipToLastName
  attr_accessor :shipToStreet1
  attr_accessor :shipToStreet2
  attr_accessor :shipToCity
  attr_accessor :shipToState
  attr_accessor :shipToPostalCode
  attr_accessor :shipToCompany
  attr_accessor :shipToCountry
  attr_accessor :billPayment
  attr_accessor :merchantDefinedDataField1
  attr_accessor :merchantDefinedDataField2
  attr_accessor :merchantDefinedDataField3
  attr_accessor :merchantDefinedDataField4
  attr_accessor :merchantSecureDataField1
  attr_accessor :merchantSecureDataField2
  attr_accessor :merchantSecureDataField3
  attr_accessor :merchantSecureDataField4
  attr_accessor :ownerMerchantID
  attr_accessor :companyTaxID
  attr_accessor :driversLicenseNumber
  attr_accessor :driversLicenseState
  attr_accessor :dateOfBirth

  def initialize(reasonCode = nil, approvalRequired = nil, automaticRenew = nil, cardAccountNumber = nil, cardExpirationMonth = nil, cardExpirationYear = nil, cardIssueNumber = nil, cardStartMonth = nil, cardStartYear = nil, cardType = nil, checkAccountNumber = nil, checkAccountType = nil, checkBankTransitNumber = nil, checkSecCode = nil, checkAuthenticateID = nil, city = nil, comments = nil, companyName = nil, country = nil, currency = nil, customerAccountID = nil, email = nil, endDate = nil, firstName = nil, frequency = nil, lastName = nil, merchantReferenceCode = nil, paymentMethod = nil, paymentsRemaining = nil, phoneNumber = nil, postalCode = nil, recurringAmount = nil, setupAmount = nil, startDate = nil, state = nil, status = nil, street1 = nil, street2 = nil, subscriptionID = nil, subscriptionIDNew = nil, title = nil, totalPayments = nil, shipToFirstName = nil, shipToLastName = nil, shipToStreet1 = nil, shipToStreet2 = nil, shipToCity = nil, shipToState = nil, shipToPostalCode = nil, shipToCompany = nil, shipToCountry = nil, billPayment = nil, merchantDefinedDataField1 = nil, merchantDefinedDataField2 = nil, merchantDefinedDataField3 = nil, merchantDefinedDataField4 = nil, merchantSecureDataField1 = nil, merchantSecureDataField2 = nil, merchantSecureDataField3 = nil, merchantSecureDataField4 = nil, ownerMerchantID = nil, companyTaxID = nil, driversLicenseNumber = nil, driversLicenseState = nil, dateOfBirth = nil)
    @reasonCode = reasonCode
    @approvalRequired = approvalRequired
    @automaticRenew = automaticRenew
    @cardAccountNumber = cardAccountNumber
    @cardExpirationMonth = cardExpirationMonth
    @cardExpirationYear = cardExpirationYear
    @cardIssueNumber = cardIssueNumber
    @cardStartMonth = cardStartMonth
    @cardStartYear = cardStartYear
    @cardType = cardType
    @checkAccountNumber = checkAccountNumber
    @checkAccountType = checkAccountType
    @checkBankTransitNumber = checkBankTransitNumber
    @checkSecCode = checkSecCode
    @checkAuthenticateID = checkAuthenticateID
    @city = city
    @comments = comments
    @companyName = companyName
    @country = country
    @currency = currency
    @customerAccountID = customerAccountID
    @email = email
    @endDate = endDate
    @firstName = firstName
    @frequency = frequency
    @lastName = lastName
    @merchantReferenceCode = merchantReferenceCode
    @paymentMethod = paymentMethod
    @paymentsRemaining = paymentsRemaining
    @phoneNumber = phoneNumber
    @postalCode = postalCode
    @recurringAmount = recurringAmount
    @setupAmount = setupAmount
    @startDate = startDate
    @state = state
    @status = status
    @street1 = street1
    @street2 = street2
    @subscriptionID = subscriptionID
    @subscriptionIDNew = subscriptionIDNew
    @title = title
    @totalPayments = totalPayments
    @shipToFirstName = shipToFirstName
    @shipToLastName = shipToLastName
    @shipToStreet1 = shipToStreet1
    @shipToStreet2 = shipToStreet2
    @shipToCity = shipToCity
    @shipToState = shipToState
    @shipToPostalCode = shipToPostalCode
    @shipToCompany = shipToCompany
    @shipToCountry = shipToCountry
    @billPayment = billPayment
    @merchantDefinedDataField1 = merchantDefinedDataField1
    @merchantDefinedDataField2 = merchantDefinedDataField2
    @merchantDefinedDataField3 = merchantDefinedDataField3
    @merchantDefinedDataField4 = merchantDefinedDataField4
    @merchantSecureDataField1 = merchantSecureDataField1
    @merchantSecureDataField2 = merchantSecureDataField2
    @merchantSecureDataField3 = merchantSecureDataField3
    @merchantSecureDataField4 = merchantSecureDataField4
    @ownerMerchantID = ownerMerchantID
    @companyTaxID = companyTaxID
    @driversLicenseNumber = driversLicenseNumber
    @driversLicenseState = driversLicenseState
    @dateOfBirth = dateOfBirth
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PaySubscriptionDeleteReply
#   reasonCode - SOAP::SOAPInteger
#   subscriptionID - SOAP::SOAPString
class PaySubscriptionDeleteReply
  attr_accessor :reasonCode
  attr_accessor :subscriptionID

  def initialize(reasonCode = nil, subscriptionID = nil)
    @reasonCode = reasonCode
    @subscriptionID = subscriptionID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalPaymentReply
#   reasonCode - SOAP::SOAPInteger
#   secureData - SOAP::SOAPString
#   amount - (any)
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
class PayPalPaymentReply
  attr_accessor :reasonCode
  attr_accessor :secureData
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID

  def initialize(reasonCode = nil, secureData = nil, amount = nil, requestDateTime = nil, reconciliationID = nil)
    @reasonCode = reasonCode
    @secureData = secureData
    @amount = amount
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalCreditReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   processorResponse - SOAP::SOAPString
class PayPalCreditReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :processorResponse

  def initialize(reasonCode = nil, amount = nil, requestDateTime = nil, reconciliationID = nil, processorResponse = nil)
    @reasonCode = reasonCode
    @amount = amount
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @processorResponse = processorResponse
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}VoidReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   amount - (any)
#   currency - SOAP::SOAPString
class VoidReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :currency

  def initialize(reasonCode = nil, requestDateTime = nil, amount = nil, currency = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @amount = amount
    @currency = currency
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PinlessDebitReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   authorizationCode - SOAP::SOAPString
#   requestDateTime - (any)
#   processorResponse - SOAP::SOAPString
#   receiptNumber - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   ownerMerchantID - SOAP::SOAPString
class PinlessDebitReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :authorizationCode
  attr_accessor :requestDateTime
  attr_accessor :processorResponse
  attr_accessor :receiptNumber
  attr_accessor :reconciliationID
  attr_accessor :ownerMerchantID

  def initialize(reasonCode = nil, amount = nil, authorizationCode = nil, requestDateTime = nil, processorResponse = nil, receiptNumber = nil, reconciliationID = nil, ownerMerchantID = nil)
    @reasonCode = reasonCode
    @amount = amount
    @authorizationCode = authorizationCode
    @requestDateTime = requestDateTime
    @processorResponse = processorResponse
    @receiptNumber = receiptNumber
    @reconciliationID = reconciliationID
    @ownerMerchantID = ownerMerchantID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PinlessDebitValidateReply
#   reasonCode - SOAP::SOAPInteger
#   status - SOAP::SOAPString
#   requestDateTime - (any)
class PinlessDebitValidateReply
  attr_accessor :reasonCode
  attr_accessor :status
  attr_accessor :requestDateTime

  def initialize(reasonCode = nil, status = nil, requestDateTime = nil)
    @reasonCode = reasonCode
    @status = status
    @requestDateTime = requestDateTime
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PinlessDebitReversalReply
#   reasonCode - SOAP::SOAPInteger
#   amount - (any)
#   requestDateTime - (any)
#   processorResponse - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
class PinlessDebitReversalReply
  attr_accessor :reasonCode
  attr_accessor :amount
  attr_accessor :requestDateTime
  attr_accessor :processorResponse
  attr_accessor :reconciliationID

  def initialize(reasonCode = nil, amount = nil, requestDateTime = nil, processorResponse = nil, reconciliationID = nil)
    @reasonCode = reasonCode
    @amount = amount
    @requestDateTime = requestDateTime
    @processorResponse = processorResponse
    @reconciliationID = reconciliationID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalButtonCreateReply
#   reasonCode - SOAP::SOAPInteger
#   encryptedFormData - SOAP::SOAPString
#   unencryptedFormData - SOAP::SOAPString
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   buttonType - SOAP::SOAPString
class PayPalButtonCreateReply
  attr_accessor :reasonCode
  attr_accessor :encryptedFormData
  attr_accessor :unencryptedFormData
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :buttonType

  def initialize(reasonCode = nil, encryptedFormData = nil, unencryptedFormData = nil, requestDateTime = nil, reconciliationID = nil, buttonType = nil)
    @reasonCode = reasonCode
    @encryptedFormData = encryptedFormData
    @unencryptedFormData = unencryptedFormData
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @buttonType = buttonType
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalPreapprovedPaymentReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   payerStatus - SOAP::SOAPString
#   payerName - SOAP::SOAPString
#   transactionType - SOAP::SOAPString
#   feeAmount - SOAP::SOAPString
#   payerCountry - SOAP::SOAPString
#   pendingReason - SOAP::SOAPString
#   paymentStatus - SOAP::SOAPString
#   mpStatus - SOAP::SOAPString
#   payer - SOAP::SOAPString
#   payerID - SOAP::SOAPString
#   payerBusiness - SOAP::SOAPString
#   transactionID - SOAP::SOAPString
#   desc - SOAP::SOAPString
#   mpMax - SOAP::SOAPString
#   paymentType - SOAP::SOAPString
#   paymentDate - SOAP::SOAPString
#   paymentGrossAmount - SOAP::SOAPString
#   settleAmount - SOAP::SOAPString
#   taxAmount - SOAP::SOAPString
#   exchangeRate - SOAP::SOAPString
#   paymentSourceID - SOAP::SOAPString
class PayPalPreapprovedPaymentReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :payerStatus
  attr_accessor :payerName
  attr_accessor :transactionType
  attr_accessor :feeAmount
  attr_accessor :payerCountry
  attr_accessor :pendingReason
  attr_accessor :paymentStatus
  attr_accessor :mpStatus
  attr_accessor :payer
  attr_accessor :payerID
  attr_accessor :payerBusiness
  attr_accessor :transactionID
  attr_accessor :desc
  attr_accessor :mpMax
  attr_accessor :paymentType
  attr_accessor :paymentDate
  attr_accessor :paymentGrossAmount
  attr_accessor :settleAmount
  attr_accessor :taxAmount
  attr_accessor :exchangeRate
  attr_accessor :paymentSourceID

  def initialize(reasonCode = nil, requestDateTime = nil, reconciliationID = nil, payerStatus = nil, payerName = nil, transactionType = nil, feeAmount = nil, payerCountry = nil, pendingReason = nil, paymentStatus = nil, mpStatus = nil, payer = nil, payerID = nil, payerBusiness = nil, transactionID = nil, desc = nil, mpMax = nil, paymentType = nil, paymentDate = nil, paymentGrossAmount = nil, settleAmount = nil, taxAmount = nil, exchangeRate = nil, paymentSourceID = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @payerStatus = payerStatus
    @payerName = payerName
    @transactionType = transactionType
    @feeAmount = feeAmount
    @payerCountry = payerCountry
    @pendingReason = pendingReason
    @paymentStatus = paymentStatus
    @mpStatus = mpStatus
    @payer = payer
    @payerID = payerID
    @payerBusiness = payerBusiness
    @transactionID = transactionID
    @desc = desc
    @mpMax = mpMax
    @paymentType = paymentType
    @paymentDate = paymentDate
    @paymentGrossAmount = paymentGrossAmount
    @settleAmount = settleAmount
    @taxAmount = taxAmount
    @exchangeRate = exchangeRate
    @paymentSourceID = paymentSourceID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalPreapprovedUpdateReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   reconciliationID - SOAP::SOAPString
#   payerStatus - SOAP::SOAPString
#   payerName - SOAP::SOAPString
#   payerCountry - SOAP::SOAPString
#   mpStatus - SOAP::SOAPString
#   payer - SOAP::SOAPString
#   payerID - SOAP::SOAPString
#   payerBusiness - SOAP::SOAPString
#   desc - SOAP::SOAPString
#   mpMax - SOAP::SOAPString
#   paymentSourceID - SOAP::SOAPString
class PayPalPreapprovedUpdateReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :reconciliationID
  attr_accessor :payerStatus
  attr_accessor :payerName
  attr_accessor :payerCountry
  attr_accessor :mpStatus
  attr_accessor :payer
  attr_accessor :payerID
  attr_accessor :payerBusiness
  attr_accessor :desc
  attr_accessor :mpMax
  attr_accessor :paymentSourceID

  def initialize(reasonCode = nil, requestDateTime = nil, reconciliationID = nil, payerStatus = nil, payerName = nil, payerCountry = nil, mpStatus = nil, payer = nil, payerID = nil, payerBusiness = nil, desc = nil, mpMax = nil, paymentSourceID = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @reconciliationID = reconciliationID
    @payerStatus = payerStatus
    @payerName = payerName
    @payerCountry = payerCountry
    @mpStatus = mpStatus
    @payer = payer
    @payerID = payerID
    @payerBusiness = payerBusiness
    @desc = desc
    @mpMax = mpMax
    @paymentSourceID = paymentSourceID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcSetReply
#   reasonCode - SOAP::SOAPInteger
#   paypalToken - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
class PayPalEcSetReply
  attr_accessor :reasonCode
  attr_accessor :paypalToken
  attr_accessor :amount
  attr_accessor :currency
  attr_accessor :correlationID
  attr_accessor :errorCode

  def initialize(reasonCode = nil, paypalToken = nil, amount = nil, currency = nil, correlationID = nil, errorCode = nil)
    @reasonCode = reasonCode
    @paypalToken = paypalToken
    @amount = amount
    @currency = currency
    @correlationID = correlationID
    @errorCode = errorCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcGetDetailsReply
#   reasonCode - SOAP::SOAPInteger
#   paypalToken - SOAP::SOAPString
#   payer - SOAP::SOAPString
#   payerId - SOAP::SOAPString
#   payerStatus - SOAP::SOAPString
#   payerSalutation - SOAP::SOAPString
#   payerFirstname - SOAP::SOAPString
#   payerMiddlename - SOAP::SOAPString
#   payerLastname - SOAP::SOAPString
#   payerSuffix - SOAP::SOAPString
#   payerCountry - SOAP::SOAPString
#   payerBusiness - SOAP::SOAPString
#   shipToName - SOAP::SOAPString
#   shipToAddress1 - SOAP::SOAPString
#   shipToAddress2 - SOAP::SOAPString
#   shipToCity - SOAP::SOAPString
#   shipToState - SOAP::SOAPString
#   shipToCountry - SOAP::SOAPString
#   shipToZip - SOAP::SOAPString
#   addressStatus - SOAP::SOAPString
#   payerPhone - SOAP::SOAPString
#   avsCode - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
#   street1 - SOAP::SOAPString
#   street2 - SOAP::SOAPString
#   city - SOAP::SOAPString
#   state - SOAP::SOAPString
#   postalCode - SOAP::SOAPString
#   countryCode - SOAP::SOAPString
#   countryName - SOAP::SOAPString
#   addressID - SOAP::SOAPString
#   paypalBillingAgreementAcceptedStatus - SOAP::SOAPString
class PayPalEcGetDetailsReply
  attr_accessor :reasonCode
  attr_accessor :paypalToken
  attr_accessor :payer
  attr_accessor :payerId
  attr_accessor :payerStatus
  attr_accessor :payerSalutation
  attr_accessor :payerFirstname
  attr_accessor :payerMiddlename
  attr_accessor :payerLastname
  attr_accessor :payerSuffix
  attr_accessor :payerCountry
  attr_accessor :payerBusiness
  attr_accessor :shipToName
  attr_accessor :shipToAddress1
  attr_accessor :shipToAddress2
  attr_accessor :shipToCity
  attr_accessor :shipToState
  attr_accessor :shipToCountry
  attr_accessor :shipToZip
  attr_accessor :addressStatus
  attr_accessor :payerPhone
  attr_accessor :avsCode
  attr_accessor :correlationID
  attr_accessor :errorCode
  attr_accessor :street1
  attr_accessor :street2
  attr_accessor :city
  attr_accessor :state
  attr_accessor :postalCode
  attr_accessor :countryCode
  attr_accessor :countryName
  attr_accessor :addressID
  attr_accessor :paypalBillingAgreementAcceptedStatus

  def initialize(reasonCode = nil, paypalToken = nil, payer = nil, payerId = nil, payerStatus = nil, payerSalutation = nil, payerFirstname = nil, payerMiddlename = nil, payerLastname = nil, payerSuffix = nil, payerCountry = nil, payerBusiness = nil, shipToName = nil, shipToAddress1 = nil, shipToAddress2 = nil, shipToCity = nil, shipToState = nil, shipToCountry = nil, shipToZip = nil, addressStatus = nil, payerPhone = nil, avsCode = nil, correlationID = nil, errorCode = nil, street1 = nil, street2 = nil, city = nil, state = nil, postalCode = nil, countryCode = nil, countryName = nil, addressID = nil, paypalBillingAgreementAcceptedStatus = nil)
    @reasonCode = reasonCode
    @paypalToken = paypalToken
    @payer = payer
    @payerId = payerId
    @payerStatus = payerStatus
    @payerSalutation = payerSalutation
    @payerFirstname = payerFirstname
    @payerMiddlename = payerMiddlename
    @payerLastname = payerLastname
    @payerSuffix = payerSuffix
    @payerCountry = payerCountry
    @payerBusiness = payerBusiness
    @shipToName = shipToName
    @shipToAddress1 = shipToAddress1
    @shipToAddress2 = shipToAddress2
    @shipToCity = shipToCity
    @shipToState = shipToState
    @shipToCountry = shipToCountry
    @shipToZip = shipToZip
    @addressStatus = addressStatus
    @payerPhone = payerPhone
    @avsCode = avsCode
    @correlationID = correlationID
    @errorCode = errorCode
    @street1 = street1
    @street2 = street2
    @city = city
    @state = state
    @postalCode = postalCode
    @countryCode = countryCode
    @countryName = countryName
    @addressID = addressID
    @paypalBillingAgreementAcceptedStatus = paypalBillingAgreementAcceptedStatus
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcDoPaymentReply
#   reasonCode - SOAP::SOAPInteger
#   paypalToken - SOAP::SOAPString
#   transactionId - SOAP::SOAPString
#   paypalTransactiontype - SOAP::SOAPString
#   paymentType - SOAP::SOAPString
#   paypalOrderTime - SOAP::SOAPString
#   paypalAmount - SOAP::SOAPString
#   paypalFeeAmount - SOAP::SOAPString
#   paypalTaxAmount - SOAP::SOAPString
#   paypalExchangeRate - SOAP::SOAPString
#   paypalPaymentStatus - SOAP::SOAPString
#   paypalPendingReason - SOAP::SOAPString
#   orderId - SOAP::SOAPString
#   paypalReasonCode - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
#   paypalBillingAgreementId - SOAP::SOAPString
class PayPalEcDoPaymentReply
  attr_accessor :reasonCode
  attr_accessor :paypalToken
  attr_accessor :transactionId
  attr_accessor :paypalTransactiontype
  attr_accessor :paymentType
  attr_accessor :paypalOrderTime
  attr_accessor :paypalAmount
  attr_accessor :paypalFeeAmount
  attr_accessor :paypalTaxAmount
  attr_accessor :paypalExchangeRate
  attr_accessor :paypalPaymentStatus
  attr_accessor :paypalPendingReason
  attr_accessor :orderId
  attr_accessor :paypalReasonCode
  attr_accessor :amount
  attr_accessor :currency
  attr_accessor :correlationID
  attr_accessor :errorCode
  attr_accessor :paypalBillingAgreementId

  def initialize(reasonCode = nil, paypalToken = nil, transactionId = nil, paypalTransactiontype = nil, paymentType = nil, paypalOrderTime = nil, paypalAmount = nil, paypalFeeAmount = nil, paypalTaxAmount = nil, paypalExchangeRate = nil, paypalPaymentStatus = nil, paypalPendingReason = nil, orderId = nil, paypalReasonCode = nil, amount = nil, currency = nil, correlationID = nil, errorCode = nil, paypalBillingAgreementId = nil)
    @reasonCode = reasonCode
    @paypalToken = paypalToken
    @transactionId = transactionId
    @paypalTransactiontype = paypalTransactiontype
    @paymentType = paymentType
    @paypalOrderTime = paypalOrderTime
    @paypalAmount = paypalAmount
    @paypalFeeAmount = paypalFeeAmount
    @paypalTaxAmount = paypalTaxAmount
    @paypalExchangeRate = paypalExchangeRate
    @paypalPaymentStatus = paypalPaymentStatus
    @paypalPendingReason = paypalPendingReason
    @orderId = orderId
    @paypalReasonCode = paypalReasonCode
    @amount = amount
    @currency = currency
    @correlationID = correlationID
    @errorCode = errorCode
    @paypalBillingAgreementId = paypalBillingAgreementId
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalDoCaptureReply
#   reasonCode - SOAP::SOAPInteger
#   authorizationId - SOAP::SOAPString
#   transactionId - SOAP::SOAPString
#   parentTransactionId - SOAP::SOAPString
#   paypalReceiptId - SOAP::SOAPString
#   paypalTransactiontype - SOAP::SOAPString
#   paypalPaymentType - SOAP::SOAPString
#   paypalOrderTime - SOAP::SOAPString
#   paypalPaymentGrossAmount - SOAP::SOAPString
#   paypalFeeAmount - SOAP::SOAPString
#   paypalTaxAmount - SOAP::SOAPString
#   paypalExchangeRate - SOAP::SOAPString
#   paypalPaymentStatus - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
class PayPalDoCaptureReply
  attr_accessor :reasonCode
  attr_accessor :authorizationId
  attr_accessor :transactionId
  attr_accessor :parentTransactionId
  attr_accessor :paypalReceiptId
  attr_accessor :paypalTransactiontype
  attr_accessor :paypalPaymentType
  attr_accessor :paypalOrderTime
  attr_accessor :paypalPaymentGrossAmount
  attr_accessor :paypalFeeAmount
  attr_accessor :paypalTaxAmount
  attr_accessor :paypalExchangeRate
  attr_accessor :paypalPaymentStatus
  attr_accessor :amount
  attr_accessor :currency
  attr_accessor :correlationID
  attr_accessor :errorCode

  def initialize(reasonCode = nil, authorizationId = nil, transactionId = nil, parentTransactionId = nil, paypalReceiptId = nil, paypalTransactiontype = nil, paypalPaymentType = nil, paypalOrderTime = nil, paypalPaymentGrossAmount = nil, paypalFeeAmount = nil, paypalTaxAmount = nil, paypalExchangeRate = nil, paypalPaymentStatus = nil, amount = nil, currency = nil, correlationID = nil, errorCode = nil)
    @reasonCode = reasonCode
    @authorizationId = authorizationId
    @transactionId = transactionId
    @parentTransactionId = parentTransactionId
    @paypalReceiptId = paypalReceiptId
    @paypalTransactiontype = paypalTransactiontype
    @paypalPaymentType = paypalPaymentType
    @paypalOrderTime = paypalOrderTime
    @paypalPaymentGrossAmount = paypalPaymentGrossAmount
    @paypalFeeAmount = paypalFeeAmount
    @paypalTaxAmount = paypalTaxAmount
    @paypalExchangeRate = paypalExchangeRate
    @paypalPaymentStatus = paypalPaymentStatus
    @amount = amount
    @currency = currency
    @correlationID = correlationID
    @errorCode = errorCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalAuthReversalReply
#   reasonCode - SOAP::SOAPInteger
#   authorizationId - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
class PayPalAuthReversalReply
  attr_accessor :reasonCode
  attr_accessor :authorizationId
  attr_accessor :correlationID
  attr_accessor :errorCode

  def initialize(reasonCode = nil, authorizationId = nil, correlationID = nil, errorCode = nil)
    @reasonCode = reasonCode
    @authorizationId = authorizationId
    @correlationID = correlationID
    @errorCode = errorCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalRefundReply
#   reasonCode - SOAP::SOAPInteger
#   transactionId - SOAP::SOAPString
#   paypalNetRefundAmount - SOAP::SOAPString
#   paypalFeeRefundAmount - SOAP::SOAPString
#   paypalGrossRefundAmount - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
class PayPalRefundReply
  attr_accessor :reasonCode
  attr_accessor :transactionId
  attr_accessor :paypalNetRefundAmount
  attr_accessor :paypalFeeRefundAmount
  attr_accessor :paypalGrossRefundAmount
  attr_accessor :correlationID
  attr_accessor :errorCode

  def initialize(reasonCode = nil, transactionId = nil, paypalNetRefundAmount = nil, paypalFeeRefundAmount = nil, paypalGrossRefundAmount = nil, correlationID = nil, errorCode = nil)
    @reasonCode = reasonCode
    @transactionId = transactionId
    @paypalNetRefundAmount = paypalNetRefundAmount
    @paypalFeeRefundAmount = paypalFeeRefundAmount
    @paypalGrossRefundAmount = paypalGrossRefundAmount
    @correlationID = correlationID
    @errorCode = errorCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalEcOrderSetupReply
#   reasonCode - SOAP::SOAPInteger
#   paypalToken - SOAP::SOAPString
#   transactionId - SOAP::SOAPString
#   paypalTransactiontype - SOAP::SOAPString
#   paymentType - SOAP::SOAPString
#   paypalOrderTime - SOAP::SOAPString
#   paypalAmount - SOAP::SOAPString
#   paypalFeeAmount - SOAP::SOAPString
#   paypalTaxAmount - SOAP::SOAPString
#   paypalExchangeRate - SOAP::SOAPString
#   paypalPaymentStatus - SOAP::SOAPString
#   paypalPendingReason - SOAP::SOAPString
#   paypalReasonCode - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
class PayPalEcOrderSetupReply
  attr_accessor :reasonCode
  attr_accessor :paypalToken
  attr_accessor :transactionId
  attr_accessor :paypalTransactiontype
  attr_accessor :paymentType
  attr_accessor :paypalOrderTime
  attr_accessor :paypalAmount
  attr_accessor :paypalFeeAmount
  attr_accessor :paypalTaxAmount
  attr_accessor :paypalExchangeRate
  attr_accessor :paypalPaymentStatus
  attr_accessor :paypalPendingReason
  attr_accessor :paypalReasonCode
  attr_accessor :amount
  attr_accessor :currency
  attr_accessor :correlationID
  attr_accessor :errorCode

  def initialize(reasonCode = nil, paypalToken = nil, transactionId = nil, paypalTransactiontype = nil, paymentType = nil, paypalOrderTime = nil, paypalAmount = nil, paypalFeeAmount = nil, paypalTaxAmount = nil, paypalExchangeRate = nil, paypalPaymentStatus = nil, paypalPendingReason = nil, paypalReasonCode = nil, amount = nil, currency = nil, correlationID = nil, errorCode = nil)
    @reasonCode = reasonCode
    @paypalToken = paypalToken
    @transactionId = transactionId
    @paypalTransactiontype = paypalTransactiontype
    @paymentType = paymentType
    @paypalOrderTime = paypalOrderTime
    @paypalAmount = paypalAmount
    @paypalFeeAmount = paypalFeeAmount
    @paypalTaxAmount = paypalTaxAmount
    @paypalExchangeRate = paypalExchangeRate
    @paypalPaymentStatus = paypalPaymentStatus
    @paypalPendingReason = paypalPendingReason
    @paypalReasonCode = paypalReasonCode
    @amount = amount
    @currency = currency
    @correlationID = correlationID
    @errorCode = errorCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalAuthorizationReply
#   reasonCode - SOAP::SOAPInteger
#   transactionId - SOAP::SOAPString
#   paypalAmount - SOAP::SOAPString
#   amount - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
#   protectionEligibility - SOAP::SOAPString
class PayPalAuthorizationReply
  attr_accessor :reasonCode
  attr_accessor :transactionId
  attr_accessor :paypalAmount
  attr_accessor :amount
  attr_accessor :currency
  attr_accessor :correlationID
  attr_accessor :errorCode
  attr_accessor :protectionEligibility

  def initialize(reasonCode = nil, transactionId = nil, paypalAmount = nil, amount = nil, currency = nil, correlationID = nil, errorCode = nil, protectionEligibility = nil)
    @reasonCode = reasonCode
    @transactionId = transactionId
    @paypalAmount = paypalAmount
    @amount = amount
    @currency = currency
    @correlationID = correlationID
    @errorCode = errorCode
    @protectionEligibility = protectionEligibility
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalUpdateAgreementReply
#   reasonCode - SOAP::SOAPInteger
#   paypalBillingAgreementId - SOAP::SOAPString
#   paypalBillingAgreementDesc - SOAP::SOAPString
#   paypalBillingAgreementCustom - SOAP::SOAPString
#   paypalBillingAgreementStatus - SOAP::SOAPString
#   payer - SOAP::SOAPString
#   payerId - SOAP::SOAPString
#   payerStatus - SOAP::SOAPString
#   payerCountry - SOAP::SOAPString
#   payerBusiness - SOAP::SOAPString
#   payerSalutation - SOAP::SOAPString
#   payerFirstname - SOAP::SOAPString
#   payerMiddlename - SOAP::SOAPString
#   payerLastname - SOAP::SOAPString
#   payerSuffix - SOAP::SOAPString
#   addressStatus - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
class PayPalUpdateAgreementReply
  attr_accessor :reasonCode
  attr_accessor :paypalBillingAgreementId
  attr_accessor :paypalBillingAgreementDesc
  attr_accessor :paypalBillingAgreementCustom
  attr_accessor :paypalBillingAgreementStatus
  attr_accessor :payer
  attr_accessor :payerId
  attr_accessor :payerStatus
  attr_accessor :payerCountry
  attr_accessor :payerBusiness
  attr_accessor :payerSalutation
  attr_accessor :payerFirstname
  attr_accessor :payerMiddlename
  attr_accessor :payerLastname
  attr_accessor :payerSuffix
  attr_accessor :addressStatus
  attr_accessor :errorCode
  attr_accessor :correlationID

  def initialize(reasonCode = nil, paypalBillingAgreementId = nil, paypalBillingAgreementDesc = nil, paypalBillingAgreementCustom = nil, paypalBillingAgreementStatus = nil, payer = nil, payerId = nil, payerStatus = nil, payerCountry = nil, payerBusiness = nil, payerSalutation = nil, payerFirstname = nil, payerMiddlename = nil, payerLastname = nil, payerSuffix = nil, addressStatus = nil, errorCode = nil, correlationID = nil)
    @reasonCode = reasonCode
    @paypalBillingAgreementId = paypalBillingAgreementId
    @paypalBillingAgreementDesc = paypalBillingAgreementDesc
    @paypalBillingAgreementCustom = paypalBillingAgreementCustom
    @paypalBillingAgreementStatus = paypalBillingAgreementStatus
    @payer = payer
    @payerId = payerId
    @payerStatus = payerStatus
    @payerCountry = payerCountry
    @payerBusiness = payerBusiness
    @payerSalutation = payerSalutation
    @payerFirstname = payerFirstname
    @payerMiddlename = payerMiddlename
    @payerLastname = payerLastname
    @payerSuffix = payerSuffix
    @addressStatus = addressStatus
    @errorCode = errorCode
    @correlationID = correlationID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalCreateAgreementReply
#   reasonCode - SOAP::SOAPInteger
#   paypalBillingAgreementId - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
class PayPalCreateAgreementReply
  attr_accessor :reasonCode
  attr_accessor :paypalBillingAgreementId
  attr_accessor :errorCode
  attr_accessor :correlationID

  def initialize(reasonCode = nil, paypalBillingAgreementId = nil, errorCode = nil, correlationID = nil)
    @reasonCode = reasonCode
    @paypalBillingAgreementId = paypalBillingAgreementId
    @errorCode = errorCode
    @correlationID = correlationID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}PayPalDoRefTransactionReply
#   reasonCode - SOAP::SOAPInteger
#   paypalBillingAgreementId - SOAP::SOAPString
#   transactionId - SOAP::SOAPString
#   paypalTransactionType - SOAP::SOAPString
#   paypalPaymentType - SOAP::SOAPString
#   paypalOrderTime - SOAP::SOAPString
#   paypalAmount - SOAP::SOAPString
#   currency - SOAP::SOAPString
#   paypalTaxAmount - SOAP::SOAPString
#   paypalExchangeRate - SOAP::SOAPString
#   paypalPaymentStatus - SOAP::SOAPString
#   paypalPendingReason - SOAP::SOAPString
#   paypalReasonCode - SOAP::SOAPString
#   errorCode - SOAP::SOAPString
#   correlationID - SOAP::SOAPString
class PayPalDoRefTransactionReply
  attr_accessor :reasonCode
  attr_accessor :paypalBillingAgreementId
  attr_accessor :transactionId
  attr_accessor :paypalTransactionType
  attr_accessor :paypalPaymentType
  attr_accessor :paypalOrderTime
  attr_accessor :paypalAmount
  attr_accessor :currency
  attr_accessor :paypalTaxAmount
  attr_accessor :paypalExchangeRate
  attr_accessor :paypalPaymentStatus
  attr_accessor :paypalPendingReason
  attr_accessor :paypalReasonCode
  attr_accessor :errorCode
  attr_accessor :correlationID

  def initialize(reasonCode = nil, paypalBillingAgreementId = nil, transactionId = nil, paypalTransactionType = nil, paypalPaymentType = nil, paypalOrderTime = nil, paypalAmount = nil, currency = nil, paypalTaxAmount = nil, paypalExchangeRate = nil, paypalPaymentStatus = nil, paypalPendingReason = nil, paypalReasonCode = nil, errorCode = nil, correlationID = nil)
    @reasonCode = reasonCode
    @paypalBillingAgreementId = paypalBillingAgreementId
    @transactionId = transactionId
    @paypalTransactionType = paypalTransactionType
    @paypalPaymentType = paypalPaymentType
    @paypalOrderTime = paypalOrderTime
    @paypalAmount = paypalAmount
    @currency = currency
    @paypalTaxAmount = paypalTaxAmount
    @paypalExchangeRate = paypalExchangeRate
    @paypalPaymentStatus = paypalPaymentStatus
    @paypalPendingReason = paypalPendingReason
    @paypalReasonCode = paypalReasonCode
    @errorCode = errorCode
    @correlationID = correlationID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RiskUpdateReply
#   reasonCode - SOAP::SOAPInteger
class RiskUpdateReply
  attr_accessor :reasonCode

  def initialize(reasonCode = nil)
    @reasonCode = reasonCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FraudUpdateReply
#   reasonCode - SOAP::SOAPInteger
class FraudUpdateReply
  attr_accessor :reasonCode

  def initialize(reasonCode = nil)
    @reasonCode = reasonCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RuleResultItem
#   name - SOAP::SOAPString
#   decision - SOAP::SOAPString
#   evaluation - SOAP::SOAPString
#   ruleID - SOAP::SOAPInteger
class RuleResultItem
  attr_accessor :name
  attr_accessor :decision
  attr_accessor :evaluation
  attr_accessor :ruleID

  def initialize(name = nil, decision = nil, evaluation = nil, ruleID = nil)
    @name = name
    @decision = decision
    @evaluation = evaluation
    @ruleID = ruleID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RuleResultItems
class RuleResultItems < ::Array
end

# {urn:schemas-cybersource-com:transaction-data-1.67}DecisionReply
#   casePriority - SOAP::SOAPInteger
#   activeProfileReply - CyberSource::Soap::ProfileReply
#   velocityInfoCode - SOAP::SOAPString
class DecisionReply
  attr_accessor :casePriority
  attr_accessor :activeProfileReply
  attr_accessor :velocityInfoCode

  def initialize(casePriority = nil, activeProfileReply = nil, velocityInfoCode = nil)
    @casePriority = casePriority
    @activeProfileReply = activeProfileReply
    @velocityInfoCode = velocityInfoCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ProfileReply
#   selectedBy - SOAP::SOAPString
#   name - SOAP::SOAPString
#   destinationQueue - SOAP::SOAPString
#   rulesTriggered - CyberSource::Soap::RuleResultItems
class ProfileReply
  attr_accessor :selectedBy
  attr_accessor :name
  attr_accessor :destinationQueue
  attr_accessor :rulesTriggered

  def initialize(selectedBy = nil, name = nil, destinationQueue = nil, rulesTriggered = nil)
    @selectedBy = selectedBy
    @name = name
    @destinationQueue = destinationQueue
    @rulesTriggered = rulesTriggered
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}CCDCCReply
#   reasonCode - SOAP::SOAPInteger
#   dccSupported - (any)
#   validHours - SOAP::SOAPString
#   marginRatePercentage - SOAP::SOAPString
class CCDCCReply
  attr_accessor :reasonCode
  attr_accessor :dccSupported
  attr_accessor :validHours
  attr_accessor :marginRatePercentage

  def initialize(reasonCode = nil, dccSupported = nil, validHours = nil, marginRatePercentage = nil)
    @reasonCode = reasonCode
    @dccSupported = dccSupported
    @validHours = validHours
    @marginRatePercentage = marginRatePercentage
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ChinaPaymentReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   amount - (any)
#   currency - SOAP::SOAPString
#   reconciliationID - SOAP::SOAPString
#   formData - SOAP::SOAPString
#   verifyFailure - SOAP::SOAPString
#   verifyInProcess - SOAP::SOAPString
#   verifySuccess - SOAP::SOAPString
class ChinaPaymentReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :currency
  attr_accessor :reconciliationID
  attr_accessor :formData
  attr_accessor :verifyFailure
  attr_accessor :verifyInProcess
  attr_accessor :verifySuccess

  def initialize(reasonCode = nil, requestDateTime = nil, amount = nil, currency = nil, reconciliationID = nil, formData = nil, verifyFailure = nil, verifyInProcess = nil, verifySuccess = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @amount = amount
    @currency = currency
    @reconciliationID = reconciliationID
    @formData = formData
    @verifyFailure = verifyFailure
    @verifyInProcess = verifyInProcess
    @verifySuccess = verifySuccess
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ChinaRefundReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   amount - (any)
#   currency - SOAP::SOAPString
class ChinaRefundReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :currency

  def initialize(reasonCode = nil, requestDateTime = nil, amount = nil, currency = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @amount = amount
    @currency = currency
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}BoletoPaymentReply
#   reasonCode - SOAP::SOAPInteger
#   requestDateTime - (any)
#   amount - (any)
#   reconciliationID - SOAP::SOAPString
#   boletoNumber - SOAP::SOAPString
#   expirationDate - SOAP::SOAPString
#   url - SOAP::SOAPString
class BoletoPaymentReply
  attr_accessor :reasonCode
  attr_accessor :requestDateTime
  attr_accessor :amount
  attr_accessor :reconciliationID
  attr_accessor :boletoNumber
  attr_accessor :expirationDate
  attr_accessor :url

  def initialize(reasonCode = nil, requestDateTime = nil, amount = nil, reconciliationID = nil, boletoNumber = nil, expirationDate = nil, url = nil)
    @reasonCode = reasonCode
    @requestDateTime = requestDateTime
    @amount = amount
    @reconciliationID = reconciliationID
    @boletoNumber = boletoNumber
    @expirationDate = expirationDate
    @url = url
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ReplyMessage
#   merchantReferenceCode - SOAP::SOAPString
#   requestID - SOAP::SOAPString
#   decision - SOAP::SOAPString
#   reasonCode - SOAP::SOAPInteger
#   missingField - SOAP::SOAPString
#   invalidField - SOAP::SOAPString
#   requestToken - SOAP::SOAPString
#   purchaseTotals - CyberSource::Soap::PurchaseTotals
#   deniedPartiesMatch - CyberSource::Soap::DeniedPartiesMatch
#   ccAuthReply - CyberSource::Soap::CCAuthReply
#   ccCaptureReply - CyberSource::Soap::CCCaptureReply
#   ccCreditReply - CyberSource::Soap::CCCreditReply
#   ccAuthReversalReply - CyberSource::Soap::CCAuthReversalReply
#   ccAutoAuthReversalReply - CyberSource::Soap::CCAutoAuthReversalReply
#   ccDCCReply - CyberSource::Soap::CCDCCReply
#   ecDebitReply - CyberSource::Soap::ECDebitReply
#   ecCreditReply - CyberSource::Soap::ECCreditReply
#   ecAuthenticateReply - CyberSource::Soap::ECAuthenticateReply
#   payerAuthEnrollReply - CyberSource::Soap::PayerAuthEnrollReply
#   payerAuthValidateReply - CyberSource::Soap::PayerAuthValidateReply
#   taxReply - CyberSource::Soap::TaxReply
#   afsReply - CyberSource::Soap::AFSReply
#   davReply - CyberSource::Soap::DAVReply
#   exportReply - CyberSource::Soap::ExportReply
#   fxRatesReply - CyberSource::Soap::FXRatesReply
#   bankTransferReply - CyberSource::Soap::BankTransferReply
#   bankTransferRefundReply - CyberSource::Soap::BankTransferRefundReply
#   bankTransferRealTimeReply - CyberSource::Soap::BankTransferRealTimeReply
#   directDebitMandateReply - CyberSource::Soap::DirectDebitMandateReply
#   directDebitReply - CyberSource::Soap::DirectDebitReply
#   directDebitValidateReply - CyberSource::Soap::DirectDebitValidateReply
#   directDebitRefundReply - CyberSource::Soap::DirectDebitRefundReply
#   paySubscriptionCreateReply - CyberSource::Soap::PaySubscriptionCreateReply
#   paySubscriptionUpdateReply - CyberSource::Soap::PaySubscriptionUpdateReply
#   paySubscriptionEventUpdateReply - CyberSource::Soap::PaySubscriptionEventUpdateReply
#   paySubscriptionRetrieveReply - CyberSource::Soap::PaySubscriptionRetrieveReply
#   paySubscriptionDeleteReply - CyberSource::Soap::PaySubscriptionDeleteReply
#   payPalPaymentReply - CyberSource::Soap::PayPalPaymentReply
#   payPalCreditReply - CyberSource::Soap::PayPalCreditReply
#   voidReply - CyberSource::Soap::VoidReply
#   pinlessDebitReply - CyberSource::Soap::PinlessDebitReply
#   pinlessDebitValidateReply - CyberSource::Soap::PinlessDebitValidateReply
#   pinlessDebitReversalReply - CyberSource::Soap::PinlessDebitReversalReply
#   payPalButtonCreateReply - CyberSource::Soap::PayPalButtonCreateReply
#   payPalPreapprovedPaymentReply - CyberSource::Soap::PayPalPreapprovedPaymentReply
#   payPalPreapprovedUpdateReply - CyberSource::Soap::PayPalPreapprovedUpdateReply
#   riskUpdateReply - CyberSource::Soap::RiskUpdateReply
#   fraudUpdateReply - CyberSource::Soap::FraudUpdateReply
#   decisionReply - CyberSource::Soap::DecisionReply
#   reserved - CyberSource::Soap::ReplyReserved
#   payPalRefundReply - CyberSource::Soap::PayPalRefundReply
#   payPalAuthReversalReply - CyberSource::Soap::PayPalAuthReversalReply
#   payPalDoCaptureReply - CyberSource::Soap::PayPalDoCaptureReply
#   payPalEcDoPaymentReply - CyberSource::Soap::PayPalEcDoPaymentReply
#   payPalEcGetDetailsReply - CyberSource::Soap::PayPalEcGetDetailsReply
#   payPalEcSetReply - CyberSource::Soap::PayPalEcSetReply
#   payPalAuthorizationReply - CyberSource::Soap::PayPalAuthorizationReply
#   payPalEcOrderSetupReply - CyberSource::Soap::PayPalEcOrderSetupReply
#   payPalUpdateAgreementReply - CyberSource::Soap::PayPalUpdateAgreementReply
#   payPalCreateAgreementReply - CyberSource::Soap::PayPalCreateAgreementReply
#   payPalDoRefTransactionReply - CyberSource::Soap::PayPalDoRefTransactionReply
#   chinaPaymentReply - CyberSource::Soap::ChinaPaymentReply
#   chinaRefundReply - CyberSource::Soap::ChinaRefundReply
#   boletoPaymentReply - CyberSource::Soap::BoletoPaymentReply
#   receiptNumber - SOAP::SOAPString
#   additionalData - SOAP::SOAPString
#   solutionProviderTransactionID - SOAP::SOAPString
class ReplyMessage
  attr_accessor :merchantReferenceCode
  attr_accessor :requestID
  attr_accessor :decision
  attr_accessor :reasonCode
  attr_accessor :missingField
  attr_accessor :invalidField
  attr_accessor :requestToken
  attr_accessor :purchaseTotals
  attr_accessor :deniedPartiesMatch
  attr_accessor :ccAuthReply
  attr_accessor :ccCaptureReply
  attr_accessor :ccCreditReply
  attr_accessor :ccAuthReversalReply
  attr_accessor :ccAutoAuthReversalReply
  attr_accessor :ccDCCReply
  attr_accessor :ecDebitReply
  attr_accessor :ecCreditReply
  attr_accessor :ecAuthenticateReply
  attr_accessor :payerAuthEnrollReply
  attr_accessor :payerAuthValidateReply
  attr_accessor :taxReply
  attr_accessor :afsReply
  attr_accessor :davReply
  attr_accessor :exportReply
  attr_accessor :fxRatesReply
  attr_accessor :bankTransferReply
  attr_accessor :bankTransferRefundReply
  attr_accessor :bankTransferRealTimeReply
  attr_accessor :directDebitMandateReply
  attr_accessor :directDebitReply
  attr_accessor :directDebitValidateReply
  attr_accessor :directDebitRefundReply
  attr_accessor :paySubscriptionCreateReply
  attr_accessor :paySubscriptionUpdateReply
  attr_accessor :paySubscriptionEventUpdateReply
  attr_accessor :paySubscriptionRetrieveReply
  attr_accessor :paySubscriptionDeleteReply
  attr_accessor :payPalPaymentReply
  attr_accessor :payPalCreditReply
  attr_accessor :voidReply
  attr_accessor :pinlessDebitReply
  attr_accessor :pinlessDebitValidateReply
  attr_accessor :pinlessDebitReversalReply
  attr_accessor :payPalButtonCreateReply
  attr_accessor :payPalPreapprovedPaymentReply
  attr_accessor :payPalPreapprovedUpdateReply
  attr_accessor :riskUpdateReply
  attr_accessor :fraudUpdateReply
  attr_accessor :decisionReply
  attr_accessor :reserved
  attr_accessor :payPalRefundReply
  attr_accessor :payPalAuthReversalReply
  attr_accessor :payPalDoCaptureReply
  attr_accessor :payPalEcDoPaymentReply
  attr_accessor :payPalEcGetDetailsReply
  attr_accessor :payPalEcSetReply
  attr_accessor :payPalAuthorizationReply
  attr_accessor :payPalEcOrderSetupReply
  attr_accessor :payPalUpdateAgreementReply
  attr_accessor :payPalCreateAgreementReply
  attr_accessor :payPalDoRefTransactionReply
  attr_accessor :chinaPaymentReply
  attr_accessor :chinaRefundReply
  attr_accessor :boletoPaymentReply
  attr_accessor :receiptNumber
  attr_accessor :additionalData
  attr_accessor :solutionProviderTransactionID

  def initialize(merchantReferenceCode = nil, requestID = nil, decision = nil, reasonCode = nil, missingField = [], invalidField = [], requestToken = nil, purchaseTotals = nil, deniedPartiesMatch = [], ccAuthReply = nil, ccCaptureReply = nil, ccCreditReply = nil, ccAuthReversalReply = nil, ccAutoAuthReversalReply = nil, ccDCCReply = nil, ecDebitReply = nil, ecCreditReply = nil, ecAuthenticateReply = nil, payerAuthEnrollReply = nil, payerAuthValidateReply = nil, taxReply = nil, afsReply = nil, davReply = nil, exportReply = nil, fxRatesReply = nil, bankTransferReply = nil, bankTransferRefundReply = nil, bankTransferRealTimeReply = nil, directDebitMandateReply = nil, directDebitReply = nil, directDebitValidateReply = nil, directDebitRefundReply = nil, paySubscriptionCreateReply = nil, paySubscriptionUpdateReply = nil, paySubscriptionEventUpdateReply = nil, paySubscriptionRetrieveReply = nil, paySubscriptionDeleteReply = nil, payPalPaymentReply = nil, payPalCreditReply = nil, voidReply = nil, pinlessDebitReply = nil, pinlessDebitValidateReply = nil, pinlessDebitReversalReply = nil, payPalButtonCreateReply = nil, payPalPreapprovedPaymentReply = nil, payPalPreapprovedUpdateReply = nil, riskUpdateReply = nil, fraudUpdateReply = nil, decisionReply = nil, reserved = nil, payPalRefundReply = nil, payPalAuthReversalReply = nil, payPalDoCaptureReply = nil, payPalEcDoPaymentReply = nil, payPalEcGetDetailsReply = nil, payPalEcSetReply = nil, payPalAuthorizationReply = nil, payPalEcOrderSetupReply = nil, payPalUpdateAgreementReply = nil, payPalCreateAgreementReply = nil, payPalDoRefTransactionReply = nil, chinaPaymentReply = nil, chinaRefundReply = nil, boletoPaymentReply = nil, receiptNumber = nil, additionalData = nil, solutionProviderTransactionID = nil)
    @merchantReferenceCode = merchantReferenceCode
    @requestID = requestID
    @decision = decision
    @reasonCode = reasonCode
    @missingField = missingField
    @invalidField = invalidField
    @requestToken = requestToken
    @purchaseTotals = purchaseTotals
    @deniedPartiesMatch = deniedPartiesMatch
    @ccAuthReply = ccAuthReply
    @ccCaptureReply = ccCaptureReply
    @ccCreditReply = ccCreditReply
    @ccAuthReversalReply = ccAuthReversalReply
    @ccAutoAuthReversalReply = ccAutoAuthReversalReply
    @ccDCCReply = ccDCCReply
    @ecDebitReply = ecDebitReply
    @ecCreditReply = ecCreditReply
    @ecAuthenticateReply = ecAuthenticateReply
    @payerAuthEnrollReply = payerAuthEnrollReply
    @payerAuthValidateReply = payerAuthValidateReply
    @taxReply = taxReply
    @afsReply = afsReply
    @davReply = davReply
    @exportReply = exportReply
    @fxRatesReply = fxRatesReply
    @bankTransferReply = bankTransferReply
    @bankTransferRefundReply = bankTransferRefundReply
    @bankTransferRealTimeReply = bankTransferRealTimeReply
    @directDebitMandateReply = directDebitMandateReply
    @directDebitReply = directDebitReply
    @directDebitValidateReply = directDebitValidateReply
    @directDebitRefundReply = directDebitRefundReply
    @paySubscriptionCreateReply = paySubscriptionCreateReply
    @paySubscriptionUpdateReply = paySubscriptionUpdateReply
    @paySubscriptionEventUpdateReply = paySubscriptionEventUpdateReply
    @paySubscriptionRetrieveReply = paySubscriptionRetrieveReply
    @paySubscriptionDeleteReply = paySubscriptionDeleteReply
    @payPalPaymentReply = payPalPaymentReply
    @payPalCreditReply = payPalCreditReply
    @voidReply = voidReply
    @pinlessDebitReply = pinlessDebitReply
    @pinlessDebitValidateReply = pinlessDebitValidateReply
    @pinlessDebitReversalReply = pinlessDebitReversalReply
    @payPalButtonCreateReply = payPalButtonCreateReply
    @payPalPreapprovedPaymentReply = payPalPreapprovedPaymentReply
    @payPalPreapprovedUpdateReply = payPalPreapprovedUpdateReply
    @riskUpdateReply = riskUpdateReply
    @fraudUpdateReply = fraudUpdateReply
    @decisionReply = decisionReply
    @reserved = reserved
    @payPalRefundReply = payPalRefundReply
    @payPalAuthReversalReply = payPalAuthReversalReply
    @payPalDoCaptureReply = payPalDoCaptureReply
    @payPalEcDoPaymentReply = payPalEcDoPaymentReply
    @payPalEcGetDetailsReply = payPalEcGetDetailsReply
    @payPalEcSetReply = payPalEcSetReply
    @payPalAuthorizationReply = payPalAuthorizationReply
    @payPalEcOrderSetupReply = payPalEcOrderSetupReply
    @payPalUpdateAgreementReply = payPalUpdateAgreementReply
    @payPalCreateAgreementReply = payPalCreateAgreementReply
    @payPalDoRefTransactionReply = payPalDoRefTransactionReply
    @chinaPaymentReply = chinaPaymentReply
    @chinaRefundReply = chinaRefundReply
    @boletoPaymentReply = boletoPaymentReply
    @receiptNumber = receiptNumber
    @additionalData = additionalData
    @solutionProviderTransactionID = solutionProviderTransactionID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}FaultDetails
#   requestID - SOAP::SOAPString
class FaultDetails
  attr_accessor :requestID

  def initialize(requestID = nil)
    @requestID = requestID
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}AirlineData
#   agentCode - SOAP::SOAPString
#   agentName - SOAP::SOAPString
#   ticketIssuerCity - SOAP::SOAPString
#   ticketIssuerState - SOAP::SOAPString
#   ticketIssuerPostalCode - SOAP::SOAPString
#   ticketIssuerCountry - SOAP::SOAPString
#   ticketIssuerAddress - SOAP::SOAPString
#   ticketIssuerCode - SOAP::SOAPString
#   ticketIssuerName - SOAP::SOAPString
#   ticketNumber - SOAP::SOAPString
#   checkDigit - SOAP::SOAPInteger
#   restrictedTicketIndicator - SOAP::SOAPInteger
#   transactionType - SOAP::SOAPString
#   extendedPaymentCode - SOAP::SOAPString
#   carrierName - SOAP::SOAPString
#   passengerName - SOAP::SOAPString
#   customerCode - SOAP::SOAPString
#   documentType - SOAP::SOAPString
#   documentNumber - SOAP::SOAPString
#   documentNumberOfParts - SOAP::SOAPString
#   invoiceNumber - SOAP::SOAPString
#   invoiceDate - SOAP::SOAPString
#   chargeDetails - SOAP::SOAPString
#   bookingReference - SOAP::SOAPString
#   totalFee - (any)
#   clearingSequence - SOAP::SOAPString
#   clearingCount - SOAP::SOAPInteger
#   totalClearingAmount - (any)
#   leg - CyberSource::Soap::Leg
#   numberOfPassengers - SOAP::SOAPString
#   reservationSystem - SOAP::SOAPString
#   processIdentifier - SOAP::SOAPString
#   iataNumericCode - SOAP::SOAPString
#   ticketIssueDate - SOAP::SOAPString
#   electronicTicket - SOAP::SOAPString
#   originalTicketNumber - SOAP::SOAPString
class AirlineData
  attr_accessor :agentCode
  attr_accessor :agentName
  attr_accessor :ticketIssuerCity
  attr_accessor :ticketIssuerState
  attr_accessor :ticketIssuerPostalCode
  attr_accessor :ticketIssuerCountry
  attr_accessor :ticketIssuerAddress
  attr_accessor :ticketIssuerCode
  attr_accessor :ticketIssuerName
  attr_accessor :ticketNumber
  attr_accessor :checkDigit
  attr_accessor :restrictedTicketIndicator
  attr_accessor :transactionType
  attr_accessor :extendedPaymentCode
  attr_accessor :carrierName
  attr_accessor :passengerName
  attr_accessor :customerCode
  attr_accessor :documentType
  attr_accessor :documentNumber
  attr_accessor :documentNumberOfParts
  attr_accessor :invoiceNumber
  attr_accessor :invoiceDate
  attr_accessor :chargeDetails
  attr_accessor :bookingReference
  attr_accessor :totalFee
  attr_accessor :clearingSequence
  attr_accessor :clearingCount
  attr_accessor :totalClearingAmount
  attr_accessor :leg
  attr_accessor :numberOfPassengers
  attr_accessor :reservationSystem
  attr_accessor :processIdentifier
  attr_accessor :iataNumericCode
  attr_accessor :ticketIssueDate
  attr_accessor :electronicTicket
  attr_accessor :originalTicketNumber

  def initialize(agentCode = nil, agentName = nil, ticketIssuerCity = nil, ticketIssuerState = nil, ticketIssuerPostalCode = nil, ticketIssuerCountry = nil, ticketIssuerAddress = nil, ticketIssuerCode = nil, ticketIssuerName = nil, ticketNumber = nil, checkDigit = nil, restrictedTicketIndicator = nil, transactionType = nil, extendedPaymentCode = nil, carrierName = nil, passengerName = nil, customerCode = nil, documentType = nil, documentNumber = nil, documentNumberOfParts = nil, invoiceNumber = nil, invoiceDate = nil, chargeDetails = nil, bookingReference = nil, totalFee = nil, clearingSequence = nil, clearingCount = nil, totalClearingAmount = nil, leg = [], numberOfPassengers = nil, reservationSystem = nil, processIdentifier = nil, iataNumericCode = nil, ticketIssueDate = nil, electronicTicket = nil, originalTicketNumber = nil)
    @agentCode = agentCode
    @agentName = agentName
    @ticketIssuerCity = ticketIssuerCity
    @ticketIssuerState = ticketIssuerState
    @ticketIssuerPostalCode = ticketIssuerPostalCode
    @ticketIssuerCountry = ticketIssuerCountry
    @ticketIssuerAddress = ticketIssuerAddress
    @ticketIssuerCode = ticketIssuerCode
    @ticketIssuerName = ticketIssuerName
    @ticketNumber = ticketNumber
    @checkDigit = checkDigit
    @restrictedTicketIndicator = restrictedTicketIndicator
    @transactionType = transactionType
    @extendedPaymentCode = extendedPaymentCode
    @carrierName = carrierName
    @passengerName = passengerName
    @customerCode = customerCode
    @documentType = documentType
    @documentNumber = documentNumber
    @documentNumberOfParts = documentNumberOfParts
    @invoiceNumber = invoiceNumber
    @invoiceDate = invoiceDate
    @chargeDetails = chargeDetails
    @bookingReference = bookingReference
    @totalFee = totalFee
    @clearingSequence = clearingSequence
    @clearingCount = clearingCount
    @totalClearingAmount = totalClearingAmount
    @leg = leg
    @numberOfPassengers = numberOfPassengers
    @reservationSystem = reservationSystem
    @processIdentifier = processIdentifier
    @iataNumericCode = iataNumericCode
    @ticketIssueDate = ticketIssueDate
    @electronicTicket = electronicTicket
    @originalTicketNumber = originalTicketNumber
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Leg
#   carrierCode - SOAP::SOAPString
#   flightNumber - SOAP::SOAPString
#   originatingAirportCode - SOAP::SOAPString
#   m_class - SOAP::SOAPString
#   stopoverCode - SOAP::SOAPString
#   departureDate - SOAP::SOAPString
#   destination - SOAP::SOAPString
#   fareBasis - SOAP::SOAPString
#   departTax - SOAP::SOAPString
#   conjunctionTicket - SOAP::SOAPString
#   exchangeTicket - SOAP::SOAPString
#   couponNumber - SOAP::SOAPString
#   departureTime - SOAP::SOAPString
#   departureTimeSegment - SOAP::SOAPString
#   arrivalTime - SOAP::SOAPString
#   arrivalTimeSegment - SOAP::SOAPString
#   endorsementsRestrictions - SOAP::SOAPString
#   fare - SOAP::SOAPString
#   xmlattr_id - SOAP::SOAPInteger
class Leg
  AttrId = XSD::QName.new(nil, "id")

  attr_accessor :carrierCode
  attr_accessor :flightNumber
  attr_accessor :originatingAirportCode
  attr_accessor :stopoverCode
  attr_accessor :departureDate
  attr_accessor :destination
  attr_accessor :fareBasis
  attr_accessor :departTax
  attr_accessor :conjunctionTicket
  attr_accessor :exchangeTicket
  attr_accessor :couponNumber
  attr_accessor :departureTime
  attr_accessor :departureTimeSegment
  attr_accessor :arrivalTime
  attr_accessor :arrivalTimeSegment
  attr_accessor :endorsementsRestrictions
  attr_accessor :fare

  def m_class
    @v_class
  end

  def m_class=(value)
    @v_class = value
  end

  def __xmlattr
    @__xmlattr ||= {}
  end

  def xmlattr_id
    __xmlattr[AttrId]
  end

  def xmlattr_id=(value)
    __xmlattr[AttrId] = value
  end

  def initialize(carrierCode = nil, flightNumber = nil, originatingAirportCode = nil, v_class = nil, stopoverCode = nil, departureDate = nil, destination = nil, fareBasis = nil, departTax = nil, conjunctionTicket = nil, exchangeTicket = nil, couponNumber = nil, departureTime = nil, departureTimeSegment = nil, arrivalTime = nil, arrivalTimeSegment = nil, endorsementsRestrictions = nil, fare = nil)
    @carrierCode = carrierCode
    @flightNumber = flightNumber
    @originatingAirportCode = originatingAirportCode
    @v_class = v_class
    @stopoverCode = stopoverCode
    @departureDate = departureDate
    @destination = destination
    @fareBasis = fareBasis
    @departTax = departTax
    @conjunctionTicket = conjunctionTicket
    @exchangeTicket = exchangeTicket
    @couponNumber = couponNumber
    @departureTime = departureTime
    @departureTimeSegment = departureTimeSegment
    @arrivalTime = arrivalTime
    @arrivalTimeSegment = arrivalTimeSegment
    @endorsementsRestrictions = endorsementsRestrictions
    @fare = fare
    @__xmlattr = {}
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Pos
#   entryMode - SOAP::SOAPString
#   cardPresent - SOAP::SOAPString
#   terminalCapability - SOAP::SOAPString
#   trackData - SOAP::SOAPString
#   terminalID - SOAP::SOAPString
#   terminalType - SOAP::SOAPString
#   terminalLocation - SOAP::SOAPString
#   transactionSecurity - SOAP::SOAPString
#   catLevel - SOAP::SOAPString
#   conditionCode - SOAP::SOAPString
class Pos
  attr_accessor :entryMode
  attr_accessor :cardPresent
  attr_accessor :terminalCapability
  attr_accessor :trackData
  attr_accessor :terminalID
  attr_accessor :terminalType
  attr_accessor :terminalLocation
  attr_accessor :transactionSecurity
  attr_accessor :catLevel
  attr_accessor :conditionCode

  def initialize(entryMode = nil, cardPresent = nil, terminalCapability = nil, trackData = nil, terminalID = nil, terminalType = nil, terminalLocation = nil, transactionSecurity = nil, catLevel = nil, conditionCode = nil)
    @entryMode = entryMode
    @cardPresent = cardPresent
    @terminalCapability = terminalCapability
    @trackData = trackData
    @terminalID = terminalID
    @terminalType = terminalType
    @terminalLocation = terminalLocation
    @transactionSecurity = transactionSecurity
    @catLevel = catLevel
    @conditionCode = conditionCode
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}Installment
#   sequence - SOAP::SOAPString
#   totalCount - SOAP::SOAPString
#   totalAmount - SOAP::SOAPString
#   frequency - SOAP::SOAPString
#   amount - SOAP::SOAPString
class Installment
  attr_accessor :sequence
  attr_accessor :totalCount
  attr_accessor :totalAmount
  attr_accessor :frequency
  attr_accessor :amount

  def initialize(sequence = nil, totalCount = nil, totalAmount = nil, frequency = nil, amount = nil)
    @sequence = sequence
    @totalCount = totalCount
    @totalAmount = totalAmount
    @frequency = frequency
    @amount = amount
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}MerchantDefinedData
#   field1 - SOAP::SOAPString
#   field2 - SOAP::SOAPString
#   field3 - SOAP::SOAPString
#   field4 - SOAP::SOAPString
#   field5 - SOAP::SOAPString
#   field6 - SOAP::SOAPString
#   field7 - SOAP::SOAPString
#   field8 - SOAP::SOAPString
#   field9 - SOAP::SOAPString
#   field10 - SOAP::SOAPString
#   field11 - SOAP::SOAPString
#   field12 - SOAP::SOAPString
#   field13 - SOAP::SOAPString
#   field14 - SOAP::SOAPString
#   field15 - SOAP::SOAPString
#   field16 - SOAP::SOAPString
#   field17 - SOAP::SOAPString
#   field18 - SOAP::SOAPString
#   field19 - SOAP::SOAPString
#   field20 - SOAP::SOAPString
class MerchantDefinedData
  attr_accessor :field1
  attr_accessor :field2
  attr_accessor :field3
  attr_accessor :field4
  attr_accessor :field5
  attr_accessor :field6
  attr_accessor :field7
  attr_accessor :field8
  attr_accessor :field9
  attr_accessor :field10
  attr_accessor :field11
  attr_accessor :field12
  attr_accessor :field13
  attr_accessor :field14
  attr_accessor :field15
  attr_accessor :field16
  attr_accessor :field17
  attr_accessor :field18
  attr_accessor :field19
  attr_accessor :field20

  def initialize(field1 = nil, field2 = nil, field3 = nil, field4 = nil, field5 = nil, field6 = nil, field7 = nil, field8 = nil, field9 = nil, field10 = nil, field11 = nil, field12 = nil, field13 = nil, field14 = nil, field15 = nil, field16 = nil, field17 = nil, field18 = nil, field19 = nil, field20 = nil)
    @field1 = field1
    @field2 = field2
    @field3 = field3
    @field4 = field4
    @field5 = field5
    @field6 = field6
    @field7 = field7
    @field8 = field8
    @field9 = field9
    @field10 = field10
    @field11 = field11
    @field12 = field12
    @field13 = field13
    @field14 = field14
    @field15 = field15
    @field16 = field16
    @field17 = field17
    @field18 = field18
    @field19 = field19
    @field20 = field20
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}MerchantSecureData
#   field1 - SOAP::SOAPString
#   field2 - SOAP::SOAPString
#   field3 - SOAP::SOAPString
#   field4 - SOAP::SOAPString
class MerchantSecureData
  attr_accessor :field1
  attr_accessor :field2
  attr_accessor :field3
  attr_accessor :field4

  def initialize(field1 = nil, field2 = nil, field3 = nil, field4 = nil)
    @field1 = field1
    @field2 = field2
    @field3 = field3
    @field4 = field4
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}ReplyReserved
class ReplyReserved
  attr_reader :__xmlele_any

  def set_any(elements)
    @__xmlele_any = elements
  end

  def initialize
    @__xmlele_any = nil
  end
end

# {urn:schemas-cybersource-com:transaction-data-1.67}RequestReserved
#   name - SOAP::SOAPString
#   value - SOAP::SOAPString
class RequestReserved
  attr_accessor :name
  attr_accessor :value

  def initialize(name = nil, value = nil)
    @name = name
    @value = value
  end
end


end; end
