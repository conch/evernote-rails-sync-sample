require 'oauth'

class WelcomeController < ApplicationController
  def index
    @connected_to_evernote = session.has_key? :evernote_account_id
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

  private
  def get_consumer
    OAuth::Consumer.new(ENV["EVERNOTE_CONSUMER_KEY"], ENV["EVERNOTE_SECRET"], {
      :site => ENV["EVERNOTE_URL"],
      :request_token_path => "/oauth",
      :access_token_path => "/oauth",
      :authorize_path => "/OAuth.action"
    })
  end

end
