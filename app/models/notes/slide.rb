class Notes::Slide
  # To change this template use File | Settings | File Templates.

  attr_accessor :line
  attr_accessor :all_lines
  attr_accessor :links
  attr_accessor :images

  def httpRegex
     /\bhttp[s]?:\/\/[^\s]+\b/
  end

  def get_images
     @links.select{|a| a.end_with?("jpg","gif","png")}
  end

  def get_links
    @all_lines.each do |line|
      line.text.scan(httpRegex).each do |link|
        yield link
      end
    end
  end

  def initialize(line)
    @line = line
    @all_lines = []
    @all_lines.push @line
    self.lines_recursive(@line.children)
    @links = to_enum(:get_links).to_a
    @images = get_images.to_a
  end

  def lines_recursive (children)

    if children.nil?
      return
    end

    children.each do |child|
      unless child.text.strip.blank?
        @all_lines.push child
      end
      lines_recursive child.children
    end

  end

  def slide_type
    # if there is only 1 or 2 children and that's it, it's a headline

    if @all_lines.length <= 3 && @images.length == 0
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