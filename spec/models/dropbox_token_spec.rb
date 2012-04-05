# encoding: utf-8
require 'spec_helper'

describe DropboxToken do
  describe "When sync is called with a new file" do
    before(:each) do
      @user = Factory.create(:user)
      @file = @user.todo_files.build(Factory.attributes_for(:file))
      @file.save!
      @token = Factory.build(:dropbox_token)
      @token.user = @user
      @user.stub(:dropbox){@token}
     @token.stub(:get_file_from_dropbox) {"some stuff"}
      @token.stub(:save_cursor){}
       delta = {"entries" => [["/test", {"modified" => "Thu, 29 Dec 2011 01:53:26 +0000", "is_dir" => false}]], "cursor" => "AgxHowM8wb-zyJmGz-ILKj6WTlI4ODHoMWx7lR-ijKO_eJxjSLf_wsCw5gerk8gdBgZDGQYgAAA_owTD", "has_more" => false}
      @token.stub(:get_delta){delta}
      @user.dropbox.sync_delta     
    end

    it 'should succeed' do
      @user.file("/test").should_not be_nil
    end
    it 'should have the right contents' do
      @user.file('/test').contents.should == "some stuff"
    end
  
    it "should have a dropbox edit source" do
      @user.file("/test").edit_source.should == "dropbox"
    end 
    it "shouldn't delete the old file" do
      @user.file(@file.filename).should_not be_nil
    end 
    describe "and the file is ASCII encoded" do
      before (:each) do
        ascii_stuff = "somet stuff \x95 other stuff"
        @token.stub(:get_file_from_dropbox) {ascii_stuff}
      end
      it 'should not raise' do
        lambda{@user.dropbox.sync_delta}.should_not raise_error
      end
    end

    describe "and then the file is deleted in dropbox" do
      before(:each) do 
        delta = {"entries" => [["/test", nil]], "cursor" => "AgxHowM8wb-zyJmGz-ILKj6WTlI4ODHoMWx7lR-ijKO_eJxjSLf_wsCw5gerk8gdBgZDGQYgAAA_owTD", "has_more" => false}
        @token.stub(:get_delta){delta}
        @user.dropbox.sync_delta     
      end

      it 'should be deleted' do
        @user.file("/test").should be_nil
      end

      it 'should not delete the other file' do
        @user.file(@file.filename).should_not be_nil
      end
    end
    
     describe "and then a directory is deleted in dropbox" do
      before(:each) do 
        @file = @user.todo_files.build(Factory.attributes_for(:file))
        @file.filename = "/some/path"
        @file.save!
        @file2 = @user.todo_files.build(Factory.attributes_for(:file))
        @file2.filename = "/something"
        @file2.save!
    delta = {"entries" => [["/some", nil]], "cursor" => "AgxHowM8wb-zyJmGz-ILKj6WTlI4ODHoMWx7lR-ijKO_eJxjSLf_wsCw5gerk8gdBgZDGQYgAAA_owTD", "has_more" => false}
        @token.stub(:get_delta){delta}
        @user.dropbox.sync_delta     
      end

      it 'should be deleted' do
        @user.file("/some/path").should be_nil
      end

      it 'should not delete the other file' do
        @user.file(@file2.filename).should_not be_nil
      end
    end
    
  end 
end
