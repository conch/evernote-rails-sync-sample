require 'evernote-thrift'

class EvernoteApi
  def initialize(account)
    @account = account
    @note_store_url = ENV["EVERNOTE_URL"] + "/shard/" + @account.shard + "/notestore"
    @user_store_url = ENV["EVERNOTE_URL"] + "/edam/user/" + @account.shard
  end

  def revoke_token
    userStoreTransport = Thrift::HTTPClientTransport.new(@user_store_url)
    userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
    userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
    begin
      stuff = userStore.revokeLongSession(@account.token)
    rescue
    end
  end
end
