require 'twitter-text'
require 'chronic'
class TodoLine
  include Twitter::Extractor

  attr_accessor :title
  attr_accessor :text
  attr_accessor :tab_count
  attr_accessor :line_type
  attr_accessor :line_number
  attr_accessor :event
  attr_accessor :lines
  attr_accessor :tags
  attr_accessor :people
  attr_accessor :file
  attr_accessor :created_at

  def to_s
    self.text
  end

  def get_people
    #return text.scan(/\b@([a-z0-9_]+)/i)
    return extract_mentioned_screen_names(text)
  end

  def get_tags
    #return text.scan(/\b@([a-z0-9_]+)/i)
    return extract_hashtags(text)
  end

  def get_event

    date = Chronic.parse(text, :now=>self.created_at)
    unless date.nil?
      event = Event.new
      event.start_at = date
      event.title = text
      return event
    end


  end
end
