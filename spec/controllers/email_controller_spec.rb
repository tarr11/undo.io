require 'spec_helper'

describe EmailController do
  describe "POST 'post'" do
    before (:each) do
      @from_user = Factory.create(:user)
      @to_user = Factory.create(:user2)
      @file = @to_user.todo_files.build(Factory.attributes_for(:file))
      @file.save!
      text = "this is a test\n--\nreply_to_id:" + @file.file_uuid + "\nmorejunk"
      post :post, :from=>"Douglas Tarr <douxx@example.com>", :recipient => "jamy@example.com", :subject => "Test", "stripped-text"=>text,"body-plain"=>text
    end

    it 'should be successful' do
      response.should be_success
    end

    it 'should have an email object' do
      received_email = assigns(:received_email)
      received_email.should_not be_nil
      received_email.valid?.should be_true
      received_email.to_user_copy.should_not be_nil
      received_email.to_user_copy.reply_to.should_not be_nil
      received_email.to_user_copy.in_reply_to.should_not be_nil
    end
     
  end
end
