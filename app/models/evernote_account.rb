class EvernoteAccount < ActiveRecord::Base
  has_many :evernote_recipes, :dependent => :destroy
end
