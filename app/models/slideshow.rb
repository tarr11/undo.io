class Slideshow
  # To change this template use File | Settings | File Templates.

  attr_accessor :slides
  attr_accessor :file

  def initialize(file)
    @file = file
    @slides = to_enum(:build_slides).to_a
  end

  def first_image
    @slides.each do |slide|
      if slide.images.length > 0
        return slide.images.first
      end
    end

    return nil

  end

  def get_events
    @slides.each do |slide|
      slide.get_events do |event|
        yield event
      end
    end
  end

  def build_slides

    # this thing iterates through all the lines and builds the slides
    # slides are a just a set of instructions for rendering a layout
    # it's really an AST but I can't bother to make that right now,
    # so let's hack the loop!
    # NOTE: DO NOT hire anyone who writes code like I am writing below

    current_slide = nil

    last_line = nil
    TodoFile.formatted_lines(@file.contents).each_with_index do |line, index|

      # first line is special, we initialize a new slide
      if index == 0
        last_line = line
        current_slide = Slide.new(self)
        next
      end

      # blank lines should be skipped past, since they forced a new slide
      if last_line.text.blank?
        last_line = line
        next
      end

      current_slide.add_line(last_line)

      # a new line with no parent means we are done
      if line.text.blank?
        current_slide.complete
        yield current_slide
        current_slide = Slide.new(self)
        last_line = line
        next
      end

      # a task with children that is not already part of a task slide demands a new slide
      if line.is_task && line.children.length > 0 && !current_slide.has_tasks
        current_slide.complete
        yield current_slide
        current_slide = Slide.new(self)
        last_line = line
        next
      end

      last_line = line
    end

    unless last_line.nil?
      unless last_line.text.blank?
        current_slide.add_line(last_line)
      end
    end

    unless current_slide.nil?
      unless current_slide.sections.length == 0
        current_slide.complete
        yield current_slide
      end
    end

  end
end
