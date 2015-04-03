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

  # linking to evernote starts here. uses oauth gem (oauth v1, not v2)
  def temp_auth
    request_token = get_consumer.get_request_token(:oauth_callback => request.url.chomp("temp_auth").concat("callback"))
    # evernote returns a temp token and secret. save these somewhere for later
    flash[:request_token] = request_token.token
    flash[:request_secret] = request_token.secret
    # evernote also returned a url that app should direct to
    # in order for user to sign in and authorize the app
    redirect_to request_token.authorize_url
  end

  # called after user has signed in and chosen whether or not to authorize the app
  def callback
    # evernote returns a verifier if user authorized the app
    oauth_verifier = params[:oauth_verifier]
    if oauth_verifier
      consumer = get_consumer
      request_token = OAuth::RequestToken.new(consumer, flash[:request_token], flash[:request_secret])
      # contains the real token, user id, shard, and token expiration date
      access_token = request_token.get_access_token(:oauth_verifier => oauth_verifier)
      account = EvernoteAccount.where("user_id = " + access_token.params[:edam_userId]).take
      if !account
        # save this stuff
        account = EvernoteAccount.create(
          user_id: access_token.params[:edam_userId],
          token: access_token.token,
          shard: access_token.params[:edam_shard],
          token_expiration: access_token.params[:edam_expires]
        )
      end
      session[:evernote_account_id] = account.id
      # directs to recipes page (recipe_controller.rb)
      redirect_to action: "index", controller: "recipes"
    else
      redirect_to action: "index"
    end
  end

  # unlinks evernote
  def logout
    account = EvernoteAccount.find(session[:evernote_account_id])
    api = EvernoteApi.new(account)
    api.revoke_token
    session.clear
    account.destroy
    redirect_to action: "index"
  end

  # called by the form on the homepage to update settings
  def update_settings
    account = EvernoteAccount.find(session[:evernote_account_id])
    if params['also_sync']
      # setting that allows user to sync notes from a certain notebook
      # in addition to the notes that are automatically classified
      # as recipes by evernote
      previous_sync_from_notebook = account.sync_from_notebook
      if params['also_sync'].include?('notebook') && !params['notebook'].nil? && !params['notebook'].strip.empty?
        account.sync_from_notebook = params['notebook']
      else
        account.sync_from_notebook = nil
      end
      # if the setting has changed, need to reset our records so that it
      # can do a full sync later
      if previous_sync_from_notebook != account.sync_from_notebook
        reset_evernote_recipes account
      end
      # setting that allows users to sync notes with certain tags
      previous_sync_from_tags = account.sync_from_tags
      tag_names = params['tags'].strip.split(/\s*,\s*/)
      if params['also_sync'].include?('tags') && !tag_names.empty?
        account.sync_from_tags = tag_names
      else
        account.sync_from_tags = []
      end
      # if the setting has changed, need to reset our records so that it
      # can do a full sync later
      if !xor(previous_sync_from_tags, account.sync_from_tags).empty?
        reset_evernote_recipes account
      end
    else
      account.sync_from_notebook = nil
      account.sync_from_tags = []
    end
    # setting that allows user to specify a notebook to save new recipes into
    account.save_in_notebook = params["save_in_notebook"]
    account.save
    redirect_to action: "index"
  end

  private
  # for oauth. need to get consumer key and secret for evernote first
  # assumes they are set as environment variables
  # EVERNOTE_URL is something like https://sandbox.evernote.com
  # or https://www.evernote.com
  def get_consumer
    OAuth::Consumer.new(ENV["EVERNOTE_CONSUMER_KEY"], ENV["EVERNOTE_SECRET"], {
      :site => ENV["EVERNOTE_URL"],
      :request_token_path => "/oauth",
      :access_token_path => "/oauth",
      :authorize_path => "/OAuth.action"
    })
  end

  # takes xor of two arrays to find elements that are in only one of the arrays
  def xor(a,b)
    (a | b) - (a & b)
  end

  # wipes evernote's record of recipe syncing
  def reset_evernote_recipes(account)
    account.update_count = 0
    EvernoteRecipe.where("evernote_account_id = " + account.id.to_s).destroy_all
  end

end
