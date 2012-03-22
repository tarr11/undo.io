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
      @received_email.to_email.should == "jamy@example.com"
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
  end

end
