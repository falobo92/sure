# frozen_string_literal: true

module HouseholdHelper
  def currency_symbol(currency)
    Money::Currency.new(currency).symbol
  rescue
    currency
  end
end

