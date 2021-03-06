class Slide
  # To change this template use File | Settings | File Templates.

  attr_accessor :slideshow
  attr_accessor :sections
  attr_accessor :has_tasks

  attr_accessor :images
  attr_accessor :links
  #attr_accessor :line
  #attr_accessor :all_lines
  #attr_accessor :links
  #attr_accessor :images

  def initialize(slideshow)
    @sections = []
    @slideshow = slideshow
#    add_line line
  end

  def complete
    @images = to_enum(:get_images).to_a
    @links = to_enum(:get_links).to_a
  end

  def title

    unless sections.first.slide_contents.first.nil?
      return sections.first.slide_contents.first.text
    end

    return "DUNNO"

  end

  def add_line(line)

    if line.is_task
      has_tasks = true
    end

    # lex and parse the line
    # links and images are items that are between word blobs
    # ! http://bla.com foo xxx http://bxx.fdk/jfdskal.jpg

    current_text = []
    line_sections = []
    line.get_cleaned_line().split(/\s/).each do |word|
      if word.strip.match(httpRegex)
        if current_text.length > 0
          line_sections.push SlideContent.new(current_text.join(" "),:text)
        end
          # TODO: use HTTP HEAD to really figure out what this thing is and then use content-type
        if word.end_with?("jpg","gif","png")
          line_sections.push SlideContent.new(word, :image)
        else
          line_sections.push SlideContent.new(word, :link)
        end
        current_text = []
      else
        unless word.blank?
          current_text.push word
        end
      end
    end

    if current_text.length > 0
        line_sections.push SlideContent.new(current_text.join(" "), :text)
    end

    @sections.push SlideSection.new(line_sections, line.is_task, line.get_level, line.has_children?)

  end

  def httpRegex
     /\bhttp[s]?:\/\/[^\s]+\b/
  end

  def get_events

    @sections.each do |section|
      section.slide_contents.each do |part|
        event =  Event.get_event(part.text, self.slideshow.file, self)
        unless event.nil?
          yield event
        end
      end
    end

     
  end

  def get_images
    @sections.each do |section|
      section.slide_contents.each do |part|
        if part.content_type == :image
          yield part.text
        end
      end
    end
  end

  def get_links
    @sections.each do |section|
      section.slide_contents.each do |part|
        if part.content_type == :link
          yield part.text
        end
      end
    end
  end

  #def initialize(line)
  #  @line = line
  #  @all_lines = []
  #  @all_lines.push @line
  #  self.lines_recursive(@line.children)
  #  @links = to_enum(:get_links).to_a
  #  @images = get_images.to_a
  #end
  #
  #def lines_recursive (children)
  #
  #  if children.nil?
  #    return
  #  end
  #
  #  children.each do |child|
  #    unless child.text.strip.blank?
  #      @all_lines.push child
  #    end
  #    lines_recursive child.children
  #  end
  #
  #end

  def slide_type
    # if there is only 1 or 2 children and that's it, it's a headline

    if @sections.length <= 3 && @images.length == 0
      return :headline
    end

    # if there is more than one task, it is a multi-task

    # if there is one task, it's a single task

    # if there is one pic, it's a single pic
    if @images.length == 1
      return :single_pic
    end

    # if there's a bunch of pics, it's a multi pic
    if @images.length > 1
      return :multi_pic
    end


    # otherwise, it's just a note

    return :note
  end

end
