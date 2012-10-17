# encoding: utf-8
require 'test_helper'

class RemoteOxxoTest < Test::Unit::TestCase
  def setup
    @gateway = OxxoGateway.new(fixtures(:oxxo))

    @options = {
      :booking_code => 'cagrncwoqps2',
      :email => 'test@email.com',
      :notifaction_url => "http://test.com/notifyme",
      :send_pdf => false,
      :available_days => 10,
      :full_name => "Arnoldo Rodriguez Colin",
      :email => "acolin@incaztch.com",
      :total => 1500.00
    }

  end

  def test_successful_purchase
    assert response = @gateway.purchase(@options)
    assert_success response
  end

  def test_unsuccessful_purchase
    @options.delete(:total)
    assert response = @gateway.purchase(@options)
    assert_failure response
  end
end
