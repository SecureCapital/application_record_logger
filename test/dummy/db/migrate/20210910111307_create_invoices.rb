class CreateInvoices < ActiveRecord::Migration[6.1]
  def change
    create_table :invoices do |t|
      t.string :title
      t.text :body
      t.integer :price
      t.text :data
      t.date :date

      t.timestamps
    end
  end
end
