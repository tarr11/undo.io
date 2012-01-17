class HomeController < ApplicationController
   before_filter :authenticate_user!, :except => :index
   respond_to_mobile_requests :skip_xhr_requests => false

  def settings
    @user = current_user
    respond_to do |format|
      format.html # index.html.erb
      format.mobile
    end
  end

  def index

    if user_signed_in?
     redirect_to :controller=>"task_folder", :action => "folder_view", :path => "/"
    end

  end

end
