require "spec_helper"

describe TeamProductRequestsController do
  describe "routing" do

    it "routes to #index" do
      get("/team_product_requests").should route_to("team_product_requests#index")
    end

    it "routes to #new" do
      get("/team_product_requests/new").should route_to("team_product_requests#new")
    end

    it "routes to #create" do
      post("/team_product_requests").should route_to("team_product_requests#create")
    end

  end
end
