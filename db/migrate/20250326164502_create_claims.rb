class CreateClaims < ActiveRecord::Migration[7.1]
  def change
    create_table :claims do |t|
      t.string :claim_number, null: false
      t.string :client_name, null: false
      t.date :date_filed, null: false
      t.string :status, null: false, default: 'pending'
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0

      t.timestamps
    end

    add_index :claims, :claim_number, unique: true
    add_index :claims, :status
  end
end
