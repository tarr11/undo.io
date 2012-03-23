require "spec_helper"

describe UserMailer do
  describe 'shared note' do
    before(:each) do
      @from_user = Factory.create(:user)
      @to_user = User.create_anonymous_user("test@example.com")
      @file = @from_user.todo_files.build(Factory.attributes_for(:file))
      @file.save!
      @email = UserMailer.shared_note(@from_user, @to_user, @file) 
    end

    it "should be addressed correctly" do
      @email.to == "test@example.com"
      @email.from.should_not be_nil
    end
    it 'should be deliverable' do
      lambda{@email.deliver!}.should_not raise_error
    end
  end
end
