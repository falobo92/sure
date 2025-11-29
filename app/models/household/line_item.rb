# frozen_string_literal: true

module Household
  class LineItem < ApplicationRecord
    self.table_name = "household_line_items"

    # Enums for item classification
    # payment_cycle: Which payment cycle this item belongs to
    #   1 = First member's cycle (e.g., salary on day 25 of previous month)
    #   2 = Second member's cycle (e.g., salary on day 5 of current month)
    #   3 = Sporadic/special (no fixed date)
    enum :payment_cycle, { cycle_1: 1, cycle_2: 2, sporadic: 3 }, prefix: :cycle

    # item_type: Variability of the item
    #   constant = Fixed amount each month (CTE)
    #   variable = Amount varies month to month (VAR)
    #   special = One-off or sporadic item (ESP)
    enum :item_type, { constant: "constant", variable: "variable", special: "special" }, prefix: :type

    # kind: Whether this is income or expense
    enum :kind, { income: "income", expense: "expense" }

    belongs_to :family
    belongs_to :member, class_name: "Household::Member", foreign_key: :household_member_id, optional: true

    validates :category, presence: true
    validates :description, presence: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :currency, presence: true
    validates :period_date, presence: true
    validates :payment_cycle, presence: true
    validates :kind, presence: true
    validates :item_type, presence: true

    scope :incomes, -> { where(kind: :income) }
    scope :expenses, -> { where(kind: :expense) }
    scope :for_period, ->(period_date) { where(period_date: period_date.beginning_of_month) }
    scope :for_cycle, ->(cycle) { where(payment_cycle: cycle) }
    scope :ordered_by_category, -> { order(:category, :description) }

    # Returns the signed amount (positive for income, negative for expense)
    def signed_amount
      income? ? amount_cents : -amount_cents
    end

    # Display helpers
    def payment_cycle_label
      case payment_cycle
      when "cycle_1" then "N°1"
      when "cycle_2" then "N°2"
      when "sporadic" then "N°3"
      end
    end

    def item_type_label
      case item_type
      when "constant" then "CTE"
      when "variable" then "VAR"
      when "special" then "ESP"
      end
    end

    def kind_label
      income? ? "Ingreso" : "Gasto"
    end

    # Copy this line item to a new period
    def copy_to_period(new_period_date)
      family.household_line_items.create!(
        household_member_id: household_member_id,
        category: category,
        description: description,
        payment_cycle: payment_cycle,
        item_type: item_type,
        kind: kind,
        amount_cents: amount_cents,
        currency: currency,
        period_date: new_period_date.beginning_of_month,
        notes: notes
      )
    end

    # Class method to copy all line items from one period to another
    def self.copy_period(family, from_period:, to_period:)
      items = family.household_line_items.for_period(from_period)
      items.each do |item|
        item.copy_to_period(to_period)
      end
    end
  end
end

