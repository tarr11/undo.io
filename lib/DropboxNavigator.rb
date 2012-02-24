class DropboxNavigator

  def self.SyncAll()
    User.all.each do |user|
      if user.dropbox.nil?
        next
      end
      Sync user
    end

  end

  def self.DeleteFileInDropbox(user, filename)
    user.dropbox.dropbox_client.file_delete filename
  end

  def self.move_file(oldPath, newFile)

    if newFile.user.dropbox.nil?
      return
    end
    newFile.user.dropbox.dropbox_client.file_move oldPath, newFile.filename
  end


  def self.UpdateFileInDropbox(todofile)
    # check if there is an existing file previous the current one

    myuser = todofile.user
    if myuser.dropbox.nil?
      return
    end

    revs = todofile.task_file_revisions.map {|a| a}

    revision = ""
    if revs.length > 1
      revs.sort_by!{|a| a.id}.reverse.second.dropbox_revision
      revision = revs.reverse.second.dropbox_revision ||= ""
    end if

    if revision.empty?
      myuser.dropbox.dropbox_client.put_file todofile.filename, todofile.contents, true
    else
      myuser.dropbox.dropbox_client.put_file todofile.filename, todofile.contents, true, revision
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

            text = user.dropbox.dropbox_client.get_file(fileinfo[:filename])
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

    getChangedFilesByPath user, user.dropbox.dropbox_client.metadata("/"), {}

  end

  def self.getChangedFilesByPath(user, directory, storedHashes, filenames = [])


     puts filenames
     directory['contents'].each do |fileinfo|

      if (fileinfo["is_dir"])
        subdir = user.dropbox.dropbox_client.metadata(fileinfo["path"])
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