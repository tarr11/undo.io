class FileComparer


  # a revision-aware file comparer
  # scenarios:
  # comparing two unrelated files
  # comparing files where one file was copied from the other so we can keep track of changes


  def initialize(compare_from, compare_to)
    @compare_from = compare_from
    @compare_to  = compare_to
    @diffs = []
    compare
  end

  def is_related?
    return @is_related
  end

  def compare

    @merge_error = false

    # source = baseline
    # destination = our changes
    # current = a newer version of destination
    # compare_from is a copy, comparing to against a revision of the master that it knew about (we may not have current changes)
    if @compare_from.copied_from == @compare_to
      @source = @compare_from
      @destination = @compare_from.copied_revision
      if @destination.nil?
        @destination = @compare_to
      end
      @current = @compare_from
      @is_related = true
    # compare_from is the master, looking at changes someone else made
    elsif @compare_from == @compare_to.copied_from
      @source = @compare_to.copied_revision
      if @source.nil?
        @source = @compare_from
      end
      @destination = @compare_to
      @current = @compare_from
      @is_related = true
    # neither are related, just assume there's not change between source and current
    else
      @source = @compare_from
      @destination = @compare_to
      @current = @compare_from
      @is_related = false
    end

    if @is_related
      compare_related
    else
      compare_unrelated
    end

  end

  def compare_unrelated
     # these files have no links, so we can't do anything smart
    dmp = DiffMatchPatch.new
    diffs = dmp.diff_main(@source.contents, @destination.contents)
    dmp.diff_cleanupSemantic(diffs)
    @diffs = diffs.map { |a|
          OpenStruct.new(
              :action=>a.first,
              :changes=>a.second
          )
        }


  end


  def is_different?
    return @diffs.select{|a| a.action != :equal}.length > 0
  end

  def diffs
    return @diffs
  end

  def merged_result
    return @merged_result
  end

  def merge_error?
    return @merge_error
  end

  def compare_related

    # one of these is copied from the other
    # find the change
    dmp = DiffMatchPatch.new
    dmp.patch_deleteThreshold=0.1
    patches = dmp.patch_make(@source.contents, @destination.contents)

    # push the change into current version
    begin
      merge_results = dmp.patch_apply(patches, @current.contents)
    rescue Exception
      @merge_error = true
      return nil
    end

    @merged_result  = merge_results.shift
    if merge_results.include?(false)
      @merge_error = true
      return nil
    end

    diff = dmp.diff_main(@current.contents, @merged_result)
    dmp.diff_cleanupSemantic(diff)

    # now compare the current version to my version
    @diffs = diff.map { |a|
      OpenStruct.new(
          :action=>a.first,
          :changes=>a.second
      )
    }


  end

  def todo
        # push the change into current version
    begin
      merge_results = dmp.patch_apply(patches, current_file_contents)
    rescue Exception
      @merge_error = true
      return nil
    end

    merged_contents = merge_results.shift
    if merge_results.include?(false)
      @merge_error = true
      return nil
    end

    diff = dmp.diff_main(current_file_contents, merged_contents)
    dmp.diff_cleanupSemantic(diff)

    # now compare the current version to my version
    mapped_diff = diff.map { |a|
      OpenStruct.new(
          :action=>a.first,
          :changes=>a.second
      )
    }

        # find the change
    dmp = DiffMatchPatch.new
    dmp.patch_deleteThreshold=0.1
    patches = dmp.patch_make(left_file_contents, right_file_contents)




  end

  def tokenize

    # convert this diff into a stream that can be parsed
    token = nil#{:token_type => :new_line, :tab_count => 0}
    left_padding = ""
    @diffs.each do |diff|

      token = {:token_type => :action_start, :diff_type => diff.action}
      yield token

      diff.changes.split("\n").each_with_index do |line,index|
        if index > 0 || (index == 0 && diff.changes.strip.blank?)
          token = {:token_type => :line_break}
          yield token
          todo_line = TodoLine.new
          todo_line.text = line
          token = {:token_type => :new_line, :tab_count => todo_line.tab_count}
          yield token
          left_padding = ""
        end

        unless line.blank?
          token = {:token_type => :text, :text => line }
          yield token
        else
          if diff.action == :insert
            left_padding += line
          end
        end

      end

      token = {:token_type => :action_end}
      yield token

    end
    token = {:token_type => :line_break}
    yield token


  end


end