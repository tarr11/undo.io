require 'spec_helper'

describe "team_product_requests/index" do
  before(:each) do
    assign(:team_product_requests, [
      stub_model(TeamProductRequest,
        :email => "Email",
        :feedback => "MyText"
      ),
      stub_model(TeamProductRequest,
        :email => "Email",
        :feedback => "MyText"
      )
    ])
  end

  it "renders a list of team_product_requests" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Email".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
