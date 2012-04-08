require "spec_helper"

describe TeamProductRequestsController do
  describe "routing" do

    it "routes to #index" do
      get("/team_product_requests").should route_to("team_product_requests#index")
    end

    it "routes to #new" do
      get("/team_product_requests/new").should route_to("team_product_requests#new")
    end

    it "routes to #show" do
      get("/team_product_requests/1").should route_to("team_product_requests#show", :id => "1")
    end

    it "routes to #edit" do
      get("/team_product_requests/1/edit").should route_to("team_product_requests#edit", :id => "1")
    end

    it "routes to #create" do
      post("/team_product_requests").should route_to("team_product_requests#create")
    end

    it "routes to #update" do
      put("/team_product_requests/1").should route_to("team_product_requests#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/team_product_requests/1").should route_to("team_product_requests#destroy", :id => "1")
    end

  end
end
