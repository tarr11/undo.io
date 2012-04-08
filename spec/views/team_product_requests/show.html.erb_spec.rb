require 'spec_helper'

describe "team_product_requests/show" do
  before(:each) do
    @team_product_request = assign(:team_product_request, stub_model(TeamProductRequest,
      :email => "Email",
      :feedback => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Email/)
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/MyText/)
  end
end
