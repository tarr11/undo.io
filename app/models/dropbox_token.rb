require 'dropbox_sdk'

class DropboxToken < ConsumerToken

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
end
