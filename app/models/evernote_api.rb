require 'evernote-thrift'

class EvernoteApi
  def initialize(account)
    @account = account
    @note_store_url = ENV["EVERNOTE_URL"] + "/shard/" + @account.shard + "/notestore"
    @user_store_url = ENV["EVERNOTE_URL"] + "/edam/user/" + @account.shard
  end

  def get_recipes
    noteStoreTransport = Thrift::HTTPClientTransport.new(@note_store_url)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    syncState = noteStore.getSyncState(@account.token)
    if @account.update_count < syncState.updateCount
      noteFilter = Evernote::EDAM::NoteStore::NoteFilter.new(
        :ascending => false,
        :order => Evernote::EDAM::Type::NoteSortOrder::UPDATE_SEQUENCE_NUMBER,
        :words => "any: classifications_recipe:" + Evernote::EDAM::Type::CLASSIFICATION_RECIPE_SERVICE_RECIPE + " classifications_recipe:" + Evernote::EDAM::Type::CLASSIFICATION_RECIPE_USER_RECIPE
      )
      resultSpec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
        :includeTitle => true,
        :includeLargestResourceSize => true,
        :includeUpdateSequenceNum => true
      )
      request_recipes_chunk(0, 100, noteStore, noteFilter, resultSpec)
      @account.update(update_count: syncState.updateCount)
    end

    Recipe.where("evernote_account_id = " + @account.id.to_s).order(title: :asc)
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

  private
  def request_recipes_chunk(start_index, max_notes, noteStore, filter, spec)
    notesMetadataList = noteStore.findNotesMetadata(@account.token, filter, start_index, max_notes, spec)
    notesMetadataList.notes.each do |n|
      if n.updateSequenceNum > @account.update_count
        recipe = Recipe.where(evernote_account_id: @account.id, guid: n.guid).take
        if recipe
          if n.title != recipe.title
            recipe.title = n.title
          end
          if n.updateSequenceNum != recipe.update_sequence_num
            recipe.update_sequence_num = n.updateSequenceNum
          end
          if n.largestResourceSize != recipe.largest_resource_size
            recipe.largest_resource_size = n.largestResourceSize
          end
          recipe.save
        else
          Recipe.create(
            evernote_account_id: @account.id,
            title: n.title,
            guid: n.guid,
            update_sequence_num: n.updateSequenceNum,
            largest_resource_size: n.largestResourceSize
          )
        end
      else
        return
      end
    end
    if notesMetadataList.startIndex + notesMetadataList.notes.length < notesMetadataList.totalNotes
      request_recipes_chunk(start_index + max_notes, max_notes, noteStore, filter, spec)
    end
  end
end
