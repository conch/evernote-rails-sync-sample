class CreateEvernoteAccounts < ActiveRecord::Migration
  def change
    create_table :evernote_accounts do |t|
      t.integer :user_id
      t.string :token
      t.string :shard
      t.integer :token_expiration, :limit => 8
      t.integer :update_count, default: 0
    end
    add_index :evernote_accounts, :user_id, unique: true
  end
end
