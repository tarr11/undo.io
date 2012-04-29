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

  describe 'follow message' do
    before (:each) do
      @from_user = Factory.create(:user)
      @to_user = Factory.create(:user2)
      @email = UserMailer.follow_message @from_user, @to_user
    end
    
    it 'should be deliverable' do
      lambda{@email.deliver!}.should_not raise_error
    end

  end
  describe 'reminder note' do 
    before(:each) do
      @from_user = Factory.create(:user)
      @to_user = User.create_anonymous_user("test@example.com")
      @file = @from_user.todo_files.build(Factory.attributes_for(:file))
      @file.save!
      events = @file.to_enum(:get_events).to_a
      @email = UserMailer.reminder_note(@from_user, events) 
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
