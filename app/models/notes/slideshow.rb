class Notes::Slideshow
  # To change this template use File | Settings | File Templates.

  attr_accessor :slides
  def initialize(file)
    @file = file
    @slides = to_enum(:build_slides).to_a
  end

  def build_slides

    # this thing iterates through all the lines and builds the slides
    # slides are a just a set of instructions for rendering a layout
    # it's really an AST but I can't bother to make that right now,
    # so let's hack the loop!
    # NOTE: DO NOT hire anyone who writes code like I am writing below

    current_slide = nil

    last_line = nil
    @file.formatted_lines.each_with_index do |line, index|

      # first line is special, we initialize a new slide
      if index == 0
        last_line = line
        current_slide = Notes::Slide.new
        next
      end

      # blank lines should be skipped past, since they forced a new slide
      if last_line.text.blank?
        last_line = line
        next
      end


      if current_slide.nil?
        current_slide = Notes::Slide.new
        current_slide.add_line(last_line)
        # TODO: check if this line is just a link
        # if so, the title is probably something related to whatever it links to
        last_line = line
        next
      end

      current_slide.add_line(last_line)

      # a new line with no parent means we are done
      if line.parent.nil?  || line.text.blank?
        current_slide.complete
        yield current_slide
        current_slide = nil
        last_line = line
        next
      end

      # a task with children that is not already part of a task slide demands a new slide
      if line.is_task && line.children.length > 0 && !current_slide.has_tasks
        current_slide.complete
        yield current_slide
        current_slide = nil
        last_line = line
        next
      end

      last_line = line
    end

    unless current_slide.nil?
      current_slide.add_line(last_line)
      current_slide.complete
      yield current_slide
    end

  end
end