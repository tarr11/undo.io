require 'spec_helper'

describe TaskFolder do


  describe "When there are no files" do
    before(:each) do
      @user = Factory.create(:user)
    end
    it 'should have a files collection that is not nill' do
       @user.task_folder.should_not be_nil
        @user.task_folder.files.should_not be_nil
        @user.task_folder.files.length.should == 0
    end
  end
  describe "When a file is created" do
    before(:each) do
          @user = Factory.create(:user)
          @file = @user.todo_files.create(Factory.attributes_for(:file))
          @folder = @file.task_folder
    end

    it 'should have a folder' do
      @folder.should_not be_nil
    end

    describe "when it is restricted to public files" do
      before(:each) do
        @folder.show_public_only
      end
      it 'should only show public files' do
        @folder.files.all?{|a|a.is_public}.should be_true
      end
    end

    describe "when it is restricted to shared files" do
      before(:each) do
        @folder.show_shared_only
      end
      it 'should be successful' do

      end
    end
    end

end
