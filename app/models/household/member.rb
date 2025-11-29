# frozen_string_literal: true

module Household
  class Member < ApplicationRecord
    self.table_name = "household_members"

    belongs_to :family
    has_many :line_items, class_name: "Household::LineItem", foreign_key: :household_member_id, dependent: :nullify
    has_many :shared_expenses, class_name: "Household::SharedExpense", foreign_key: :household_member_id, dependent: :destroy

    validates :name, presence: true
    validates :code, presence: true, length: { maximum: 10 }
    validates :code, uniqueness: { scope: :family_id }

    scope :ordered, -> { order(position: :asc) }

    before_create :set_default_position

    def display_name
      "#{name} (#{code})"
    end

    # Returns all incomes associated with this member for a given period
    def incomes_for_period(period_date)
      line_items.incomes.for_period(period_date)
    end

    # Returns all expenses associated with this member for a given period
    def expenses_for_period(period_date)
      line_items.expenses.for_period(period_date)
    end

    # Returns shared expenses for a given period
    def shared_expenses_for_period(period_date)
      shared_expenses.for_period(period_date).shared_only
    end

    # Total shared expenses amount for a period
    def total_shared_expenses_for_period(period_date)
      shared_expenses_for_period(period_date).sum(:amount_cents)
    end

    private

    def set_default_position
      self.position ||= family.household_members.maximum(:position).to_i + 1
    end
  end
end

