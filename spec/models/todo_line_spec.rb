require 'spec_helper'

describe TodoLine do

 describe "When a TodoLine is created " do
    before (:each) do
      @todoLine = TodoLine.new
      @todoLine.text = "Something 3/15/2012"
    end
    it 'should have an event' do
      event = @todoLine.get_event
      event.should_not be_nil
    end
  end
end
