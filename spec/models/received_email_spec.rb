require 'spec_helper'

describe ReceivedEmail do

  describe "when an email is created with <>" do
    it 'should be valid' do
      email = ReceivedEmail.extract_email("Douglas tarr <douglas.tarr@gmail.com>")
      email.should == "douglas.tarr@gmail.com"
    end
  end

  describe "when an email is created just plain" do
    it 'should be valid' do
      email = ReceivedEmail.extract_email("douglas.tarr@gmail.com")
      email.should == "douglas.tarr@gmail.com"
    end
  end

  describe "when an email has a gmail-like reply-block" do 

    it 'should strip it' do
      email = ReceivedEmail.strip_reply_to_blocks("message\nOn March 5, 2012\ndouglas.tarr@gmail.com wrote:\nSome stuff")
      email.should == "message\nSome stuff"
    end
    it "shouldn't strip tabs" do
      email = ReceivedEmail.strip_reply_to_blocks("\t\tmessage\nOn March 5, 2012\ndouglas.tarr@gmail.com wrote:\nSome stuff")
      email.should == "\t\tmessage\nSome stuff"
    end
  end  
  describe "when an email has a outlook-like reply-block" do 

    it 'should strip it' do
      email = ReceivedEmail.strip_reply_to_blocks("message\nFrom:Douglas Tarr<dougt@undo.io>\nTo:J'Amy Tarr <jamy@undo.io>\nSubject:something\nDate:March 10, 2012\nSome stuff")
      email.should == "message\nSome stuff"
    end
  end  
   describe "When a ReceivedEmail is created with a reply_to_id" do
    before (:each) do
      @from_user = Factory.create(:user)
      @to_user = Factory.create(:user2)
      @file = @to_user.todo_files.create(Factory.attributes_for(:file))
      @received_email = Factory.build(:received_email)
      @received_email.body_plain = "\tsomething someting \n reply_to_id:" + @file.file_uuid + " \n\n"
      @received_email.body_stripped = "\tsomething someting \n reply_to_id" + @file.file_uuid + " \n\n"
    end
  
   it 'should succeed' do
     lambda {@received_email.process}.should_not raise_error
   end 

   describe 'and it is processed' do
    before(:each) do
     @received_email.process
    end

    it 'should have a reply_to' do
      @received_email.reply_to.should_not be_nil
    end
    it 'should not strip tabs' do
      puts @received_email.to_user_copy.contents 
      @received_email.to_user_copy.contents.include?("\t").should be_true
    end
   end
  end

  describe "When a ReceivedEmail is created" do
    before (:each) do
      @from_user = Factory.create(:user)
      @to_user = Factory.create(:user2)
      @received_email = Factory.build(:received_email)
      @file = @to_user.todo_files.create(Factory.attributes_for(:file))
    end
   
    it 'should be valid' do
      @received_email.valid?.should be_true
      @received_email.from_email.should == "doug@example.com"
      @received_email.to_username.should == "jamy"
    end
    describe 'and process is called' do
      before (:each) do
        @received_email.process
      end
      it 'to_user should not be nil' do
        @received_email.to_user.should_not be_nil        
      end
      it 'from_user should not be nil' do
        @received_email.from_user.should_not be_nil        
      end
      it 'from_user_copy should not be nil' do
        @received_email.from_user_copy.should_not be_nil
        @received_email.from_user_copy.filename.should == '/Test Subject'
        @received_email.from_user_copy.user.should == @from_user
      end

      it 'to_user_copy should not be nil' do
        @received_email.to_user_copy.should_not be_nil
        @received_email.to_user_copy.filename.should == '/inbox/doug/Test Subject'
      end
      it 'should not have a footer anymore' do
        contents = @received_email.to_user_copy.contents
        contents.include?("--").should be_false
      end
    end

    describe 'with a non-registered user' do
      before (:each) do 
        @received_email_non_registered = Factory.build(:received_email) 
        @received_email_non_registered.from = "Not Registered <notregistered@example.com>"
        @received_email_non_registered.body_plain = "test"
        @received_email_non_registered.body_stripped = "test"
        @received_email_non_registered.process
      end 

      it 'from_user_copy should not be nil' do
        @received_email_non_registered.from_user_copy.should_not be_nil
        @received_email_non_registered.from_user_copy.filename.should == '/Test Subject'
      end

      it 'to_user_copy should not be nil' do
        @received_email_non_registered.to_user_copy.should_not be_nil
        @received_email_non_registered.to_user_copy.filename.should == '/inbox/notregistered@example.com/Test Subject'
      end

      it 'to user should be not registered' do
        @received_email_non_registered.from_user.is_registered?.should be_false
      end 
    end
  end

end
