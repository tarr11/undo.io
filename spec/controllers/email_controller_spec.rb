require 'spec_helper'

describe EmailController do
  describe "POST 'post'" do
    before (:each) do
      @from_user = Factory.create(:user)
      @to_user = Factory.create(:user2)
      post :post, :from=>"Douglas Tarr <doug@example.com>", :to => "J'Amy Tarr <jamy@example.com>", :subject => "Test", "stripped-text"=>"this is a test","body-plain"=>"this is a test" 
    end

    it 'should be successful' do
      response.should be_success
    end

    it 'should have an email object' do
      received_email = assigns(:received_email)
      received_email.should_not be_nil
      received_email.valid?.should be_true
    end
     
  end
end
