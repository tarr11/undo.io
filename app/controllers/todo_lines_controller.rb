class TodoLinesController < ApplicationController
  def show
     @todo_line = TodoLine.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @todo_line }
    end
  end

end
