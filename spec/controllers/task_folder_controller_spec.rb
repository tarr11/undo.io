require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe TaskFolderController do
  login_user

  describe "GET 'folder_view' /user" do
    it "should be successful" do
      get :folder_view, :path => "/", :username=>subject.current_user.username
      response.should be_success
    end

    describe "when a file is in a subfolder'" do
      before (:each) do
          @file = subject.current_user.todo_files.build(Factory.attributes_for(:file))
          @file.filename = "/path/to/file"
          @file.save!
      end
      it "should be visible" do
        get :folder_view, :path => "/", :username=>subject.current_user.username
        task_folder = assigns(:taskfolder)
        task_folder.files.length.should == 1
        response.should be_success

      end
    end
  end

  describe "GET 'folder_view' /file/new" do
    before (:each) do
      get :new_file, :username=>subject.current_user.username
    end

    it 'should be successful' do
      response.should be_success
    end 
    it 'should have a user_who_created_this' do
      user = assigns(:user_who_wrote_this) 
      user.should_not be_nil
    end

  end

=begin
  describe "GET 'folder_view' /user?shared=y" do
    it "should be successful" do
      get :folder_view, :path => "/", :username=>subject.current_user.username, :shared=>'y'
      task_folder = assigns(:taskfolder)
      task_folder.should_not be_nil
      response.should be_success
    end

    describe "when there is a file shared" do
      before (:each) do
          @user2 = Factory.create(:user2)
          @file = @user2.todo_files.create(Factory.attributes_for(:file))
          @file.share_with(subject.current_user)
      end

      it 'should find the file' do
        get :folder_view, :path => "/", :username=>subject.current_user.username, :shared=>'y'
        task_folder = assigns(:taskfolder)
        task_folder.todo_files.length.should == 1
        response.should be_success

      end
    end
  end
=end

  describe "GET 'folder_view' /foo?compare=/xxx@yyy.com" do
    before (:each) do
      @file = subject.current_user.todo_files.build(Factory.attributes_for(:file))
      @file.filename = '/foo'
      @file.save!
      @file2 = subject.current_user.todo_files.build(Factory.attributes_for(:file))
      @file2.filename = '/inbox/foo@bar.com/bla'
      @file2.save!
    end

   it "should be successful" do
      get :folder_view, :username =>subject.current_user.username, :path=>"/foo", :compare => "/" + subject.current_user.username + "/inbox/foo@bar.com/bla" 
      response.should be_success
    end

  end
 

  describe "GET 'folder_view' /user?q=foo" do
    it "should be successful" do
      get :folder_view, :path => "/", :username =>subject.current_user.username, :q=>"foo"
      response.should be_success
    end

  end
  describe "GET 'folder_view' /user/file-that-doesnt-exist" do

    it "should not be found" do
      expect do
        get :folder_view, :path => '/fake-file', :username=>subject.current_user.username
        end.to raise_error(ActionController::RoutingError)
    end

  end

  describe "GET 'folder_view' /user/sub/file" do
    before (:each) do
      @file = subject.current_user.todo_files.build(Factory.attributes_for(:file))
      @file.filename = '/user/sub/sub2/file'
      @file.save!
    end

    it "should find the subfolder" do
      get :folder_view, :path=>'/user/sub/', :username=>subject.current_user.username
      response.should be_success 
    end
  end

  describe "GET 'folder_view' /user/file" do
    before (:each) do
      @file = subject.current_user.todo_files.create(Factory.attributes_for(:file))
    end

    it "should be successful" do
      get :folder_view, :path => @file.filename, :username=>subject.current_user.username
      response.should be_success
    end

    describe "GET 'folder_view /user/file?view=feed" do
      it 'should be successful' do
        get :folder_view, :path => @file.filename, :username=>subject.current_user.username, :view=>'feed'
      end
    end

    describe "GET 'folder_view /user/file?view=tasks" do
      it 'should be successful' do
        get :folder_view, :path => @file.filename, :username=>subject.current_user.username, :view=>'tasks'
      end
    end

    describe "GET 'folder_view /user/file?view=events" do
      it 'should be successful' do
        get :folder_view, :path => @file.filename, :username=>subject.current_user.username, :view=>'events'
      end
    end

    describe "PUT 'create' /user/file :method=>'create'" do
      before (:each) do
        put :update,:savecontents=>'Some stuff', :path => @file.filename, :username => subject.current_user.username, :method => :put, :filename => '/some-new-file', :format=>:json
      end
      it 'should be successful' do
        response.should be_success
      end
    end
 
    describe "PUT 'comment' /user/file :method=>'comment'" do
      before (:each) do
        put :update, :original_content=>'Some stuff', :path => @file.filename, :revision_uuid=>@file.current_revision.revision_uuid,  :start_pos=>1, :replacement_content=>'test',  :method => :comment, :format=>:json
      end
      it 'should be successful' do
        response.should be_success
      end
    end
    describe "PUT 'update' /user/file :method=>'move'" do
      before (:each) do
        put :update, :path => @file.filename, :username => subject.current_user.username, :method => :move, :filename => '/user/file-moved'
      end
      it 'should be successful' do
        response.should be_redirect
      end
    end
    describe "PUT 'update' /user/file :method=>'share'" do
      before (:each) do
        put :update, :path => @file.filename, :username => subject.current_user.username, :method => :share, :shared_user_list => "nonregistereduser@example.com"
      end
      it 'should be successful' do
        response.should be_redirect
      end
    end
  end


  describe 'when viewing another users file' do
    before (:each) do
      @user2 = Factory.create(:user2)
      @file = @user2.todo_files.create(Factory.attributes_for(:file))
    end

    describe 'when it is private' do
      it 'should not be found' do
        expect do
          get :folder_view, :path => @file.filename, :username=>@user2.username
        end.to raise_error(ActionController::RoutingError)
      end
    end

    describe 'when it is public' do
      before (:each) do
        @public_file = @user2.todo_files.create(Factory.attributes_for(:public_file))
      end
      it 'should be found' do
          get :folder_view, :path => @public_file.filename, :username=>@user2.username
          response.should be_success
      end

      describe 'when it gets copied' do

        it 'should redirect to the new copy' do
          put :update, :path => @public_file.filename, :username=>@user2.username, :method=>"copy", :copy_filename=>@public_file.filename, :revision_uuid=>@public_file.current_revision.revision_uuid.to_s
          file = subject.current_user.file(@public_file.filename)
          is_good_redirect_url = response.location.end_with?(subject.current_user.username + @public_file.filename)
          is_good_redirect_url.should be_true
        end

        describe 'when the copy gets changed' do

        end

      end
    end


  end



end
