require 'test_helper'

class RemoteVestaTest < Test::Unit::TestCase

  def setup
    @gateway = VestaGateway.new(fixtures(:vesta))
    @amount = 200

    @credit_card = ActiveMerchant::Billing::CreditCard.new(
      number:             "340001234527890",
      verification_value: "183",
      month:              "01",
      year:               "2019",
      first_name:         "Mario F.",
      last_name:          "Moreno Reyes"
    )

    @declined_card = ActiveMerchant::Billing::CreditCard.new(
      number:             "4614201234597890",
      verification_value: "205",
      month:              "01",
      year:               "2019",
      first_name:         "John",
      last_name:          "Doe"
    )

    @options = {
      device_fingerprint: "41l9l92hjco6cuekf0c7dq68v4",
      order_id: "345454tdf54hj8",
      description: 'Blue clip',
      billing_address: {
        address1: "Rio Missisipi #123",
        address2: "Paris",
        city: "Guerrero",
        country: "Mexico",
        zip: "5555",
        name: "Mario Reyes",
        phone: "12345678",
      }
    }
  end

  def test_successful_purchase
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal nil, response.message
  end

  def test_failed_purchase
    response = @gateway.purchase(@amount, @declined_card, @options)
    assert_success response
    assert_equal "1", response.params["PaymentStatus"]
  end

  def test_successful_refund
    purchase = @gateway.purchase(@amount, @credit_card, @options)
    assert_success purchase
    @options[:payment_id] = purchase.params["PaymentID"]

    assert refund = @gateway.refund(@amount, @credit_card, @options)
    assert_success refund
    assert_equal "1", refund.params["ReversalAction"]
    assert_equal "10", refund.params["PaymentStatus"]
  end

  def test_successful_authorize
    assert response = @gateway.authorize(@amount, @credit_card, @options)
    assert_success response
    assert_equal nil, response.message
  end

  def test_unsuccessful_authorize
    assert response = @gateway.authorize(@amount, @declined_card, @options)
    assert_success response
    assert_equal nil, response.message
  end

  def test_successful_charge_confirm
    assert authorize = @gateway.authorize(@amount, @credit_card, @options)
    assert_success authorize
    assert_equal nil, authorize.message
    @options[:payment_id] = authorize.params["PaymentID"]

    assert response = @gateway.capture(@amount, @credit_card, @options)
    assert_success response
    assert_equal nil, response.message
  end

  def test_invalid_login
    gateway = VestaGateway.new(account_name: 'invalid', password: 'invalid')
    response = gateway.purchase(@amount, @credit_card, @options)
    assert_match "Login failed", response.message
  end

end
