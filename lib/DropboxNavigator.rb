class DropboxNavigator

  def self.SyncAll()
    User.all.each do |user|
      if user.dropbox.nil?
        next
      end
      Sync user
    end

  end


  def self.Sync(user)

    dropboxFiles = getChangedFiles(user)

    dbFiles = user.todo_files.all.map {|a| a}


    begin
        dropboxFiles.each do |fileinfo|

            # get the dropbox files where the revision codes don't match
            file = dbFiles.find{|a| a.filename == fileinfo[:filename]}
            if (!file.nil? && file.dropbox_revision == fileinfo[:revisionCode])
              next
            end

            text = user.dropbox.client.get_file(fileinfo[:filename])
            todo = TodoFile.pushChangesFromText user, fileinfo[:filename], text, fileinfo[:revisionDate], fileinfo[:revisionCode]
        end

    end

    dropboxFileNames = dropboxFiles.map{|a| a[:filename]}

    user.todo_files.all
      .select{|file| !dropboxFileNames
        .include?(file.filename) }
      .each {|file| file.destroy}

  end

  def self.getChangedFiles(user)

    #storedHashes = {}#user.getDropBoxStoredHashes

    getChangedFilesByPath user, user.dropbox.client.metadata("/"), {}

  end

  def self.getChangedFilesByPath(user, directory, storedHashes, filenames = [])


     puts filenames
     directory['contents'].each do |fileinfo|

      if (fileinfo["is_dir"])
        subdir = user.dropbox.client.metadata(fileinfo["path"])
        getChangedFilesByPath(user, subdir, storedHashes, filenames)
      else
        hash = {
              :filename => fileinfo['path'],
              :revisionDate => fileinfo['modified'],
              :revisionCode => fileinfo["rev"]
              }

        if (fileinfo.hash != storedHashes[hash[:filename]])
          filenames.push hash
        end
      end
     end
     return filenames
  end

end