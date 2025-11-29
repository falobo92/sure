class CreateHouseholdLineItems < ActiveRecord::Migration[7.2]
  def change
    create_table :household_line_items, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :household_member, foreign_key: true, type: :uuid, index: true
      t.string :category, null: false
      t.string :description, null: false
      t.integer :payment_cycle, null: false, default: 1 # 1, 2, or 3
      t.string :item_type, null: false, default: "constant" # constant, variable, special
      t.string :kind, null: false # income, expense
      t.decimal :amount_cents, precision: 19, scale: 4, null: false
      t.string :currency, null: false, default: "CLP"
      t.date :period_date, null: false # First day of the month (e.g., 2025-03-01)
      t.text :notes

      t.timestamps
    end

    add_index :household_line_items, [:family_id, :period_date]
    add_index :household_line_items, [:family_id, :kind]
    add_index :household_line_items, [:family_id, :payment_cycle]
    add_index :household_line_items, [:family_id, :category]
  end
end

