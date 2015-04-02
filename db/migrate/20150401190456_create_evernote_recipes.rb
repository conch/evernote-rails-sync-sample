class CreateEvernoteRecipes < ActiveRecord::Migration
  def change
    create_table :evernote_recipes do |t|
      t.string :title
      t.string :guid
      t.integer :update_sequence_num
      t.integer :largest_resource_size
      t.integer :evernote_account_id, null: false
    end
    add_foreign_key :evernote_recipes, :evernote_accounts
    add_index :evernote_recipes, :guid
  end
end
