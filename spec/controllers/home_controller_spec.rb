require 'spec_helper'

describe HomeController do
  describe "GET 'index'" do
    describe "when logged in" do
      login_user

      it "should be successful" do
        TodoFile.stub(:search) {nil}
        get :index
        response.should be_success
      end

    end

    describe "when not logged in" do
      it "should be successful" do
        get :index
        response.should be_success
      end
    end
  end
end