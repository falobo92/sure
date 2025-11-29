# frozen_string_literal: true

require "test_helper"

module Household
  class SharedExpenseTest < ActiveSupport::TestCase
    setup do
      @family = families(:dylan_family)
      @member = @family.household_members.create!(name: "Test", code: "TT")
    end

    test "creates shared expense with valid attributes" do
      expense = @family.household_shared_expenses.build(
        household_member: @member,
        description: "Supermercado",
        amount_cents: 50_000,
        currency: "CLP",
        expense_date: Date.current
      )

      assert expense.save
      assert_equal Date.current.beginning_of_month, expense.period_date
    end

    test "requires household_member" do
      expense = @family.household_shared_expenses.build(
        description: "Test",
        amount_cents: 100,
        currency: "CLP",
        expense_date: Date.current
      )
      assert_not expense.valid?
      assert_includes expense.errors[:member], "must exist"
    end

    test "requires description" do
      expense = @family.household_shared_expenses.build(
        household_member: @member,
        amount_cents: 100,
        currency: "CLP",
        expense_date: Date.current
      )
      assert_not expense.valid?
      assert_includes expense.errors[:description], "can't be blank"
    end

    test "sets period_date from expense_date" do
      expense = @family.household_shared_expenses.create!(
        household_member: @member,
        description: "Test",
        amount_cents: 100,
        currency: "CLP",
        expense_date: Date.new(2025, 3, 15)
      )

      assert_equal Date.new(2025, 3, 1), expense.period_date
    end

    test "shared_only scope filters by shared flag" do
      shared = @family.household_shared_expenses.create!(
        household_member: @member,
        description: "Shared",
        amount_cents: 100,
        currency: "CLP",
        expense_date: Date.current,
        shared: true
      )

      not_shared = @family.household_shared_expenses.create!(
        household_member: @member,
        description: "Not Shared",
        amount_cents: 50,
        currency: "CLP",
        expense_date: Date.current,
        shared: false
      )

      results = @family.household_shared_expenses.shared_only
      assert_includes results, shared
      assert_not_includes results, not_shared
    end

    test "member_name returns member name" do
      expense = @family.household_shared_expenses.build(household_member: @member)
      assert_equal "Test", expense.member_name
    end
  end
end

