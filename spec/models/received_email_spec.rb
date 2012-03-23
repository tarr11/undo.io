require 'spec_helper'

describe ReceivedEmail do

  
  describe "When a ReceivedEmail is created" do
    before (:each) do
      @from_user = Factory.create(:user)
      @to_user = Factory.create(:user2)
      @received_email = Factory.build(:received_email)
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
    end

    describe 'with a non-registered user' do
      before (:each) do 
        @received_email_non_registered = Factory.build(:received_email) 
        @received_email_non_registered.from = "Not Registered <notregistered@example.com>"
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
