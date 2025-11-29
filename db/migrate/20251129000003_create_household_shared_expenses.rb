class CreateHouseholdSharedExpenses < ActiveRecord::Migration[7.2]
  def change
    create_table :household_shared_expenses, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :household_member, null: false, foreign_key: true, type: :uuid, index: true
      t.string :description, null: false
      t.decimal :amount_cents, precision: 19, scale: 4, null: false
      t.string :currency, null: false, default: "CLP"
      t.date :expense_date, null: false
      t.date :period_date, null: false # First day of the month for grouping
      t.boolean :shared, null: false, default: true

      t.timestamps
    end

    add_index :household_shared_expenses, [:family_id, :period_date]
    add_index :household_shared_expenses, [:family_id, :household_member_id, :period_date], 
              name: "idx_household_shared_expenses_member_period"
  end
end

