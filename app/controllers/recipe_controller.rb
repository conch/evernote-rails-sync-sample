class RecipeController < ApplicationController
  def index
    @recipe = Recipe.find(params[:id])
  end

  def save
    @recipe = Recipe.find(params[:id])
    account = EvernoteAccount.find session[:evernote_account_id]
    api = EvernoteApi.new account
    content = render_to_string "evernote_note_template.xml.erb"
    render plain: api.save_note(@recipe.title, content, account.save_in_notebook, @recipe.author, @recipe.url)
  end
end
