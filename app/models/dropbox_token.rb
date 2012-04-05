# encoding: utf-8
require 'dropbox_sdk'

class DropboxToken < ConsumerToken
# Dropbox
ACCESS_TYPE = :app_folder

DROPBOX_SETTINGS= {
  :site => "https://www.dropbox.com",
  :request_token_path => "/1/oauth/request_token",
  :access_token_path  => "/1/oauth/access_token",
  :authorize_path     => "/1/oauth/authorize"
}


  def self.consumer(options={})
        @consumer ||= OAuth::Consumer.new(credentials[:key], credentials[:secret], DROPBOX_SETTINGS.merge(options))
  end

  def dropbox_client
    @client ||= begin 
      @session = DropboxSession.new(DropboxToken.consumer.key, DropboxToken.consumer.secret)
      @session.set_access_token(token, secret)
      DropboxClient.new(@session,ACCESS_TYPE)
    end 
    
  end

  def get_delta
    dropbox_client.delta(user.dropbox_state.cursor)
  end

  def get_file_from_dropbox(filename)
    text = dropbox_client.get_file(filename)
  end

  def sync_delta_entry(delta_entry)
    filename = delta_entry.first
    metadata = delta_entry.second
    Rails.logger.debug "Dropbox: entry " + filename 
    path_entry = nil
    # file might not exist
    path_entry = user.file(filename)
    is_folder = false
    if path_entry.nil?
      path_entry  = user.task_folder(filename) 
      if path_entry.is_a_folder
        is_folder = true
      else
        path_entry = nil
      end
    end

    if metadata.nil?
      # delete this file
      unless path_entry.nil?  
        path_entry.destroy
        Rails.logger.debug "Dropbox: Deleted /" + user.username +  filename
      else
        Rails.logger.debug "Dropbox: Skipped deleting directory" + user.username + "/" +  filename
      end
    else
      # add or update this file
      # we ignore new directories for adds
      unless metadata["is_dir"]
        text = get_file_from_dropbox(filename)
        text = TodoFile.encodeUtf8(text)
        if path_entry.nil?
          file = user.todo_files.new
          file.filename = filename
          file.contents = text 
          file.is_public = false
          Rails.logger.debug "Dropbox: Created file:" + user.username + "/" +  filename
        else
          if !is_folder 
            file = path_entry
            file.contents = text
            Rails.logger.debug "Dropbox: Updated file:" + user.username + "/" +  filename
          end
        end
        if !is_folder
          file.revision_at = metadata["modified"] 
          file.edit_source = 'dropbox'
          file.save!
        end
      end
    end
  end

  def sync_delta
    while true do
      delta = get_delta 
      delta["entries"].each do |delta_entry|
        sync_delta_entry delta_entry     
      end 
   
      save_cursor delta["cursor"]
      break unless delta["has_more"] 
    end
  end

  def save_cursor(cursor)
    user.dropbox_state.cursor = cursor
    user.dropbox_state.save!
  end
end
