class CreateApplicationRecordLogs < ActiveRecord::Migration[6.1]
  def up
    create_table :application_record_logs do |t|
      t.string     :record_type, null: false
      t.integer    :record_id,   null: false
      t.references :user,       foreign_key: true, index: true
      t.integer    :action,     null: false
      t.text       :data
      # t.string     :message,    limit: 1225
      t.timestamps
      t.index :record_type
      t.index :record_id
    end
  end

  def down
    drop_table :application_record_logs
  end
end
