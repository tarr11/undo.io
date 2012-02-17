class Notes::SlideSection
  # To change this template use File | Settings | File Templates.

  attr_accessor :line_sections
  attr_accessor :is_task
  def initialize(line_sections, is_task)

    @line_sections = line_sections
    @is_task = is_task

  end
end