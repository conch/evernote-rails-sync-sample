class RecipeController < ApplicationController
  def index
    @recipe = Recipe.find(params[:id])
  end

  def save
    @recipe = Recipe.find(params[:id])
    api = EvernoteApi.new EvernoteAccount.find(session[:evernote_account_id])
    content = render_to_string "evernote_note_template.xml.erb"
    render plain: api.save_note(@recipe.title, content, @recipe.author, @recipe.url)
  end
end
