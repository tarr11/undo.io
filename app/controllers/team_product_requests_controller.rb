class TeamProductRequestsController < ApplicationController
  # GET /team_product_requests
  # GET /team_product_requests.json
  def index
    @team_product_requests = TeamProductRequest.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @team_product_requests }
    end
  end

  # GET /team_product_requests/1
  # GET /team_product_requests/1.json
  def show
    @team_product_request = TeamProductRequest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @team_product_request }
    end
  end

  # GET /team_product_requests/new
  # GET /team_product_requests/new.json
  def new
    @team_product_request = TeamProductRequest.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @team_product_request }
    end
  end

  # GET /team_product_requests/1/edit
  def edit
    @team_product_request = TeamProductRequest.find(params[:id])
  end

  # POST /team_product_requests
  # POST /team_product_requests.json
  def create
    @team_product_request = TeamProductRequest.new(params[:team_product_request])

    respond_to do |format|
      if @team_product_request.save
        format.html { redirect_to team_product_requests_url}
        format.json { render json: @team_product_request, status: :created, location: @team_product_request }
      else
        format.html { render action: "new" }
        format.json { render json: @team_product_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /team_product_requests/1
  # PUT /team_product_requests/1.json
  def update
    @team_product_request = TeamProductRequest.find(params[:id])

    respond_to do |format|
      if @team_product_request.update_attributes(params[:team_product_request])
        format.html { redirect_to @team_product_request, notice: 'Team product request was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @team_product_request.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /team_product_requests/1
  # DELETE /team_product_requests/1.json
  def destroy
    @team_product_request = TeamProductRequest.find(params[:id])
    @team_product_request.destroy

    respond_to do |format|
      format.html { redirect_to team_product_requests_url }
      format.json { head :no_content }
    end
  end
end
