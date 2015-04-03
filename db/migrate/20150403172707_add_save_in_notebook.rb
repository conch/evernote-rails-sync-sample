class AddSaveInNotebook < ActiveRecord::Migration
  def change
    add_column :evernote_accounts, :save_in_notebook, :string
  end
end
