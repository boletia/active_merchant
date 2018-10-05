module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class VestaGateway < Gateway
      self.test_url = 'https://vsafesandbox.ecustomersupport.com/GatewayV4Proxy/Service/'
      self.live_url = 'https://vsafesandbox.ecustomersupport.com/GatewayV4Proxy/Service/'

      self.supported_countries = ['MX']
      self.default_currency = 'MXN'
      self.supported_cardtypes = [:visa, :master, :american_express]
      self.money_format = :decimals

      self.homepage_url = 'https://trustvesta.com/'
      self.display_name = 'Vesta Gateway'


      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options={})
        requires!(options, :account_name, :password)
        options[:version] ||= '3.3.1'
        @credentials = options
        super
      end

      def purchase(money, payment, options={})
        post = initialize_post
        add_order(post, money, options)
        add_payment_source(post, payment, options)
        add_address(post, payment, options)
        commit(:post, 'ChargeSale', post)
      end

      def authorize(money, payment, options={})
        post = initialize_post
        add_order(post, money, options)
        add_payment_source(post, payment, options)
        add_address(post, payment, options)
        commit(:post, 'ChargeAuthorize', post)
      end

      def capture(money, payment, options={})
        post = initialize_post
        add_order(post, money, options)
        add_payment_source(post, payment, options)
        add_previous_payment_source(post, money, options)
        commit(:post, 'ChargeConfirm', post)
      end

      def refund(money, payment, options={})
        post = initialize_post
        add_order(post, money, options)
        add_payment_source(post, payment, options)
        add_previous_payment_source(post, money, options)
        commit(:post, 'ReversePayment', post)
      end

      def void(authorization, options={})
        commit('void', post)
      end

      def verify(credit_card, options={})
        MultiResponse.run(:use_first_response) do |r|
          r.process { authorize(100, credit_card, options) }
          r.process(:ignore_result) { void(r.authorization, options) }
        end
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript.
          gsub(%r((\"{\\\"AccountName\\\":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r((\\\"Password\\\":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r((\\\"ChargeAccountNumber\\\":\\?")[^"]*)i, '\1[FILTERED]').
          gsub(%r((\\\"ChargeCVN\\\":\\?")[^"]*)i, '\1[FILTERED]')
      end

      private

      def add_order(post, money, options)
        post[:TransactionID] = options[:order_id] if options[:order_id]
        post[:ChargeAmount] = amount(money)
        post[:ChargeSource] = "WEB"
        post[:StoreCard] = "false"
        post[:WebSessionID] = options[:web_session_id] if options[:web_session_id]
        post[:Fingerprint] = options[:fingerprint] if options[:fingerprint]
        post[:MerchantRoutingID] = "SandboxCredit01"
        post[:RiskInformation] = options[:risk_information]
      end

      def add_address(post, creditcard, options)
        if(address = (options[:billing_address] || options[:address] ))
          post[:CardHolderAddressLine1] = address[:address1] if address[:address1]
          post[:CardHolderCity] = address[:city] if address[:city]
          post[:CardHolderRegion] = "DF"
          post[:CardHolderPostalCode] = address[:zip] if address[:zip]
          post[:CardHolderCountryCode] = "MX"
        end
      end

      def add_payment_source(post, payment_source, options)
        post[:CardHolderFirstName] = payment_source.name
        post[:CardHolderLastName] = payment_source.name
        post[:ChargeAccountNumber] = payment_source.number
        post[:ChargeAccountNumberIndicator] = "1"
        post[:ChargeCVN] = payment_source.verification_value
        post[:ChargeExpirationMMYY] = "#{sprintf("%02d", payment_source.month)}#{"#{payment_source.year}"[-2, 2]}"
      end

      def add_previous_payment_source(post, money, options)
        post[:RefundAmount] = amount(money)
        post[:PaymentID] = options[:payment_id]
        post[:ChargeAccountNumber] = nil
      end

      def parse(body)
        return {} unless body
        JSON.parse(body)
      end

      def headers
        {
          "Content-Type" => "application/json"
        }
      end

      def commit(method, action, parameters)
        url = (test? ? test_url : live_url)
        raw_response = parse(ssl_request(method, url + action, (parameters ? parameters.to_json : nil),  headers))
        begin
          response = raw_response
        rescue ResponseError => e
          response = response_error(e.response.body)
        rescue JSON::ParserError
          response = json_error(raw_response)
        rescue StandardError => e
          response = e.message
        end

        Response.new(
          success_from(response),
          message_from(response),
          response,
          authorization: authorization_from(response),
          test: test?
        )
      end

      def success_from(response)
        valid_status = {"10"=>"complete" , "5"=>"authorized"}
        response.key?("ResponseCode") && response["ResponseCode"] == "0" && valid_status.keys.include?(response["PaymentStatus"])
      end

      def message_from(response)
        if response["ResponseCode"] == 0
          response.except("ResponseCode")
        else
          response["ResponseText"]
        end
      end

      def authorization_from(response)
        if response["ResponseCode"] == 0
         response["PaymentStatus"] == 10
        else
          false
        end
      end

      def post_data(action, parameters = {})
        parameters.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
      end

      def error_code_from(response)
        unless success_from(response)
          # TODO: lookup error code for this response
        end
      end

      def initialize_post()
        post = {}
        post[:AccountName] = @credentials[:account_name]
        post[:Password] = @credentials[:password]
        post
      end
    end
  end
end
