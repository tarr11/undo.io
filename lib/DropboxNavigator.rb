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

    begin
        dropboxFiles.each do |filename|
            text = user.dropbox.client.get_file(filename)
            todo = TodoFile.pushChangesFromText user, filename, text
        end

    end

    user.todo_files.all
      .select{|file| !dropboxFiles.include?(file.filename) }
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
        filename = fileinfo['path']
        if (fileinfo.hash != storedHashes[filename])
          filenames.push filename
        end
      end
     end
     return filenames
  end

end