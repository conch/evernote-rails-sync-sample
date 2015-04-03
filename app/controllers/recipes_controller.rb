require "net/http"

class RecipesController < ApplicationController
  def index
    @account = EvernoteAccount.find(session[:evernote_account_id])
    api = EvernoteApi.new(@account)
    @noteMetadatas = api.get_recipes
  end

  # get thumbnail for evernote notes
  # evernote thumbnail url format is
  # <evernote url>/shard/<shard>/thm/note/<note guid>
  # you can specify an optional parameter at the end to say what size
  # you want with "?size=<size>"
  # they are usually squares, so the size param is both width and height
  # but if the thumbnail is smaller than the designated square, then
  # server will just return the largest possible image unaltered, so it
  # could be non-square
  # also required to POST to this url in order to pass in authentication
  # for authentication, you must pass in the POST param "auth" with your auth token
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
