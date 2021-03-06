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

  it " should require case insensitve unique username" do
    lambda{user2 = Factory.create(:user, :email=>"user2@example.com", :username=>@user.username.upcase)}.should raise_error
  end

  it 'should be registered' do
    @user.is_registered.should be_true
  end

  describe ' and another user is created' do

    before (:each) do
      @user2 = Factory.build(:user)
      @user2.username = 'something_else'
      @user2.email = 'another@sample.com'
      @user2.save!
    end

    describe 'and that user follows the first user' do
      before (:each) do
        @user2.follow @user
      end
      it 'should be successful' do
        @user2.is_following?(@user).should be_true
      end

      describe 'and that user unfollows the first user' do

        before (:each) do
          @user2.unfollow @user
        end
        it 'should be successful' do
          @user2.is_following?(@user).should be_false
        end
      end
      
    end
  end
  describe ' When an anonymous user is created' do
    before (:each) do 
      @user = User.create_anonymous_user("foo@bar.com")
    end
    it 'should not be registered' do
      @user.is_registered.should be_false
    end
    it 'should allow email' do
      @user.allow_email.should be_true
    end
  end
end
