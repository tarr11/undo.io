
class HomeController < ApplicationController
   before_filter :authenticate_user! 
  def index
    @tasks = current_user.tasks.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tasks }
    end
 
  
  
  end

end
