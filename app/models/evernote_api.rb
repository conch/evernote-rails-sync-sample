require 'evernote-thrift'
require 'net/http'
require 'nokogiri'

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
      if @account.sync_from_tags
        @account.sync_from_tags.each do |tag|
          noteFilter.words += " tag:\"" + tag + "\""
        end
      end
      if @account.sync_from_notebook
        noteFilter_notebook = Evernote::EDAM::NoteStore::NoteFilter.new(
          :ascending => false,
          :order => Evernote::EDAM::Type::NoteSortOrder::UPDATE_SEQUENCE_NUMBER,
          :notebookGuid => @account.sync_from_notebook
        )
      end
      resultSpec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
        :includeTitle => true,
        :includeLargestResourceSize => true,
        :includeUpdateSequenceNum => true
      )
      request_recipes_chunk(0, 100, noteStore, noteFilter, resultSpec)
      if @account.sync_from_notebook
        request_recipes_chunk(0, 100, noteStore, noteFilter_notebook, resultSpec)
      end
      @account.update(update_count: syncState.updateCount)
    end

    EvernoteRecipe.where("evernote_account_id = " + @account.id.to_s).order(title: :asc)
  end

  def list_notebooks
    noteStoreTransport = Thrift::HTTPClientTransport.new(@note_store_url)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    noteStore.listNotebooks(@account.token)
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

  def save_note(title, content, author, url)
    noteStoreTransport = Thrift::HTTPClientTransport.new(@note_store_url)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

    resources = []
    doc = Nokogiri::XML(content)
    doc.css("img").each do |img_tag|
      if img_tag["src"]
        response = Net::HTTP.get_response(URI.parse(img_tag["src"]))
        md5 = Digest::MD5.hexdigest(response.body)
        mime = response.content_type
        resources.push Evernote::EDAM::Type::Resource.new(
          :data => Evernote::EDAM::Type::Data.new(:body => response.body),
          :mime => mime,
          :attributes => Evernote::EDAM::Type::ResourceAttributes.new(
            :sourceURL => img_tag["src"]
          )
        )
        img_tag.attributes["src"].remove
        img_tag.name = "en-media"
        img_tag["hash"] = md5
        img_tag["type"] = mime
      end
    end
    note = Evernote::EDAM::Type::Note.new(
      :title => title,
      :content => doc.to_xml,
      :resources => resources,
      :attributes => Evernote::EDAM::Type::NoteAttributes.new(
        :author => author,
        :source => "nyt.cooking",
        :sourceURL => url
      )
    )
    begin
      created_note = noteStore.createNote(@account.token, note)
      generate_note_link(created_note.guid)
    rescue Evernote::EDAM::Error::EDAMUserException => e
      puts "could not create note: " + e.parameter + " (error code " + e.errorCode.to_s + ")"
      throw e
    rescue Evernote::EDAM::Error::EDAMNotFoundException => e
      puts "could not find Evernote notebook: " + note.notebookGuid
      throw e
    end
  end

  private
  def request_recipes_chunk(start_index, max_notes, noteStore, filter, spec)
    notesMetadataList = noteStore.findNotesMetadata(@account.token, filter, start_index, max_notes, spec)
    notesMetadataList.notes.each do |n|
      if n.updateSequenceNum > @account.update_count
        recipe = EvernoteRecipe.where(evernote_account_id: @account.id, guid: n.guid).take
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
          EvernoteRecipe.create(
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

  def generate_note_link(note_guid)
    ENV['EVERNOTE_URL'] + "/shard/" + @account.shard + "/nl/" + @account.user_id.to_s + "/" + note_guid
  end
end
