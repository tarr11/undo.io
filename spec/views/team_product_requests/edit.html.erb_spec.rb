require 'spec_helper'

describe "team_product_requests/edit" do
  before(:each) do
    @team_product_request = assign(:team_product_request, stub_model(TeamProductRequest,
      :email => "MyString",
      :feedback => "MyText"
    ))
  end

  it "renders the edit team_product_request form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => team_product_requests_path(@team_product_request), :method => "post" do
      assert_select "input#team_product_request_email", :name => "team_product_request[email]"
      assert_select "textarea#team_product_request_feedback", :name => "team_product_request[feedback]"
    end
  end
end
