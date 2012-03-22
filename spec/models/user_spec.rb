require "spec_helper"

describe User do

  before(:each) do
    @user = Factory.create(:user)
  end

  it "should require unique email" do
    lambda{user2 = Factory.create(:user, :email=>@user.username, :username=>"user2")}.should raise_error
  end

  it "should require unique username" do
    lambda{user2 = Factory.create(:user, :email=>"user2@example.com", :username=>@user.username)}.should raise_error
  end

  it 'should be registered' do
    @user.is_registered.should be_true
  end

  describe ' When an anonymous user is created' do
    before (:each) do 
      @user = User.new
      @user.unverified_email = "foo@bar.com"
      @user.password = '123456'
      @user.save!
    end
    it 'should not be registered' do
      @user.is_registered.should be_false
    end
  end
end
