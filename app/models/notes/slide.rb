class Notes::Slide
  # To change this template use File | Settings | File Templates.

  attr_accessor :line
  attr_accessor :all_lines

  def initialize(line)
    @line = line
    @all_lines = []
    @all_lines.push @line
    self.lines_recursive(@line.children)
  end

  def lines_recursive (children)

    if children.nil?
      return
    end

    children.each do |child|
      @all_lines.push child
      lines_recursive child.children
    end

  end

  def slide_type
    # if there is only 1 or 2 children and that's it, it's a headline


    if @all_lines.length < 3
      return :headline
    end

    # if there is more than one task, it is a multi-task

    # if there is one task, it's a single task

    # if there is one pic, it's a single pic

    # if there's a bunch of pics, it's a multi pic

    # otherwise, it's just a note

    return :note
  end

end