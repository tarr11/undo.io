require 'dropbox_sdk'


class DropboxToken < ConsumerToken


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

  def client
    @client ||= begin 

      @session = DropboxSession.new(DropboxToken.consumer.key, DropboxToken.consumer.secret)
      @session.set_access_token(token, secret)
      DropboxClient.new(@session,ACCESS_TYPE)
    end 
    
   end
end
