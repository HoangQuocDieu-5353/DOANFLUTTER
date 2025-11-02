/// 🧾 Apple Pay config — dùng cho iOS
const String defaultApplePay = '''{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.com.example.flowerapp",
    "displayName": "Cửa hàng hoa Flutter",
    "merchantCapabilities": ["3DS", "debit", "credit"],
    "supportedNetworks": ["visa", "masterCard"],
    "countryCode": "VN",
    "currencyCode": "VND",
    "requiredBillingContactFields": ["emailAddress", "name", "phoneNumber"],
    "requiredShippingContactFields": [],
    "shippingMethods": [
      {
        "amount": "0.00",
        "detail": "Miễn phí giao hàng nội thành",
        "identifier": "free_shipping",
        "label": "Miễn phí giao hàng"
      }
    ]
  }
}''';


/// Google Pay 
const String defaultGooglePayVND = '''{
  "provider": "google_pay",
  "data": {
    "environment": "TEST",
    "apiVersion": 2,
    "apiVersionMinor": 0,
    "allowedPaymentMethods": [
      {
        "type": "CARD",
        "parameters": {
          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
          "allowedCardNetworks": ["VISA", "MASTERCARD"],
          "billingAddressRequired": true,
          "billingAddressParameters": {
            "format": "FULL",
            "phoneNumberRequired": true
          }
        },
        "tokenizationSpecification": {
          "type": "PAYMENT_GATEWAY",
          "parameters": {
            "gateway": "example",
            "gatewayMerchantId": "exampleGatewayMerchantId"
          }
        }
      }
    ],
    "merchantInfo": {
      "merchantId": "01234567890123456789",
      "merchantName": "Cửa hàng hoa Flutter"
    },
    "transactionInfo": {
      "countryCode": "VN",
      "currencyCode": "VND",
      "totalPriceStatus": "FINAL",
      "totalPrice": "0"
    }
  }
}''';
