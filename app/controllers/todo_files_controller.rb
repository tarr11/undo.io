class TodoFilesController < ApplicationController

 before_filter :authenticate_user!


  # GET /todo_files
  # GET /todo_files.json
  def index
    @todo_files = current_user.todo_files.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @todo_files }
    end
  end

  # GET /todo_files/1
  # GET /todo_files/1.json
  def show
    @todo_file = current_user.todo_files.find(params[:id])

    @revisions = @todo_file.task_file_revisions

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @todo_file }
    end
  end

  # GET /todo_files/new
  # GET /todo_files/new.json
  def new
    @todo_file = current_user.todo_files.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @todo_file }
    end
  end

  # GET /todo_files/1/edit
  def edit
    @todo_file = current_user.todo_files.find(params[:id])
  end

  # POST /todo_files
  # POST /todo_files.json
  def create
    @todo_file = current_user.todo_files.new(params[:todo_file])

    respond_to do |format|
      if @todo_file.save
        format.html { redirect_to @todo_file, notice: 'Todo file was successfully created.' }
        format.json { render json: @todo_file, status: :created, location: @todo_file }
      else
        format.html { render action: "new" }
        format.json { render json: @todo_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /todo_files/1
  # PUT /todo_files/1.json
  def update
    @todo_file = current_user.todo_files.find(params[:id])

    respond_to do |format|
      if @todo_file.update_attributes!(params[:todo_file])
        format.html { redirect_to @todo_file, notice: 'Todo file was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @todo_file.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /todo_files/1
  # DELETE /todo_files/1.json
  def destroy
    @todo_file = current_user.todo_files.find(params[:id])
    @todo_file.destroy

    respond_to do |format|
      format.html { redirect_to todo_files_url }
      format.json { head :ok }
    end
  end
end
