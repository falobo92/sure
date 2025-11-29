# frozen_string_literal: true

require "test_helper"

module Household
  class MonthlySettlementTest < ActiveSupport::TestCase
    setup do
      @family = families(:dylan_family)
      @period_date = Date.current.beginning_of_month

      # Clean slate
      @family.household_members.destroy_all
      @family.household_line_items.destroy_all
      @family.household_shared_expenses.destroy_all

      # Create members
      @felipe = @family.household_members.create!(name: "Felipe", code: "FL", position: 1)
      @romina = @family.household_members.create!(name: "Romina", code: "RP", position: 2)
    end

    test "calculates total incomes" do
      create_income(@felipe, :cycle_1, 3_000_000)
      create_income(@romina, :cycle_2, 2_500_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)
      assert_equal 5_500_000, settlement.total_incomes
    end

    test "calculates total fixed expenses" do
      create_expense(@felipe, :cycle_1, 1_000_000)
      create_expense(@romina, :cycle_2, 750_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)
      assert_equal 1_750_000, settlement.total_fixed_expenses
    end

    test "calculates cycle settlement for cycle 1" do
      # Felipe: income 3M, expenses 1M
      create_income(@felipe, :cycle_1, 3_000_000)
      create_expense(@felipe, :cycle_1, 1_000_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)
      cycle_data = settlement.cycle_settlement(:cycle_1)

      assert_equal 3_000_000, cycle_data[:incomes]
      assert_equal 1_000_000, cycle_data[:expenses]
      assert_equal 2_000_000, cycle_data[:balance]
      assert_equal 1_000_000, cycle_data[:half_balance]
    end

    test "calculates member settlement with shared expenses adjustment" do
      # Felipe: income 3M, expenses 1M, shared expenses 200K
      create_income(@felipe, :cycle_1, 3_000_000)
      create_expense(@felipe, :cycle_1, 1_000_000)
      create_shared_expense(@felipe, 200_000)

      # Romina: income 2.5M, expenses 750K, shared expenses 100K
      create_income(@romina, :cycle_2, 2_500_000)
      create_expense(@romina, :cycle_2, 750_000)
      create_shared_expense(@romina, 100_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)
      member1_settlement = settlement.member_1_settlement

      # Cycle 1 balance: 3M - 1M = 2M
      # Half balance: 1M
      # Felipe's shared expenses: 200K
      # Reimbursement (half of shared): 100K
      # Transfer to other: 1M - 100K = 900K

      assert_equal 3_000_000, member1_settlement[:incomes]
      assert_equal 1_000_000, member1_settlement[:fixed_expenses]
      assert_equal 2_000_000, member1_settlement[:cycle_balance]
      assert_equal 1_000_000.0, member1_settlement[:half_balance]
      assert_equal 200_000, member1_settlement[:shared_expenses_paid]
      assert_equal 100_000.0, member1_settlement[:shared_reimbursement]
      assert_equal 900_000.0, member1_settlement[:transfer_to_other]
    end

    test "calculates net transfer between members" do
      # Felipe: income 3M, expenses 1M, shared 200K
      # Cycle balance: 2M, half: 1M, transfer: 1M - 100K = 900K

      create_income(@felipe, :cycle_1, 3_000_000)
      create_expense(@felipe, :cycle_1, 1_000_000)
      create_shared_expense(@felipe, 200_000)

      # Romina: income 2.5M, expenses 750K, shared 100K
      # Cycle balance: 1.75M, half: 875K, transfer: 875K - 50K = 825K

      create_income(@romina, :cycle_2, 2_500_000)
      create_expense(@romina, :cycle_2, 750_000)
      create_shared_expense(@romina, 100_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)

      # Net: Felipe to Romina (900K) - Romina to Felipe (825K) = 75K
      # Felipe owes Romina 75K
      assert_equal 75_000.0, settlement.net_transfer
    end

    test "summary returns complete structure" do
      create_income(@felipe, :cycle_1, 3_000_000)
      create_expense(@felipe, :cycle_1, 1_000_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)
      summary = settlement.summary

      assert_includes summary.keys, :period
      assert_includes summary.keys, :period_name
      assert_includes summary.keys, :members
      assert_includes summary.keys, :totals
      assert_includes summary.keys, :by_category
      assert_includes summary.keys, :by_cycle
      assert_includes summary.keys, :member_settlements
      assert_includes summary.keys, :transfers
      assert_includes summary.keys, :libre_each
    end

    test "handles empty household gracefully" do
      @family.household_members.destroy_all

      settlement = MonthlySettlement.new(@family, period_date: @period_date)

      assert_equal 0, settlement.total_incomes
      assert_equal 0, settlement.total_fixed_expenses
      assert_equal 0, settlement.net_transfer
    end

    test "handles single member household" do
      @romina.destroy

      create_income(@felipe, :cycle_1, 3_000_000)
      create_expense(@felipe, :cycle_1, 1_000_000)

      settlement = MonthlySettlement.new(@family, period_date: @period_date)

      assert_not_nil settlement.member_1_settlement
      assert_nil settlement.member_2_settlement
      assert_equal 0, settlement.net_transfer
    end

    private

    def create_income(member, cycle, amount)
      @family.household_line_items.create!(
        household_member: member,
        category: "Ingreso",
        description: "Test Income",
        payment_cycle: cycle,
        item_type: :constant,
        kind: :income,
        amount_cents: amount,
        currency: "CLP",
        period_date: @period_date
      )
    end

    def create_expense(member, cycle, amount)
      @family.household_line_items.create!(
        household_member: member,
        category: "Gasto",
        description: "Test Expense",
        payment_cycle: cycle,
        item_type: :constant,
        kind: :expense,
        amount_cents: amount,
        currency: "CLP",
        period_date: @period_date
      )
    end

    def create_shared_expense(member, amount)
      @family.household_shared_expenses.create!(
        household_member: member,
        description: "Test Shared Expense",
        amount_cents: amount,
        currency: "CLP",
        expense_date: Date.current,
        shared: true
      )
    end
  end
end

