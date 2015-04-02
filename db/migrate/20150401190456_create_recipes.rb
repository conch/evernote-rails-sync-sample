class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :title
      t.string :guid
      t.integer :update_sequence_num
      t.integer :largest_resource_size
      t.integer :evernote_account_id, null: false
    end
    add_foreign_key :recipes, :evernote_accounts
    add_index :recipes, :guid
  end
end
