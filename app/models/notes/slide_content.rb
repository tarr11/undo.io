class Notes::SlideContent
  # To change this template use File | Settings | File Templates.
  attr_accessor :text
  attr_accessor :content_type
  def initialize(text, content_type)
    @text = text
    @content_type = content_type
  end

end