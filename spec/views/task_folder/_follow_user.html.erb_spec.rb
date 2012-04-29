require 'spec_helper'
include TaskFolderHelper

describe "task_folder/_follow_user" do
  
  describe 'when not logged in' do
    before (:each) do
      @user = Factory.create(:user)
      file = @user.todo_files.create(Factory.attributes_for(:file))
      @views = []
      @changed_files_by_date = get_changed_files_by_date([file])
      view.stub!(:user_owns_file).and_return(true)
    end

    it "should be successful" do
      assign(:user, @user)
      render
    end
  end

  describe 'when logged in' do
    login_user
    before (:each) do
      @user = Factory.create(:user2)
      file = @user.todo_files.create(Factory.attributes_for(:file))
      @views = []
      @changed_files_by_date = get_changed_files_by_date([file])
      view.stub!(:user_owns_file).and_return(true)
      view.stub!(:user).and_return(@user)
    end

    it "should be successful" do
      render
    end
  end

end
