require "spec_helper"

describe TaskFolderController do
  describe "routing" do

    it "routes to #index" do
      get("/username").should route_to("task_folder#folder_view", :username=>"username", :path=>"")
    end

  end
end
