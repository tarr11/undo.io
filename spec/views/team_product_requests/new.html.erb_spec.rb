require 'spec_helper'

describe "team_product_requests/new" do
  before(:each) do
    assign(:team_product_request, stub_model(TeamProductRequest,
      :email => "MyString",
      :feedback => "MyText"
    ).as_new_record)
  end

  it "renders new team_product_request form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => team_product_requests_path, :method => "post" do
      assert_select "input#team_product_request_email", :name => "team_product_request[email]"
      assert_select "textarea#team_product_request_feedback", :name => "team_product_request[feedback]"
    end
  end
end
