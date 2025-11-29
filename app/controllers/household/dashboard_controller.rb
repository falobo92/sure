# frozen_string_literal: true

module Household
  class DashboardController < Household::BaseController
    def show
      @settlement = Household::MonthlySettlement.new(Current.family, period_date: @period_date)
      @line_items = Current.family.household_line_items.for_period(@period_date).ordered_by_category
      @shared_expenses = Current.family.household_shared_expenses.for_period(@period_date).ordered_by_date
    end
  end
end

