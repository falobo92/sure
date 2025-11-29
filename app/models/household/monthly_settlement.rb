# frozen_string_literal: true

module Household
  # MonthlySettlement calculates the monthly financial settlement between
  # household members. It implements the following logic:
  #
  # For each member's payment cycle:
  # 1. Sum all incomes for that cycle
  # 2. Subtract all fixed expenses for that cycle
  # 3. Calculate remaining balance
  # 4. Split the balance 50/50
  # 5. Adjust for shared expenses already paid by each member
  # 6. Determine net transfer between members
  #
  class MonthlySettlement
    attr_reader :family, :period_date, :members, :line_items, :shared_expenses

    def initialize(family, period_date:)
      @family = family
      @period_date = period_date.beginning_of_month
      @members = family.household_members.ordered.to_a
      @line_items = family.household_line_items.for_period(@period_date)
      @shared_expenses = family.household_shared_expenses.for_period(@period_date)
    end

    # Returns a comprehensive summary of the monthly settlement
    def summary
      @summary ||= build_summary
    end

    # Total incomes for the month (all cycles)
    def total_incomes
      @total_incomes ||= line_items.incomes.sum(:amount_cents)
    end

    # Total expenses for the month (all cycles, fixed line items only)
    def total_fixed_expenses
      @total_fixed_expenses ||= line_items.expenses.sum(:amount_cents)
    end

    # Total shared expenses (additional expenses tracked separately)
    def total_shared_expenses
      @total_shared_expenses ||= shared_expenses.shared_only.sum(:amount_cents)
    end

    # Total all expenses (fixed + shared)
    def total_all_expenses
      total_fixed_expenses + total_shared_expenses
    end

    # Net household balance (incomes - all expenses)
    def net_balance
      total_incomes - total_all_expenses
    end

    # Incomes grouped by category
    def incomes_by_category
      @incomes_by_category ||= line_items.incomes
        .group(:category)
        .sum(:amount_cents)
        .transform_keys(&:to_s)
    end

    # Expenses grouped by category
    def expenses_by_category
      @expenses_by_category ||= line_items.expenses
        .group(:category)
        .sum(:amount_cents)
        .transform_keys(&:to_s)
    end

    # Line items grouped by payment cycle
    def items_by_cycle
      @items_by_cycle ||= {
        cycle_1: line_items.for_cycle(:cycle_1).ordered_by_category,
        cycle_2: line_items.for_cycle(:cycle_2).ordered_by_category,
        sporadic: line_items.for_cycle(:sporadic).ordered_by_category
      }
    end

    # Calculate settlement for a specific payment cycle
    def cycle_settlement(cycle)
      cycle_items = line_items.for_cycle(cycle)
      cycle_incomes = cycle_items.incomes.sum(:amount_cents)
      cycle_expenses = cycle_items.expenses.sum(:amount_cents)
      balance = cycle_incomes - cycle_expenses
      half_balance = balance / 2.0

      {
        incomes: cycle_incomes,
        expenses: cycle_expenses,
        balance: balance,
        half_balance: half_balance
      }
    end

    # Settlement for member 1 (cycle 1)
    def member_1_settlement
      return nil if members.empty?

      @member_1_settlement ||= calculate_member_settlement(members[0], :cycle_1)
    end

    # Settlement for member 2 (cycle 2)
    def member_2_settlement
      return nil if members.length < 2

      @member_2_settlement ||= calculate_member_settlement(members[1], :cycle_2)
    end

    # Net transfer between members
    # Positive = Member 1 owes Member 2
    # Negative = Member 2 owes Member 1
    def net_transfer
      return 0 if members.length < 2

      transfer_1_to_2 = member_1_settlement[:transfer_to_other]
      transfer_2_to_1 = member_2_settlement[:transfer_to_other]

      transfer_1_to_2 - transfer_2_to_1
    end

    # Free money for each member after all settlements
    def libre_each
      return {} if members.length < 2

      settlement_1 = member_1_settlement
      settlement_2 = member_2_settlement

      # Each member gets half of their cycle's remaining balance
      # Plus/minus their share of shared expenses
      {
        members[0].id => settlement_1[:libre],
        members[1].id => settlement_2[:libre]
      }
    end

    private

    def build_summary
      {
        period: period_date,
        period_name: I18n.l(period_date, format: "%B %Y"),
        members: members.map { |m| { id: m.id, name: m.name, code: m.code } },
        totals: {
          incomes: total_incomes,
          fixed_expenses: total_fixed_expenses,
          shared_expenses: total_shared_expenses,
          all_expenses: total_all_expenses,
          net_balance: net_balance
        },
        by_category: {
          incomes: incomes_by_category,
          expenses: expenses_by_category
        },
        by_cycle: {
          cycle_1: cycle_settlement(:cycle_1),
          cycle_2: cycle_settlement(:cycle_2),
          sporadic: cycle_settlement(:sporadic)
        },
        member_settlements: build_member_settlements,
        transfers: build_transfers,
        libre_each: libre_each
      }
    end

    def build_member_settlements
      return {} if members.empty?

      result = {}
      result[members[0].id] = member_1_settlement if members[0]
      result[members[1].id] = member_2_settlement if members.length >= 2
      result
    end

    def build_transfers
      return {} if members.length < 2

      net = net_transfer

      if net.positive?
        # Member 1 owes Member 2
        {
          from: members[0].id,
          from_name: members[0].name,
          to: members[1].id,
          to_name: members[1].name,
          amount: net.abs
        }
      elsif net.negative?
        # Member 2 owes Member 1
        {
          from: members[1].id,
          from_name: members[1].name,
          to: members[0].id,
          to_name: members[0].name,
          amount: net.abs
        }
      else
        {
          from: nil,
          to: nil,
          amount: 0
        }
      end
    end

    def calculate_member_settlement(member, cycle)
      cycle_data = cycle_settlement(cycle)
      member_shared = member.total_shared_expenses_for_period(period_date)

      # Half of shared expenses this member paid (to be reimbursed by the other)
      shared_reimbursement = member_shared / 2.0

      # Transfer to other member:
      # = half of cycle balance - half of member's shared expenses
      # (because member already paid 100% of shared, other owes them 50%)
      transfer_to_other = cycle_data[:half_balance] - shared_reimbursement

      # Free money for this member after settlement
      libre = cycle_data[:half_balance]

      {
        member_id: member.id,
        member_name: member.name,
        cycle: cycle,
        incomes: cycle_data[:incomes],
        fixed_expenses: cycle_data[:expenses],
        cycle_balance: cycle_data[:balance],
        half_balance: cycle_data[:half_balance],
        shared_expenses_paid: member_shared,
        shared_reimbursement: shared_reimbursement,
        transfer_to_other: transfer_to_other,
        libre: libre
      }
    end
  end
end

