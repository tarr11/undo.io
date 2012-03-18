require 'spec_helper'

describe TodoFile do

  describe "When a file is created" do
    before(:each) do
      @user = Factory.create(:user)
      @file = @user.todo_files.create(Factory.attributes_for(:file))
    end

    it 'should have a single revision after save' do
      @file.task_file_revisions.count.should eq(1)
    end

    it 'should have a current revision UUID' do
      @file.current_revision.revision_uuid.should_not be_nil
    end

    it "shouldn't be shared" do
      @file.was_sent_to_other_user?.should be_false
    end

    describe "and is moved" do
      before (:each) do
        @file.move '/somewhere/else'
      end

      it 'should be in the new place' do
        @file.filename.should == '/somewhere/else'
      end
      describe "and another file is created" do
        before (:each) do
          @file2 = @user.todo_files.create(Factory.attributes_for(:file2))
          @file.move @file2.filename
        end
        
        it 'should be successful' do
          @file.should_not be_nil
        end

        it 'should be somewhere else' do
          @file.filename.should_not == @file2.filename
          @file.filename.should == '/foo2_1'
        end
      end

       
    end

    describe "and is_public is called" do
      before(:each) do
        @file.make_public()
      end
      it 'should set is_public to true' do
        @file.is_public.should be_true
      end
    end

    describe "and make_private is called" do
      before(:each) do
        @file.make_private()
      end
      it 'should set is_public to false' do
        @file.is_public.should be_false
      end
    end
  	
    describe "and shared with another user" do
      before (:each) do
        @user2 = Factory.create(:user2)
        @new_file = @file.share_with(@user2)
        @new_file.save!
      end

      it 'should be be in the inbox' do
        @new_file.user_id.should == @user2.id
        @new_file.filename.should == '/inbox/' + @user.username + @file.filename
      end

      it 'should be read-only' do 
        @new_file.is_read_only.should be_true
      end

      it 'should have the original file as the thread source' do
        @new_file.thread_source.should == @file
        @new_file.thread_source_id.should == @file.id
        @new_file.thread_source_id.should > 0
      end

      it 'should be shared' do
        @file.was_sent_to_other_user?.should be_true
      end
      
      it 'should have reply_to set back to the original file' do 
        @new_file.reply_to.should_not be_nil
        @new_file.reply_to.should == @file
      end
      
      describe "and user creates a copy to reply back" do
        before (:each) do
          @reply = @new_file.get_copy_of_file(@user2)
          @reply.save!
        end

        it 'should have reply set back to the original file' do 
          @reply.reply_to.should == @file
        end

        it 'should not be read only' do
          @reply.is_read_only.should_not be_true
        end

     
        describe "and user shares it back to original user" do
          before (:each) do
            
            @reply_back = @reply.share_with(@user)
          end
          it 'should be successful' do
            @reply_back.should_not be_nil
          end

          it 'in_reply_to should point back to the original' do
            @reply_back.in_reply_to.should == @file
          end 
        end
      end

    end

  end
end
=begin
      it 'should be in replies' do
        @reply.filename.should == @file.filename + "/replies/" + @user2.username + "/reply-1"
        Rails.logger.debug "FILENAME:" + @reply.filename
      end

      it 'user should see reply in replies collection' do
        @file.replies.length.should == 1
      end

      it 'should be owned by the recipient' do
        @reply.user_id.should == @user.id
      end
=end
=begin
      describe "and replied again back to the first user" do
        before (:each) do
            @reply2 = @new_file.get_copy_of_file(@user)
            @reply2.save!
        end
        it 'should be in /replies folder' do
          @reply2.filename.should == @file.filename + "/replies/" + @user2.username + "/reply-2"
          Rails.logger.debug "FILENAME:" + @reply2.filename
        end

        it 'user should see reply in replies collection' do
          @file.replies.length.should == 2
        end

        it 'should be owned by the recipient' do
          @reply2.user_id.should == @user.id
        end

      end
=end
=begin
    describe "and shared with another user" do
      before (:each) do
        @user2 = Factory.create(:user2)
        @file.share_with(@user2)
      end
      it 'shared_with user should have 1 file' do
        @user2.files_shared_with_user.count.should eq(1)
      end

      it 'no other users should see this file' do
        SharedFile.count.should eq(1)
      end
      it 'sharing_user should not have shared with itself' do
        @user.files_shared_with_user.count.should eq(0)
      end
      it 'file should be shared with this and only this user' do
        @file.shared_with_users.count.should eq(1)
      end

      it 'shared user should see it in their folder' do
        task_folder = @user2.task_folder
        task_folder.show_shared_only()
        task_folder.todo_files.length.should == 1
      end

      describe "and other user copies file" do

        before (:each) do
          @new_file = @file.copy(@user2, @file.filename, @file.current_revision.revision_uuid)
          @new_file.save!
        end
        it 'user2 should have a copy' do
          @user2.todo_files.count.should eq(1)
        end

        it 'user2 copy should point to the current revision' do
          @new_file.copied_task_file_revision_id.should eq(@file.current_revision.id)
        end

        it 'the copy should have the same contents' do
          @new_file.contents.should eq(@file.contents)
        end

        describe "and then user1 changes the file" do
          before (:each) do
            @file.contents = @file.contents + " " + "new stuff"
            @file.save!
          end

          describe "and then user2 reloads their file" do
            before(:each) do
              @file_reloaded = @user2.file(@file.filename)
            end

            it "user2 shouldn't see user1 changes" do
              @file_reloaded.contents.should_not eq(@file.contents)
            end

            it "user2 should be able to point to the revision they copied from" do
              @file_reloaded.copied_revision.contents.should eq(@file_reloaded.contents)
            end

          end

        end

      end


    end
=end


