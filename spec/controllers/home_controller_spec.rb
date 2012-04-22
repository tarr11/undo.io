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

      describe "GET /public" do

        it "should be not be successful" do
          # need to stub out search calls
          # public pages fail when there are no notes in them
          lambda{get :public_view}.should raise_error
        end
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
