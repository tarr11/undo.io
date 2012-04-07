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
  describe "When a file is created with an unregisterd user" do
    before (:each) do 
      @user = Factory.create(:user_unverified)
      @file = @user.todo_files.build(Factory.attributes_for(:file))
      @file.save!
    end

    it 'should be findable' do
      file = TaskFolder.get_file_from_path('/' + @user.unverified_email + @file.filename)
      file.should_not be_nil
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

    it "should be able to send an email reminder" do
      result = @folder.send_email_reminders( DateTime.parse("2012-3-15"), DateTime.parse("2012-3-16") )
      result.should be_true
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
      it 'should be empty' do
        @folder.files.length.should == 0
      end
    end
  end

end
