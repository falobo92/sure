class CreateHouseholdMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :household_members, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :code, null: false, limit: 10
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :household_members, [:family_id, :code], unique: true
    add_index :household_members, [:family_id, :position]
  end
end

