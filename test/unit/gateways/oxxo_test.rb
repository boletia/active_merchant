require 'test_helper'

class OxxoTest < Test::Unit::TestCase
  include CommStub

  def setup
    @gateway = OxxoGateway.new(fixtures(:oxxo))

    @options = {
      :booking_code => 'cagrncwoqps2',
      :email => 'test@email.com',
      :notification_url => "http://www.test.com",
      :send_pdf => false,
      :available_days => 10,
      :full_name => "Arnoldo Rodriguez Colin",
      :email => "acolin@incaztch.com",
      :total => 1500.00
    }
  end

  def test_successful_purchase
    #@gateway.expects(:ssl_post).returns(successful_purchase_response)

    assert response = @gateway.purchase(@options)
    assert_success response

    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    assert response = @gateway.purchase(@options)
    assert_failure response
    assert response.test?
  end

  private

  def failed_purchase_response
    <<-RESPONSE
    {"error":"true","error_msg":"variables de configuracion faltantes: referencia"}
    RESPONSE
  end

  def successful_purchase_response
    <<-RESPONSE
    {"error":"false","response":{"barcode_mg": "iVBORw0KGgoAAAANSUhEUgAAASwAAABOAQMAAACg+LnTAAAABlBMVEX///8AAABVwtN+AAABN0lEQVRIiWP4Twz4wNDAQAQQGFVGkTLG4LCwVLVrMyOnRvkuTVtyzTssVXfpkku5GaPKRpWNKhtVNqpsVBm9lBEAA6uMvYlHQqLyR+Hjw4eZ+FkkKiwSDhxob2aTQ1PG4SakotLK0CSiotIm0KPS4jBRUbHDpVMRXZmXopNTKyOTiIqGl8AUp5ZGLiGhDo+AhehucwIqY2VkEFDQcGJocWIBKhNo8AhoRFPG2ARUZvnxw8MDJ5yYWZwkfgKVNXYE9KEpY2ICKmPh5BBQ5HBiYXFSaAUqa+LAMI0FpkyJw4mDxckBpKwFUxkHSFkLJ5eICoeTAItTA0hZBweGFziYQAECUsbSJMCi0tAyUVGhgwUjQPjP90hIVHz4+Pj4Y/758yX+VCQcOPz+MEbwEhlZo8poo4y4pjsAQ8yaZodoTmIAAAAASUVORK5CYII=", "barcode":"21000356332012102600012003", "referencia":"cagrncwoqps2", "fecha_vigencia":"2012-10-26", "monto":"1500.00", "path_img":"cagrncwoqps2.png"}}
    RESPONSE
  end
end
