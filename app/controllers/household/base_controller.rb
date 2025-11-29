# frozen_string_literal: true

module Household
  class BaseController < ApplicationController
    layout "application"

    before_action :set_period
    before_action :set_members

    private

    def set_period
      @period_date = if params[:period].present?
        Date.strptime(params[:period], "%Y-%m").beginning_of_month
      else
        Date.current.beginning_of_month
      end
    rescue ArgumentError
      @period_date = Date.current.beginning_of_month
    end

    def set_members
      @members = Current.family.household_members.ordered
    end

    def period_param
      @period_date.strftime("%Y-%m")
    end
    helper_method :period_param

    def previous_period_param
      (@period_date - 1.month).strftime("%Y-%m")
    end
    helper_method :previous_period_param

    def next_period_param
      next_date = @period_date + 1.month
      return nil if next_date > Date.current.beginning_of_month

      next_date.strftime("%Y-%m")
    end
    helper_method :next_period_param

    def period_name
      I18n.l(@period_date, format: "%B %Y")
    end
    helper_method :period_name
  end
end

