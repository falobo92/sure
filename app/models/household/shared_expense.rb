# frozen_string_literal: true

module Household
  class SharedExpense < ApplicationRecord
    self.table_name = "household_shared_expenses"

    belongs_to :family
    belongs_to :member, class_name: "Household::Member", foreign_key: :household_member_id

    validates :description, presence: true
    validates :amount_cents, presence: true, numericality: { greater_than: 0 }
    validates :currency, presence: true
    validates :expense_date, presence: true
    validates :period_date, presence: true

    before_validation :set_period_date_from_expense_date

    scope :for_period, ->(period_date) { where(period_date: period_date.beginning_of_month) }
    scope :shared_only, -> { where(shared: true) }
    scope :ordered_by_date, -> { order(expense_date: :desc) }
    scope :for_member, ->(member) { where(household_member: member) }

    def member_name
      member&.name || "Sin asignar"
    end

    private

    def set_period_date_from_expense_date
      self.period_date = expense_date&.beginning_of_month
    end
  end
end

