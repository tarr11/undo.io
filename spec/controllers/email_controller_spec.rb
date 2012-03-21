require 'spec_helper'

describe EmailController do
  describe "POST 'post'" do
    it "should be successful" do
      post :post, :from=>"Douglas Tarr <douglas.tarr@gmail.com>", :recipient => "J'Amy Tarr <jamytarr@gmail.com>", :subject => "Test", "stripped-text"=>"this is a test","body-plain"=>"this is a test" 

      response.should be_success
      received_email = assigns(:received_email)
      received_email.should_not be_nil
      received_email.from.should == "Douglas Tarr <douglas.tarr@gmail.com>"
      received_email.valid?.should be_true
    end
  end
end
