require 'spec_helper'

describe "applications/show.html.erb" do
  before(:each) do
    @application = assign(:application, stub_model(Application,
      :name => "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    rendered.should match(/Name/)
  end
end
