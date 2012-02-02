class HomeController < ApplicationController
   before_filter :authenticate_user!, :except => :index
   respond_to_mobile_requests :skip_xhr_requests => false


  def index

    if user_signed_in?

      #format.html {:render '_home_view'}
      respond_to do |format|
          format.html { render 'task_folder/home_view', :layout => 'application' }
      end
    else
      respond_to do |format|
        format.html # index.html.erb
        format.mobile
      end

    end


  end

end
