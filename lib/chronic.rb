module Chronic_test
  require 'chronic'
 # To change this template use File | Settings | File Templates.
  def self.parse_it

    result = Chronic.parse('3/5', :ambiguous_time_range => :none)
    puts result
  end
  Chronic_test.parse_it

 end