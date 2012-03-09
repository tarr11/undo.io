require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe TaskFolderController do
  login_user

  describe "GET 'folder_view' /user" do
    it "should be successful" do
      get :folder_view, :path => "/", :username=>subject.current_user.username
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
