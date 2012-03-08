require 'spec_helper'

describe TaskFolderHelper do
  describe "When get_file_from_path is called" do
    before (:each) do
      @user = Factory.create(:user)
      @file = @user.todo_files.create(Factory.attributes_for(:file))
    end
    it "returns a file" do
      file = helper.get_file_from_path("/" + @user.username + "/foo")
      file.should_not be_nil
    end
  end

  describe "When a file is created with spaces in the name" do
    before (:each) do
      @user = Factory.create(:user)
      @file = @user.todo_files.build(Factory.attributes_for(:file))
      @file.filename = "/foo bar"
      @file.save!
    end

    it "returns a file" do
      file = helper.get_file_from_path("/doug/foo bar")
      file.should_not be_nil
    end

    describe "and the filename is urlencoded" do
      it "returns a file" do
        file = helper.get_file_from_path("/doug/foo%20bar")
        file.should_not be_nil
      end
    end

  end
end
