# page to display individual non-evernote recipes
class RecipeController < ApplicationController
  def index
    @recipe = Recipe.find(params[:id])
  end

  # saves non-evernote recipe into evernote account
  # takes the xml template which has a sample ENML note
  # and fills in the details
  # ENML is what must be sent to the server as the note's content
  def save
    @recipe = Recipe.find(params[:id])
    account = EvernoteAccount.find session[:evernote_account_id]
    api = EvernoteApi.new account
    content = render_to_string "evernote_note_template.xml.erb"
    render plain: api.save_note(@recipe.title, content, account.save_in_notebook, @recipe.author, @recipe.url)
  end
end
