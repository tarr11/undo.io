class TodoLine

  attr_accessor :text
  attr_accessor :tab_count
  attr_accessor :line_type

  def to_s
    self.text
  end
end
