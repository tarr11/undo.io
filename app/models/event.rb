class Event
  attr_accessor :start_at
  attr_accessor :title
  attr_accessor :slide
  attr_accessor :file

  def self.extract_date(text,created_at)
	regexes =[/(0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])[- \/.]((19|20)\d\d)?/,
		/[1-9][012]?:[0-5][0-9](?:\s[ap]m)?/i,
	/(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s[0-9]{1,2}/i,
	/(january|february|march|april|may|june|july|august|september|october|november|december)\s[0-9]{1,2}/i,
	/(today|tomorrow|this week|next week|next month|next year|eod|cob|bod)/i,
	/(sunday|monday|tuesday|wednesday|thursday|friday|saturday)/i
	]

	extracted_text = ""
	regexes.each do |re|
		match = re.match(text)
		unless match.nil?
			extracted_text = extracted_text + " " + match[0]
		end
	end
    return Chronic.parse(extracted_text,:now=>created_at)
  end


  def self.get_event(text, file, slide)

    extracted_date = extract_date(text, file.created_at)
    #match = text.match(/(0?[1-9]|1[012])[- \/.](0?[1-9]|[12][0-9]|3[01])[- \/.](19|20)\d\d/)
    #date = chronic.parse(text, :now=>self.created_at)
    unless extracted_date.blank?
      event = Event.new
      event.start_at =  extracted_date    
        event.file = file
      event.slide = slide
      event.title = text
      unless event.start_at.nil?
        return event
      end
    end


  end
end
