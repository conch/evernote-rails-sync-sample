require 'evernote-thrift'
require 'net/http'
require 'nokogiri'

class EvernoteApi
  def initialize(account)
    @account = account
    @note_store_url = ENV["EVERNOTE_URL"] + "/shard/" + @account.shard + "/notestore"
    @user_store_url = ENV["EVERNOTE_URL"] + "/edam/user/" + @account.shard
  end

  # syncs recipes from evernote
  def get_recipes
    noteStoreTransport = Thrift::HTTPClientTransport.new(@note_store_url)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    # first check if evernote account has had any changes since the last time
    # you synced recipes. only download recipes if there were changes. this is
    # to keep server calls to a minimum
    syncState = noteStore.getSyncState(@account.token)
    # the sync state contains a field updateCount which is a 32-bit unsigned integer.
    # it is equal to the number of updates there have been to the account. updates
    # includes everything from creating notes, updating notes, deleting notes to
    # upgrading to premium or changing their email.
    # you should be saving the updateCount everytime you call this.
    # check against your saved value to determine if the account has changed since
    # the last time you made this call
    if @account.update_count < syncState.updateCount
      # account changed, so must sync recipes
      # this filter is how you specify that you just want recipes instead of all notes, as well
      # as how to sort and order them.
      # there are more options, but I'm just using a few here.
      # I am sorting the notes by their Update Sequence Number (USN) which is also
      # an unsigned 32-bit integer that is the number of the account update that last touched that note.
      # that means that a note that has a higher USN was updated more recently
      # than a note with a lower USN. updateCount is the maximum for USN.
      # I want my results to be listed in the order that they were updated.
      # the first spot is most recently updated while the last slot is least recently updated.
      # this choice is crucial to syncing efficiently, as described in
      # the comments of the function request_recipes_chunk
      noteFilter = Evernote::EDAM::NoteStore::NoteFilter.new(
        :ascending => false,
        :order => Evernote::EDAM::Type::NoteSortOrder::UPDATE_SEQUENCE_NUMBER,
        :words => "any: classifications_recipe:" + Evernote::EDAM::Type::CLASSIFICATION_RECIPE_SERVICE_RECIPE + " classifications_recipe:" + Evernote::EDAM::Type::CLASSIFICATION_RECIPE_USER_RECIPE
      )
      # if user has specified that they want to also sync notes with specific tags
      # then add those to the filter
      if @account.sync_from_tags
        @account.sync_from_tags.each do |tag|
          noteFilter.words += " tag:\"" + tag + "\""
        end
      end
      # if user has specified that they want to also sync notes from a specific notebook
      # then we need to make a separate call to get those. unfortunately, it is not
      # possible to get the union of auto-classified recipes plus notes with a certain
      # tag plus notes in a certain notebook in one call.
      if @account.sync_from_notebook
        noteFilter_notebook = Evernote::EDAM::NoteStore::NoteFilter.new(
          :ascending => false,
          :order => Evernote::EDAM::Type::NoteSortOrder::UPDATE_SEQUENCE_NUMBER,
          :notebookGuid => @account.sync_from_notebook
        )
      end
      # this specifies what note properties to include in the result set
      # everything is false by default in order to minimize bandwidth
      # a note's largestResourceSize is the number of bytes of its largest image
      # it is useful to determine whether you should request a thumbnail later.
      # if it is 0, that means the note has no images, so if you request a thumbnail
      # anyway, the thumbnail would just be a picture of the note text, which may
      # not be desirable
      # we also want the note's USN
      resultSpec = Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
        :includeTitle => true,
        :includeLargestResourceSize => true,
        :includeUpdateSequenceNum => true
      )
      # the api call requires pagination, so we set the page size to 100 notes
      # that means we must recursively call it until we get all the recipes
      request_recipes_chunk(0, 100, noteStore, noteFilter, resultSpec)
      if @account.sync_from_notebook
        request_recipes_chunk(0, 100, noteStore, noteFilter_notebook, resultSpec)
      end
      # finally, update your records with the user's latest updateCount
      @account.update(update_count: syncState.updateCount)
    end

    # after making sure your database is up-to-date, show them to user
    EvernoteRecipe.where("evernote_account_id = " + @account.id.to_s).order(title: :asc)
  end

  # gets list of personal notebooks to show to user on homepage.
  # this does not include notebooks others shared to the user and business notebooks.
  # only notebooks that the user owns.
  def list_notebooks
    noteStoreTransport = Thrift::HTTPClientTransport.new(@note_store_url)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)
    noteStore.listNotebooks(@account.token)
  end

  # when you unlink from evernote, you have to tell evernote that you want
  # to unlink by revoking the auth token
  def revoke_token
    userStoreTransport = Thrift::HTTPClientTransport.new(@user_store_url)
    userStoreProtocol = Thrift::BinaryProtocol.new(userStoreTransport)
    userStore = Evernote::EDAM::UserStore::UserStore::Client.new(userStoreProtocol)
    begin
      userStore.revokeLongSession(@account.token)
    rescue
    end
  end

  # saves nyt recipe to evernote. title and content are required, but
  # the others are optional. if you don't specify a notebook guid,
  # server saves it to the default notebook
  # content is a ENML string
  def save_note(title, content, notebookGuid, author, url)
    noteStoreTransport = Thrift::HTTPClientTransport.new(@note_store_url)
    noteStoreProtocol = Thrift::BinaryProtocol.new(noteStoreTransport)
    noteStore = Evernote::EDAM::NoteStore::NoteStore::Client.new(noteStoreProtocol)

    # go through content and convert img tags to evernote Resources so that image
    # data is stored in Evernote forever instead of a link to the image
    resources = []
    doc = Nokogiri::XML(content)
    doc.css("img").each do |img_tag|
      if img_tag["src"]
        # download image bytes
        response = Net::HTTP.get_response(URI.parse(img_tag["src"]))
        # take an MD5 hash of bytes
        md5 = Digest::MD5.hexdigest(response.body)
        mime = response.content_type
        # adds as a resource. data and mime are required
        resources.push Evernote::EDAM::Type::Resource.new(
          :data => Evernote::EDAM::Type::Data.new(:body => response.body),
          :mime => mime,
          :attributes => Evernote::EDAM::Type::ResourceAttributes.new(
            :sourceURL => img_tag["src"]
          )
        )
        # also need to modify the ENML to reference this resource.
        # change img tag to en-media tag. remove src attribute because
        # it is not an allowed attribute for en-media tags
        # add hash attribute that points to the md5 hash so evernote clients
        # know where to look up the resource when they have to render this note
        # type is a required attribute. points to mime
        img_tag.attributes["src"].remove
        img_tag.name = "en-media"
        img_tag["hash"] = md5
        img_tag["type"] = mime
      end
    end
    # the api call.
    # you can set the source attribute to whatever you want if you would
    # like to mark the note as something coming from NYT Cooking
    note = Evernote::EDAM::Type::Note.new(
      :title => title,
      :content => doc.to_xml,
      :notebookGuid => notebookGuid,
      :resources => resources,
      :attributes => Evernote::EDAM::Type::NoteAttributes.new(
        :author => author,
        :source => "nyt.cooking",
        :sourceURL => url
      )
    )
    begin
      created_note = noteStore.createNote(@account.token, note)
      # evernote returns the note that was created with only a few fields
      # filled out. includes the guid and title among other things
      # use guid to create a link to view the note
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
  # called recursively by get_recipes
  def request_recipes_chunk(start_index, max_notes, noteStore, filter, spec)
    # the api call
    notesMetadataList = noteStore.findNotesMetadata(@account.token, filter, start_index, max_notes, spec)
    # once you have your first set of results, go through them to see if the latest
    # account updates actually affected the notes that you're interested. since
    # updates can touch any part of the account, not just the recipes, we can't be
    # sure that the recipes changed until we get a list of them and look at their USNs.
    # we sorted the results by USN to make this quick.
    notesMetadataList.notes.each do |n|
      # check if each note is greater than your previous updateCount
      # if it is, that means this recipe that you're interested did indeed change
      # and you would need to save the modifications to your database.
      # if it is not, then the note did not change.
      # we can stop iterating through the notes and don't
      # need to request more pages of results because we sorted the list so that
      # the highest USNs are on the top. if the highest USNs are lower than or equal to
      # the previous updateCount, then all subsequent recipes can't have changed.
      # that means your database of recipes is up-to-date
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
        # stopping because our database is up-to-date
        return
      end
    end
    # if we're at this point that means everything we've seen so far has been new
    # and we want more recipes
    # check if there are more by comparing this page's start index and size with
    # the total count
    if notesMetadataList.startIndex + notesMetadataList.notes.length < notesMetadataList.totalNotes
      request_recipes_chunk(start_index + max_notes, max_notes, noteStore, filter, spec)
    end
  end

  def generate_note_link(note_guid)
    ENV['EVERNOTE_URL'] + "/shard/" + @account.shard + "/nl/" + @account.user_id.to_s + "/" + note_guid
  end
end
