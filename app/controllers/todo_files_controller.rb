class TodoFilesController < ApplicationController
 helper :task_folder
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
    @todo_file.revision_at = DateTime.now.utc

    if !@todo_file.filename.starts_with?("/")
      @todo_file.filename = "/" + @todo_file.filename
    end

    respond_to do |format|
      if @todo_file.save
        DropboxNavigator.UpdateFileInDropbox(@todo_file)
        format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @todo_file.filename, notice: 'File was successfully created.' }
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
    @todo_file.revision_at = DateTime.now.utc

    respond_to do |format|
      if @todo_file.saveFromWeb(params[:todo_file])
        format.html { render action: "update", :layout => false}
        format.json { head :ok }
        format.js
      else
        format.html { render action: "edit" }
        format.json { render json: @todo_file.errors, status: :unprocessable_entity }
        format.js
      end
    end
  end

  # DELETE /todo_files/1
  # DELETE /todo_files/1.json
  def destroy
    @todo_file = current_user.todo_files.find(params[:id])
    TodoFile.deleteFromWeb current_user, @todo_file.filename

    respond_to do |format|
      format.html { redirect_to :controller=>'task_folder', :action=>'folder_view', :path=> @todo_file.path, notice: 'File was deleted.' }
      format.json { head :ok }
    end
  end
end
