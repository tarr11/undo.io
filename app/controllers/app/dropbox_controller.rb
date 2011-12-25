class App::DropboxController < ApplicationController

  require 'dropbox_sdk'
  before_filter :authenticate_user! 
 
  ACCESS_TYPE = :app_folder

  def index

   #@info = current_user.dropbox.client
   # token = current_user.dropbox.client.consumer.key
   #secret = current_user.dropbox.client.consumer.secret

    #@session = DropboxSession.new(token, secret)

    #@session.set_access_token(current_user.dropbox.client.token, current_user.dropbox.client.secret)

    #@client = DropboxClient.new(@session,ACCESS_TYPE)

  info = current_user.dropbox.client.metadata "/"
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: info }
    end
  end


end
