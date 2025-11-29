# frozen_string_literal: true

module Household
  class LineItemsController < Household::BaseController
    before_action :set_line_item, only: %i[edit update destroy]

    def index
      @line_items = Current.family.household_line_items
        .for_period(@period_date)
        .includes(:member)
        .ordered_by_category
    end

    def new
      @line_item = Current.family.household_line_items.build(
        period_date: @period_date,
        currency: Current.family.currency
      )
    end

    def create
      @line_item = Current.family.household_line_items.build(line_item_params)
      @line_item.period_date = @period_date

      if @line_item.save
        redirect_to household_line_items_path(period: period_param), notice: "Item creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @line_item.update(line_item_params)
        redirect_to household_line_items_path(period: period_param), notice: "Item actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @line_item.destroy
      redirect_to household_line_items_path(period: period_param), notice: "Item eliminado exitosamente."
    end

    # Copy all line items from previous month to current period
    def copy_from_previous
      previous_period = @period_date - 1.month
      Household::LineItem.copy_period(Current.family, from_period: previous_period, to_period: @period_date)
      redirect_to household_line_items_path(period: period_param), notice: "Items copiados del mes anterior."
    end

    private

    def set_line_item
      @line_item = Current.family.household_line_items.find(params[:id])
    end

    def line_item_params
      params.require(:household_line_item).permit(
        :household_member_id,
        :category,
        :description,
        :payment_cycle,
        :item_type,
        :kind,
        :amount_cents,
        :currency,
        :notes
      )
    end
  end
end

