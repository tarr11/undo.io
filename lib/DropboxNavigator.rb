class DropboxNavigator

  def self.Sync

      User.all.each do |user|
      if user.dropbox.nil?
        next
      end
      puts user.email

      getChangedFiles(user) do |filename|
        text = user.dropbox.client.get_file(filename)
        todo = TodoFile.pushChangesFromText user, filename, text

      end

    end
  end

  def self.getChangedFiles(user)

    storedHashes = {}#user.getDropBoxStoredHashes
    fileinfo = user.dropbox.client.metadata("/")
    getChangedFilesByPath(user, fileinfo, storedHashes) do |filename|
      yield filename
    end


  end

  def self.getChangedFilesByPath(user, directory, storedHashes)

    directory['contents'].each do |fileinfo|

      if (fileinfo["is_dir"])
        subdir = user.dropbox.client.metadata(fileinfo["path"])
        getChangedFilesByPath(user, subdir, storedHashes) do |filename|
          yield filename
        end
      else
        filename = fileinfo['path']
        if (fileinfo.hash != storedHashes[filename])
          yield filename
        end
      end


    end

  end


end