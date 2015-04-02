class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :title
      t.string :author
      t.string :prep_time
      t.string :intro
      t.string :ingredients, array: true
      t.string :instructions, array: true
      t.string :pic_url
      t.string :pic_credit
      t.string :url
    end
  end
end
