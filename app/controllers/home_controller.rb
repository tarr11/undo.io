
class HomeController < ApplicationController
   before_filter :authenticate_user! 
  def index
    allFiles = current_user.todo_files.includes(:todo_lines)

=begin
    rows = files.map do |file|
      file.todo_lines.map do |line|
        {
          :todofile => file ,
          :task => line.line
        }
      end
    end
=end

    @files = allFiles.select do |file|
      file.todo_lines.length > 0
    end


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @files}
    end
 
  
  
  end

end
