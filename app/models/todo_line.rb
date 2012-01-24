require 'twitter-text'

class TodoLine
  include Twitter::Extractor

  attr_accessor :text
  attr_accessor :tab_count
  attr_accessor :line_type
  attr_accessor :line_number

  def to_s
    self.text
  end

  def get_people
    #return text.scan(/\b@([a-z0-9_]+)/i)
    return extract_mentioned_screen_names(text)
  end
end
