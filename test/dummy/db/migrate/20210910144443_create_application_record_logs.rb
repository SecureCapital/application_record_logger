class CreateApplicationRecordLogs < ActiveRecord::Migration[6.1]
  def change
    create_table :application_record_logs do |t|
      t.string     :owner_type, null: false
      t.integer    :owner_id,   null: false
      t.references :user,       foreign_key: true, index: true
      t.integer    :action,     null: false
      t.text       :data
      t.string     :message,    limit: 1225
      t.timestamps
      t.index :owner_type
      t.index :owner_id
    end
  end
end
