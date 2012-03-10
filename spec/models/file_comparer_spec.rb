require 'spec_helper'

describe FileComparer do
  describe "When two unrelated files are compared" do

    before (:each) do
      @user = Factory.build(:user)
      @file1 = @user.todo_files.build(Factory.attributes_for(:file))
      @file2 = @user.todo_files.build(Factory.attributes_for(:file2))
      @comparer = FileComparer.new(@file1, @file2)
    end

    it 'should not be related' do
      @comparer.is_related?.should be_false
    end

    describe "and file1.contents='foo' and file2.contents='bar'" do
      before (:each) do
        @file1.contents = "foo"
        @file2.contents = "bar"
        @comparer = FileComparer.new(@file1, @file2)
      end

      it 'should be different' do
        @comparer.is_different?.should be_true
      end

      it 'should have two differences' do
        @comparer.diffs.length.should == 2
      end

      it 'should have one insert' do
        @comparer.diffs.select{|a| a.action == :insert}.length.should == 1
      end

      it 'should have one delete' do
        @comparer.diffs.select{|a| a.action == :delete}.length.should == 1
      end

      describe 'and the diff is tokenized' do
        before (:each) do
          @tokens = @comparer.to_enum(:tokenize).to_a
        end

        it 'should be successful' do
          @tokens.should_not be_nil
        end
      end

    end

    describe "and file1.contents='foo' and file2.contents='foo'" do
      before (:each) do
        @file1.contents = "foo"
        @file2.contents = "foo"
        @comparer = FileComparer.new(@file1, @file2)
      end

      it 'should be the same' do
        @comparer.is_different?.should be_false
      end

    end


  end


  describe "When a file is copied to another file" do

    before (:each) do
      @user = Factory.create(:user)
      @file1 = @user.todo_files.build(Factory.attributes_for(:file))
      @file1.contents = "foo"
      @file1.save!
      @file2 = @file1.copy(@user,'/foo2',@file1.current_revision.revision_uuid)
      @comparer = FileComparer.new(@file1, @file2)
    end

    it 'should be related' do
      @comparer.is_related?.should be_true
    end

    it 'should be the same' do
      @comparer.is_different?.should be_false
    end

    describe 'and that file is edited and saved' do

      before (:each) do
        @file2.contents = "foo bla"
        @file2.save!
        @comparer = FileComparer.new(@file1,@file2)
      end

      it 'should still be related' do
        @comparer.is_related?.should be_true
      end

      it 'should be different' do
        @comparer.is_different?.should be_true
      end

      it 'should merge correctly' do
        @comparer.merge_error?.should be_false
      end

      it 'should take the new file as the final result' do
        @comparer.merged_result.should == @file2.contents
      end

      describe ' and then the original file is edited and saved' do
        before (:each) do
          @file1.contents = "foo bar"
          @file1.save!
          @comparer = FileComparer.new(@file1,@file2)
        end

        it 'should still be related' do
          @comparer.is_related?.should be_true
        end

        it 'should be different' do
          @comparer.is_different?.should be_true
        end

        it 'should not have a merge error' do
          @comparer.merge_error?.should be_false
        end

        it 'should merge correctly' do
          @comparer.merged_result.should == 'foo bla bar'
        end

      end
    end


  end

end
