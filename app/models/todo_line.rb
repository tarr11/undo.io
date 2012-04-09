require 'twitter-text'
require 'chronic'
class TodoLine
  include Twitter::Extractor

  attr_accessor :title
  attr_accessor :text
  attr_accessor :line_type
  attr_accessor :line_number
  attr_accessor :event
  attr_accessor :lines
  attr_accessor :tags
  attr_accessor :people
  attr_accessor :file
  attr_accessor :created_at
  attr_accessor :parent
  attr_accessor :children

  def initialize
    @children = []
  end

  def self.taskRegex
    /^[\s]*!/
  end

  def has_children?
    return children.length > 0
  end

  def self.completedtaskRegex
    /^[\s]*x[\s]*!/
  end

  def get_level
    start = 0
    parent = self.parent
    while true
      if parent.nil?
        return start
      end
      start = start + 1
      parent = parent.parent
    end


  end

  def tab_count
    # each tab counts as 1 tab for now
    # 4 spaces count as a tab


    if is_completed_task
      line = self.text.gsub(/^([\s]*)x(.*)/,"\\1\\2")
    else
      line = self.text
    end

    tab_count = 0
    space_count = 0
    line.each_char{ |c|
      if c == "\t"
        if space_count > 0
          tab_count += (space_count / 1).to_i
          space_count = 0
        end
        tab_count += 1
      elsif c == " "
        space_count += 1
      else
        # stop when we hit a non-whitespace character
        if space_count > 0
          tab_count += (space_count / 1).to_i
          space_count = 0
        end
        break
      end
    }

    # in case there's no whitespace
    tab_count += (space_count/1).to_i

    return tab_count

  end

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

  def is_task
    stripped = self.text.lstrip.downcase
    return stripped.match(TodoLine.taskRegex)
  end

  def get_cleaned_completed_task
    return self.text.gsub(TodoLine.completedtaskRegex,"")

  end

  def get_cleaned_line

    if is_completed_task
      get_cleaned_completed_task
    elsif is_task
      return self.text.gsub(TodoLine.taskRegex,"")
    else
      return self.text
    end
  end


  def is_completed_task
    stripped = self.text.lstrip.downcase
    return stripped.match(TodoLine.completedtaskRegex)

  end

  def get_event

	regexes =[/(0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])[- \/.]((19|20)\d\d)?/,
		/[1-9][012]?:[0-5][0-9](?:\s[ap]m)?/i,
	/(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s[0-9]{1,2}/i,
	/(january|february|march|april|may|june|july|august|september|october|november|december)\s[0-9]{1,2}/i
	]

	extracted_text = ""
	regexes.each do |re|
		match = re.match(text)
		unless match.nil?
			extracted_text = extracted_text + " " + match[0]
		end
	end
	puts extracted_text

    #match = text.match(/(0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d/)
    #date = chronic.parse(text, :now=>self.created_at)
    unless extracted_text.blank?

      event = Event.new
      event.start_at = Chronic.parse(extracted_text,:now=>self.created_at)
      event.title = text
      event.todo_line = self
      return event
    end


  end
end
