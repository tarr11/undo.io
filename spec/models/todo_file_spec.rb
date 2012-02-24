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


  end



end
