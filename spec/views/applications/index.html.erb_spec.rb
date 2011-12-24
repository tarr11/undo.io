require 'spec_helper'

describe "applications/index.html.erb" do
  before(:each) do
    assign(:applications, [
      stub_model(Application,
        :name => "Name"
      ),
      stub_model(Application,
        :name => "Name"
      )
    ])
  end

  it "renders a list of applications" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "Name".to_s, :count => 2
  end
end