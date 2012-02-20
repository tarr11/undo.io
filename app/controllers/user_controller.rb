class UserController < ApplicationController


  def show
    @user = current_user
  end

  def edit

  end

  def update

    respond_to do |format|
      if current_user.update_attributes(params[:user])
        format.html { redirect_to :action=>:show, notice: 'Settings were successfully updated.' }
        format.mobile
        format.json { head :ok }
      else
        @user=current_user
        format.html { render :action=>:show }
        format.mobile
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end

  end


end
