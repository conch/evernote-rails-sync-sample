require 'oauth'

class WelcomeController < ApplicationController
  def index
    @connected_to_evernote = session.has_key? :evernote_account_id
    if @connected_to_evernote
      @non_evernote_recipes = Recipe.all
      account = EvernoteAccount.find(session[:evernote_account_id])
      api = EvernoteApi.new account
      @notebooks = api.list_notebooks
      @sync_from_notebook = account.sync_from_notebook
      @sync_from_tags = account.sync_from_tags
    end
  end

  def temp_auth
    request_token = get_consumer.get_request_token(:oauth_callback => request.url.chomp("temp_auth").concat("callback"))
    flash[:request_token] = request_token.token
    flash[:request_secret] = request_token.secret
    redirect_to request_token.authorize_url
  end

  def callback
    oauth_verifier = params[:oauth_verifier]
    if oauth_verifier
      consumer = get_consumer
      request_token = OAuth::RequestToken.new(consumer, flash[:request_token], flash[:request_secret])
      access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
      account = EvernoteAccount.where("user_id = " + access_token.params[:edam_userId]).take
      if !account
        account = EvernoteAccount.create(
          user_id: access_token.params[:edam_userId],
          token: access_token.token,
          shard: access_token.params[:edam_shard],
          token_expiration: access_token.params[:edam_expires]
        )
      end
      session[:evernote_account_id] = account.id
      redirect_to action: "index", controller: "recipes"
    else
      redirect_to action: "index"
    end
  end

  def logout
    account = EvernoteAccount.find(session[:evernote_account_id])
    api = EvernoteApi.new(account)
    api.revoke_token
    session.clear
    account.destroy
    redirect_to action: "index"
  end

  def update_settings
    account = EvernoteAccount.find(session[:evernote_account_id])
    if params['also_sync']
      previous_sync_from_notebook = account.sync_from_notebook
      if params['also_sync'].include?('notebook') && !params['notebook'].nil? && !params['notebook'].strip.empty?
        account.sync_from_notebook = params['notebook']
      else
        account.sync_from_notebook = nil
      end
      if previous_sync_from_notebook != account.sync_from_notebook
        reset_evernote_recipes account
      end
      previous_sync_from_tags = account.sync_from_tags
      tag_names = params['tags'].strip.split(/\s*,\s*/)
      if params['also_sync'].include?('tags') && !tag_names.empty?
        account.sync_from_tags = tag_names
      else
        account.sync_from_tags = []
      end
      if !xor(previous_sync_from_tags, account.sync_from_tags).empty?
        reset_evernote_recipes account
      end
    else
      account.sync_from_notebook = nil
      account.sync_from_tags = []
    end
    account.save
    redirect_to action: "index"
  end

  private
  def get_consumer
    OAuth::Consumer.new(ENV["EVERNOTE_CONSUMER_KEY"], ENV["EVERNOTE_SECRET"], {
      :site => ENV["EVERNOTE_URL"],
      :request_token_path => "/oauth",
      :access_token_path => "/oauth",
      :authorize_path => "/OAuth.action"
    })
  end

  def xor(a,b)
    (a | b) - (a & b)
  end

  def reset_evernote_recipes(account)
    account.update_count = 0
    EvernoteRecipe.where("evernote_account_id = " + account.id.to_s).destroy_all
  end

end
