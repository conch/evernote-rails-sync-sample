require "net/http"

class RecipesController < ApplicationController
  def index
    @account = EvernoteAccount.find(session[:evernote_account_id])
    api = EvernoteApi.new(@account)
    @noteMetadatas = api.get_recipes
  end

  def thumbnail
    account = EvernoteAccount.find(session[:evernote_account_id])
    uri_string = ENV["EVERNOTE_URL"] + "/shard/" + account.shard + "/thm/note/" + params[:note_guid]
    if params[:size]
      uri_string += "?size=" + params[:size]
    end
    response = Net::HTTP.post_form(URI.parse(uri_string), "auth" => account.token)
    render :text => response.body, :status => 200, :content_type => response.content_type
  end
end
