class SlideSection
  # To change this template use File | Settings | File Templates.

  attr_accessor :slide_contents
  attr_accessor :is_task
  attr_accessor :level

  def has_children?
    return @has_children
  end

  def initialize(slide_contents, is_task, level, has_children)

    @slide_contents = slide_contents
    @is_task = is_task
    @level = level
    @has_children = has_children

  end
end