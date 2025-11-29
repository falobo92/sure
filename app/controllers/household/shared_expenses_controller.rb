# frozen_string_literal: true

module Household
  class SharedExpensesController < Household::BaseController
    before_action :set_shared_expense, only: %i[edit update destroy]

    def index
      @shared_expenses = Current.family.household_shared_expenses
        .for_period(@period_date)
        .includes(:member)
        .ordered_by_date
    end

    def new
      @shared_expense = Current.family.household_shared_expenses.build(
        expense_date: Date.current,
        currency: Current.family.currency
      )
    end

    def create
      @shared_expense = Current.family.household_shared_expenses.build(shared_expense_params)

      if @shared_expense.save
        redirect_to household_shared_expenses_path(period: period_param), notice: "Gasto compartido creado exitosamente."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shared_expense.update(shared_expense_params)
        redirect_to household_shared_expenses_path(period: period_param), notice: "Gasto compartido actualizado exitosamente."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shared_expense.destroy
      redirect_to household_shared_expenses_path(period: period_param), notice: "Gasto compartido eliminado exitosamente."
    end

    private

    def set_shared_expense
      @shared_expense = Current.family.household_shared_expenses.find(params[:id])
    end

    def shared_expense_params
      params.require(:household_shared_expense).permit(
        :household_member_id,
        :description,
        :amount_cents,
        :currency,
        :expense_date,
        :shared
      )
    end
  end
end

