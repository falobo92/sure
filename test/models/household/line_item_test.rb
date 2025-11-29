# frozen_string_literal: true

require "test_helper"

module Household
  class LineItemTest < ActiveSupport::TestCase
    setup do
      @family = families(:dylan_family)
      @period_date = Date.current.beginning_of_month
    end

    test "creates line item with valid attributes" do
      item = @family.household_line_items.build(
        category: "Ingreso",
        description: "Sueldo Test",
        payment_cycle: :cycle_1,
        item_type: :constant,
        kind: :income,
        amount_cents: 1_000_000,
        currency: "CLP",
        period_date: @period_date
      )

      assert item.save
    end

    test "requires category" do
      item = @family.household_line_items.build(
        description: "Test",
        payment_cycle: :cycle_1,
        item_type: :constant,
        kind: :income,
        amount_cents: 100,
        currency: "CLP",
        period_date: @period_date
      )
      assert_not item.valid?
      assert_includes item.errors[:category], "can't be blank"
    end

    test "requires positive amount" do
      item = @family.household_line_items.build(
        category: "Test",
        description: "Test",
        payment_cycle: :cycle_1,
        item_type: :constant,
        kind: :income,
        amount_cents: -100,
        currency: "CLP",
        period_date: @period_date
      )
      assert_not item.valid?
      assert_includes item.errors[:amount_cents], "must be greater than 0"
    end

    test "payment_cycle_label returns correct label" do
      item = @family.household_line_items.build(payment_cycle: :cycle_1)
      assert_equal "N°1", item.payment_cycle_label

      item.payment_cycle = :cycle_2
      assert_equal "N°2", item.payment_cycle_label

      item.payment_cycle = :sporadic
      assert_equal "N°3", item.payment_cycle_label
    end

    test "item_type_label returns correct label" do
      item = @family.household_line_items.build(item_type: :constant)
      assert_equal "CTE", item.item_type_label

      item.item_type = :variable
      assert_equal "VAR", item.item_type_label

      item.item_type = :special
      assert_equal "ESP", item.item_type_label
    end

    test "signed_amount returns positive for income" do
      item = @family.household_line_items.build(kind: :income, amount_cents: 100)
      assert_equal 100, item.signed_amount
    end

    test "signed_amount returns negative for expense" do
      item = @family.household_line_items.build(kind: :expense, amount_cents: 100)
      assert_equal(-100, item.signed_amount)
    end

    test "scopes filter by kind" do
      @family.household_line_items.destroy_all

      income = @family.household_line_items.create!(
        category: "Ingreso", description: "Test Income",
        payment_cycle: :cycle_1, item_type: :constant, kind: :income,
        amount_cents: 100, currency: "CLP", period_date: @period_date
      )

      expense = @family.household_line_items.create!(
        category: "Gasto", description: "Test Expense",
        payment_cycle: :cycle_1, item_type: :constant, kind: :expense,
        amount_cents: 50, currency: "CLP", period_date: @period_date
      )

      assert_includes @family.household_line_items.incomes, income
      assert_not_includes @family.household_line_items.incomes, expense

      assert_includes @family.household_line_items.expenses, expense
      assert_not_includes @family.household_line_items.expenses, income
    end

    test "for_period scope filters by period" do
      @family.household_line_items.destroy_all

      current = @family.household_line_items.create!(
        category: "Test", description: "Current",
        payment_cycle: :cycle_1, item_type: :constant, kind: :income,
        amount_cents: 100, currency: "CLP", period_date: @period_date
      )

      previous = @family.household_line_items.create!(
        category: "Test", description: "Previous",
        payment_cycle: :cycle_1, item_type: :constant, kind: :income,
        amount_cents: 100, currency: "CLP", period_date: @period_date - 1.month
      )

      results = @family.household_line_items.for_period(@period_date)
      assert_includes results, current
      assert_not_includes results, previous
    end
  end
end

