module ActiveMerchant #:nodoc:
    module Billing #:nodoc:
        class OxxoGateway < Gateway
            URL = 'https://banwire.com/api.oxxo'

            self.supported_countries = ['MX']
            self.homepage_url = 'http://www.banwire.com/'
            self.display_name = 'OXXO'

            def initialize(options = {})
                requires!(options, :login)
                @options = options
                super
            end

            def purchase(money, source, options = {})
                post = {}
                add_response_type(post)
                add_config_data(post, options)
                add_order_data(post, options)
                add_amount(money, post, options)

                commit(post)
            end

            private

            def add_response_type(post)
                post[:formato] = "HTTPQUERY"
            end

            def add_config_data(post, options)
                post[:usuario] = @options[:login]
                post[:url_respuesta] = options[:notification_url]
                post[:sendPDF] = false
                post[:dias_vigencia] = options[:available_days]
            end

            def add_order_data(post, options)
                post[:referencia] = options[:order_id]
                post[:cliente] = options[:name]
                post[:email] = options[:email]
            end

            def add_amount(money, post, options)
                post[:monto] = amount(money)
            end

            def parse(body)
                response = parsed = CGI::parse(body)
                response.each do |k, v|
                    response[k] = v.first
                end
            end

            def commit(parameters)
                response = parse(ssl_post(URL, post_data(parameters)))
                Response.new(success?(response),
                             response["error_message"],
                             response,
                             :test => test?,
                             :authorization => response["error"])
            end

            def success?(response)
                (response["error"] == "0")
            end

            def post_data(parameters = {})
                parameters.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
            end
        end
    end
end
