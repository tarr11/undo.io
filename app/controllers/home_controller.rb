require 'matrix'
class HomeController < ApplicationController
   before_filter :authenticate_user!, :except => :index
   respond_to_mobile_requests :skip_xhr_requests => false

  def options
    respond_to do |format|
      format.html # index.html.erb
      format.mobile
    end
  end

  def index

    if user_signed_in?
     redirect_to :controller=>"task_folder", :action => "folder_view", :path => "/"
    end
    #
    #topfolders = current_user.task_folder.task_folders
    #
    #@topfolders = current_user.task_folder.task_folders.push(current_user.task_folder)
    #@topfolders.sort_by!{|a| a.path.downcase}
    #
    #@cols = @topfolders.length - 1
    #@rows = 0
    #
    #@matrix = Hash.new
    #@topfolders.each_with_index do |folder, col|
    #  folder.all.each_with_index do |item, row|
    #    if (col == 0)
    #      next
    #    end
    #    @matrix[[col, row]] = item
    #    if row > @rows
    #      @rows = row
    #    end
    #  end
    #end
    #
    ## to get the # of rows, we have to find th
    #
    #
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.json { render json: @files}
    #end
    #
  
  
  end

end
