class AddSyncFromOptions < ActiveRecord::Migration
  def change
    add_column :evernote_accounts, :sync_from_notebook, :string
    add_column :evernote_accounts, :sync_from_tags, :string, array: true, default: []
  end
end
