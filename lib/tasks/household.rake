# frozen_string_literal: true

namespace :household do
  desc "Seed example data for Household Finance module"
  task seed: :environment do
    puts "Seeding Household Finance example data..."

    # Find or create a family
    family = Family.first
    unless family
      puts "No family found. Please create a family first."
      exit 1
    end

    puts "Using family: #{family.name}"

    # Create members if they don't exist
    felipe = family.household_members.find_or_create_by!(code: "FL") do |m|
      m.name = "Felipe"
      m.position = 1
    end
    puts "  Member: #{felipe.display_name}"

    romina = family.household_members.find_or_create_by!(code: "RP") do |m|
      m.name = "Romina"
      m.position = 2
    end
    puts "  Member: #{romina.display_name}"

    # Current month
    period = Date.current.beginning_of_month
    currency = family.currency.presence || "CLP"

    puts "\nCreating line items for #{I18n.l(period, format: '%B %Y')}..."

    # Clear existing items for this period (optional, for demo purposes)
    family.household_line_items.where(period_date: period).destroy_all
    family.household_shared_expenses.where(period_date: period).destroy_all

    # ==========================================
    # CYCLE 1 - Felipe's payment cycle
    # ==========================================

    # Incomes
    items_cycle_1_incomes = [
      { category: "Ingreso", description: "Sueldo Felipe", amount: 3_500_000, type: :constant },
      { category: "Ingreso", description: "Arriendo 409", amount: 450_000, type: :constant }
    ]

    items_cycle_1_incomes.each do |item|
      family.household_line_items.create!(
        household_member: felipe,
        category: item[:category],
        description: item[:description],
        payment_cycle: :cycle_1,
        item_type: item[:type],
        kind: :income,
        amount_cents: item[:amount],
        currency: currency,
        period_date: period
      )
      puts "    + #{item[:description]}: #{item[:amount]}"
    end

    # Expenses
    items_cycle_1_expenses = [
      { category: "Vivienda", description: "Dividendo 409", amount: 890_000, type: :constant },
      { category: "Vivienda", description: "GGCC 409", amount: 85_000, type: :variable },
      { category: "Vivienda", description: "Luz", amount: 45_000, type: :variable },
      { category: "Vivienda", description: "Agua", amount: 25_000, type: :variable },
      { category: "Crédito de consumo", description: "Crédito BCH Felipe", amount: 280_000, type: :constant },
      { category: "Crédito de consumo", description: "Crédito CLA Felipe", amount: 150_000, type: :constant },
      { category: "Telefonía e internet", description: "Celular Felipe", amount: 25_000, type: :constant },
      { category: "Telefonía e internet", description: "Internet", amount: 35_000, type: :constant },
      { category: "Cuidado niños", description: "Señora Tere", amount: 350_000, type: :constant }
    ]

    items_cycle_1_expenses.each do |item|
      family.household_line_items.create!(
        household_member: felipe,
        category: item[:category],
        description: item[:description],
        payment_cycle: :cycle_1,
        item_type: item[:type],
        kind: :expense,
        amount_cents: item[:amount],
        currency: currency,
        period_date: period
      )
      puts "    - #{item[:description]}: #{item[:amount]}"
    end

    # ==========================================
    # CYCLE 2 - Romina's payment cycle
    # ==========================================

    # Incomes
    items_cycle_2_incomes = [
      { category: "Ingreso", description: "Sueldo Romina", amount: 2_800_000, type: :constant },
      { category: "Ingreso", description: "Pensión alimenticia", amount: 200_000, type: :constant }
    ]

    items_cycle_2_incomes.each do |item|
      family.household_line_items.create!(
        household_member: romina,
        category: item[:category],
        description: item[:description],
        payment_cycle: :cycle_2,
        item_type: item[:type],
        kind: :income,
        amount_cents: item[:amount],
        currency: currency,
        period_date: period
      )
      puts "    + #{item[:description]}: #{item[:amount]}"
    end

    # Expenses
    items_cycle_2_expenses = [
      { category: "Vivienda", description: "Arriendo 306", amount: 650_000, type: :constant },
      { category: "Vivienda", description: "GGCC 306", amount: 45_000, type: :variable },
      { category: "Crédito de consumo", description: "Crédito Scotiabank Romina", amount: 180_000, type: :constant },
      { category: "Telefonía e internet", description: "Celular Romina", amount: 22_000, type: :constant },
      { category: "Cuidado niños", description: "Furgón", amount: 120_000, type: :constant },
      { category: "Cuidado niños", description: "Mesada", amount: 50_000, type: :constant }
    ]

    items_cycle_2_expenses.each do |item|
      family.household_line_items.create!(
        household_member: romina,
        category: item[:category],
        description: item[:description],
        payment_cycle: :cycle_2,
        item_type: item[:type],
        kind: :expense,
        amount_cents: item[:amount],
        currency: currency,
        period_date: period
      )
      puts "    - #{item[:description]}: #{item[:amount]}"
    end

    # ==========================================
    # CYCLE 3 - Sporadic items
    # ==========================================

    items_sporadic = [
      { category: "Vivienda", description: "Contribuciones", amount: 95_000, kind: :expense, type: :special },
      { category: "Automóvil", description: "TAG", amount: 30_000, kind: :expense, type: :variable }
    ]

    items_sporadic.each do |item|
      family.household_line_items.create!(
        category: item[:category],
        description: item[:description],
        payment_cycle: :sporadic,
        item_type: item[:type],
        kind: item[:kind],
        amount_cents: item[:amount],
        currency: currency,
        period_date: period
      )
      puts "    #{item[:kind] == :income ? '+' : '-'} #{item[:description]}: #{item[:amount]} (N°3)"
    end

    # ==========================================
    # Shared Expenses
    # ==========================================

    puts "\nCreating shared expenses..."

    shared_expenses = [
      { member: felipe, description: "Supermercado Jumbo", amount: 185_000, date: period + 5.days },
      { member: felipe, description: "Gasolina", amount: 65_000, date: period + 8.days },
      { member: felipe, description: "Farmacia", amount: 35_000, date: period + 12.days },
      { member: romina, description: "Supermercado Líder", amount: 145_000, date: period + 10.days },
      { member: romina, description: "Veterinario", amount: 45_000, date: period + 15.days }
    ]

    shared_expenses.each do |exp|
      family.household_shared_expenses.create!(
        household_member: exp[:member],
        description: exp[:description],
        amount_cents: exp[:amount],
        currency: currency,
        expense_date: exp[:date],
        shared: true
      )
      puts "    #{exp[:member].code}: #{exp[:description]} - #{exp[:amount]}"
    end

    # ==========================================
    # Summary
    # ==========================================

    puts "\n" + "=" * 50
    puts "SUMMARY"
    puts "=" * 50

    settlement = Household::MonthlySettlement.new(family, period_date: period)
    summary = settlement.summary

    puts "\nTotal Incomes: #{summary[:totals][:incomes]}"
    puts "Total Fixed Expenses: #{summary[:totals][:fixed_expenses]}"
    puts "Total Shared Expenses: #{summary[:totals][:shared_expenses]}"
    puts "Net Balance: #{summary[:totals][:net_balance]}"

    if summary[:transfers][:amount].to_i > 0
      puts "\nTransfer: #{summary[:transfers][:from_name]} → #{summary[:transfers][:to_name]}: #{summary[:transfers][:amount]}"
    else
      puts "\nNo transfer needed - balanced!"
    end

    puts "\nLibre c/u:"
    settlement.libre_each.each do |member_id, amount|
      member = family.household_members.find(member_id)
      puts "  #{member.name}: #{amount}"
    end

    puts "\n✅ Household Finance data seeded successfully!"
    puts "Navigate to /household to view the dashboard."
  end

  desc "Clear all Household Finance data for the current family"
  task clear: :environment do
    family = Family.first
    unless family
      puts "No family found."
      exit 1
    end

    puts "Clearing Household Finance data for #{family.name}..."

    count_members = family.household_members.count
    count_items = family.household_line_items.count
    count_shared = family.household_shared_expenses.count

    family.household_members.destroy_all
    family.household_line_items.destroy_all
    family.household_shared_expenses.destroy_all

    puts "Deleted:"
    puts "  - #{count_members} members"
    puts "  - #{count_items} line items"
    puts "  - #{count_shared} shared expenses"
    puts "✅ Done!"
  end
end

