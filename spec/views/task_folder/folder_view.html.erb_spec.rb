require 'spec_helper'
include TaskFolderHelper

describe "task_folder/folder_view" do
  login_user

  before (:each) do
    user = view.current_user
    file = user.todo_files.create(Factory.attributes_for(:file))
    @views = []
    @changed_files_by_date = get_changed_files_by_date([file])
    view.stub!(:user_owns_file).and_return(true)
  end

  it "should be successful" do
    render
  end
end
