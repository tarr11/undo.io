require 'DropboxNavigator'
require "iconv"
require 'diff/lcs'
require 'diff/lcs/array'

class TodoFile < ActiveRecord::Base

  belongs_to :user
#  has_many :todo_lines
  has_many :task_file_revisions
  belongs_to :copied_from, :class_name => "TodoFile", :foreign_key => "copied_from_id"
  has_many :copied_to, :class_name => "TodoFile", :foreign_key => "copied_from_id"
  has_many :shared_with_users, :through => :shared_files, :source=>:user
  has_many :shared_files

  after_save :save_revision
#  attr_accessible :is_public, :contents

  serialize :diff

  searchable do
    text :contents, :stored => true
    text :filename, :stored => true
    time :revision_at
    integer :user_id
    boolean :is_public
  end
  handle_asynchronously :solr_index
  handle_asynchronously :remove_from_index

  validates_inclusion_of :is_public, :in => [true, false]
  validates_presence_of :revision_at, :filename, :contents, :user_id
  validates_uniqueness_of :filename, :scope => :user_id

  def all_copies
    return self.copied_to.map{|a| a}
  end

  def other_people_copies
    return all_copies.select {|a| a.user.id != self.user.id}
  end

  def replies
    other_people_copies.select{|a| a.is_public == true || a.shared_with_users.include?(self.user)}
  end


  def self.pushChangesFromText(user, filename, text, revisionDate, revisionCode)
    newFile = TodoFile.saveFile(user, filename, text,revisionDate, revisionCode)
    #TodoFile.pushChanges(user, newFile)
  end

  def self.deleteFile(user, filename)
    file = user.todo_files.find_by_filename(filename)
    file.destroy
  end

  def self.deleteFromWeb(user, filename)
    TodoFile.deleteFile user, filename
    DropboxNavigator.delay.DeleteFileInDropbox user, filename
  end
=begin
 =begin

 def save


    # also save revisions
    revision = self.task_file_revisions.new
    revision.filename = self.filename
    revision.contents = self.contents
    revision.user_id = self.user_id
    revision.save

  end

end
=end

  def reply()
    # shares this version back to the original owner
    original_user = copied_from.user
    original_user.shared_files.create! :todo_file => self
    original_user.alerts.create! :message => ReplyAlert.new

  end

  def make_public()
      saveFromWeb(:is_public=>true, :published_at=> DateTime.now.utc)
  end

  def make_private()
      saveFromWeb(:is_public=>false)
  end

  def mark_task_status(line_number, is_completed)

    i = 1
    new_file = ""
    reader = StringIO.new(self.contents.strip)
     while (line = reader.gets)
       # only lines that start with to do chars are considered todos

       if i == line_number
          if is_completed
            new_line = 'x ' + line
          else
            # remove an x from the beginning of the line
            new_line = line.gsub("^x","")
          end
       else
          new_line = line
       end
       new_file = new_file + new_line
       i = i+1
     end

    saveFromWeb(:contents=>new_file)
  end

  def self.saveFile(user, filename, file, revisionDate, revisionCode)

    utfEncodedFile = encodeUtf8(file)
    # save the curent file
    todofile = user.todo_files.find_or_initialize_by_filename(filename)
    todofile.contents = utfEncodedFile
    todofile.revision_at = revisionDate
    todofile.dropbox_revision = revisionCode
    previous = todofile.task_file_revisions.last
    unless (previous.nil?)
      arrayA = previous.contents.split("\n")
      arrayB = todofile.contents.split("\n")
      diff = TodoFile.getLcsDiff(arrayA, arrayB)
      todofile.diff = diff
    end

    todofile.save

    return todofile
  end

  def save_revision
   # also save revisions

    previous = self.task_file_revisions.last
    revision = self.task_file_revisions.new
    revision.filename = self.filename
    revision.contents = self.contents
    revision.user_id = self.user_id
    revision.revision_at = self.revision_at
    revision.dropbox_revision = self.dropbox_revision

    unless (previous.nil?)
      arrayA = previous.contents.split("\n")
      arrayB = self.contents.split("\n")
      diff = TodoFile.getLcsDiff(arrayA, arrayB)
      revision.diff = diff
    end
    revision.save

  end

  def saveFromWeb(todofileParams)

    if self.update_attributes!(todofileParams)
      DropboxNavigator.delay.UpdateFileInDropbox(self)
      return true
    else
      return false
    end

  end

  def self.getLcsDiff(arrayA, arrayB)

#    return nil
   return Diff::LCS::diff(arrayA, arrayB)
  end

  def self.getLcsDiff2(arrayA,arrayB)
    return Diff::LCS::sdiff(arrayA, arrayB)

  end

  def getChanges(startDate, endDate, all_revisions)
      revs = all_revisions.select {|a| a.todo_file_id == self.id && !a.revision_at.nil?}
        .sort_by{|a| a.revision_at}
        .reverse

      firstversion = revs.first


      if (firstversion.nil?)
          return []
      end

      if (revs.nil?)
        return []
      end


      nextRev = revs.select{|a| !a.revision_at.nil? && a.revision_at > startDate && a.revision_at < endDate}
                    .sort_by{|a| a.revision_at}
                    .reverse
                    .first

      if (!nextRev.nil?)
      # prev = first rev on a different day
      prevRev = revs.select{|a| !a.revision_at.nil? && a.revision_at < nextRev.revision_at.beginning_of_day}
                    .sort_by{|a| a.revision_at}
                    .reverse
                    .first

      end
      if (prevRev.nil?)
        prevContents = ""
      else
        prevContents = prevRev.contents
      end

      revision_at = endDate
      if (nextRev.nil?)
        # if there are no changes in the range, skip it
        return nil
      else
        nextContents = nextRev.contents
        revision_at = nextRev.revision_at
      end

      prevContents = TodoFile.encodeUtf8(prevContents)
      nextContents = TodoFile.encodeUtf8(nextContents)

      if (prevContents.nil? || nextContents.nil?)
        return nil
      end

      #diff = Diffy::Diff.new(prevContents, nextContents)
      arrayA = prevContents.split("\n")
      arrayB = nextContents.split("\n")
      diff = TodoFile.getLcsDiff(arrayA, arrayB)

      #lines = diff
      #        .map {|a| a.action + ' ' + a.element}

      addedLines = []
      diff.flatten.each{|a|
          if (a.action == "+")
            a.element.split('\n').each{|b|
                addedLines.push b
                }
          end
      }

      if addedLines.length > 0
         return {
            :file => self,
            :diff => diff,
            :revision_at => revision_at,
            :changedLines => addedLines.first(3)
         }
      else
        return nil

      end

  end

  def self.encodeUtf8(untrusted_string)
    if (untrusted_string.nil?)
      return nil
    end

    ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
    valid_string = ic.iconv(untrusted_string + ' ')[0..-2]

  end

  def get_tasks


    if (self.contents.nil?)
      return
    end

    reader = StringIO.new(self.contents.strip)

    # if the first line has a !, every non-blank,non-tabbed line is a task
    line = reader.gets

     if (line.nil?)
      return
    end

    i = 1
    task = nil
    parent_line = nil
    prev_line = nil
     formatted_lines.each do |line|
       i = i + 1

      is_task = line.is_task #stripped.match(taskRegex)
      completed_task = line.is_completed_task #stripped.match(completedtaskRegex)

      new_task = is_task || completed_task

       if (new_task && !task.nil?)
         yield task
         task = nil
       end

       if new_task
           task = Task.new
           if new_task
             task.title = line.get_cleaned_line
             if completed_task
               task.completed = true
             end
             task.parent = line.parent
             task.file = self
             task.line_number = i
             task.lines = []
           end
         elsif (!task.nil? && (line.text.starts_with?("\t") || line.text.starts_with?("  ")))
             task.lines.push line.text.strip
         end

     end
    if !task.nil?
      yield task
    end
  end

  #def summary
  #  if (self.notes.nil?)
  #    return [""]
  #  end
  #  reader = StringIO.new(self.contents)
  #  return [reader.gets]
  #end

  def name
    self.filename
  end

  def shortName
    self.filename.split("/").last
  end

  def path
    parts = self.filename.split("/")
    parts.pop
    parts.join("/") + "/"
  end

  def task_folder
    @task_folder = TaskFolder.new(self.user, path)
  end

  def formatted_lines

    # create a directed graph of the document
    if !@lines.nil?
      return @lines
    end

    @lines = []
    self.get_lines do |line|
      @lines.push line
    end

    stack = []
    @lines.each do |line|

        if stack.length == 0
          stack.push line
          next
        end

        if line.tab_count > stack.last.tab_count
          line.parent = stack.last
          stack.last.children.push line
          stack.push line
          next
        end

        while (true)
          if stack.length == 0
            break
          end
          next_item = stack.last
          if next_item.tab_count < line.tab_count
            line.parent = next_item
            next_item.children.push line
            break
          end
          stack.pop()
        end
        stack.push line

    end

    first_line = @lines.first
    if (!first_line.nil? && !first_line.blank?)
      first_line.line_type = :document_title
    end
    return @lines

  end

  def get_event_notes
    # copy/paste from get_person_notes
    # forgive me, future me!

    last_tab_count = 0
    note = nil

    formatted_lines.each do |line|
      line.created_at = self.revision_at
      event = line.get_event
      if !event.nil?
        if !note.nil?
          yield note
          note = nil
        end
        note = TodoLine.new
        note.event = event
        note.title = line
        note.line_number = line.line_number
        note.lines = []
        note.created_at = event.start_at
        last_tab_count = line.tab_count
        note.file = self
      elsif !note.nil? && line.tab_count > last_tab_count
        note.lines.push line
      elsif !note.nil?
        yield note
        note = nil
      end
    end

    if !note.nil?
      yield note
    end
  end


  def get_people
    these_peeps = []
    self.get_person_notes do |note|
      note.people.each do |person|
        these_peeps.push person
      end
    end

    return these_peeps.uniq

  end

  def get_person_notes(&block)

    last_tab_count = 0
    note = nil
    formatted_lines.each do |line|

      people = line.get_people.map{|a| a.downcase}
      if !people.nil? && people.length > 0
        if !note.nil?
          yield note
          note = nil
        end
        note = PersonNote.new
        note.people = people
        note.title = line
        note.line_number = line.line_number
        note.lines = []
        last_tab_count = line.tab_count
        note.file = self
      elsif !note.nil? && line.tab_count > last_tab_count
        note.lines.push line
      elsif !note.nil?
        yield note
        note = nil
      end
    end

    if !note.nil?
      yield note
    end

  end

  def get_tag_notes
    last_tab_count = 0
    note = nil
    formatted_lines.each do |line|
      tags = line.get_tags.map{|a| a.downcase}
      if !tags.nil? && tags.length > 0
        if !note.nil?
          yield note
          note = nil
        end
        note = TagNote.new
        note.tags = tags
        note.title = line
        note.line_number = line.line_number
        note.lines = []
        last_tab_count = line.tab_count
        note.file = self
      elsif !note.nil? && line.tab_count > last_tab_count
        note.lines.push line
      elsif !note.nil?
        yield note
        note = nil
      end
    end

    if !note.nil?
      yield note
    end

  end

  def get_lines

    if (self.contents.nil?)
      return
    end

    reader = StringIO.new(self.contents)
    prev_line = nil
    line_number = 1
    while (line = reader.gets)
      # only lines that start with to do chars are considered todos
        todo_line = TodoLine.new
        todo_line.text = line
        #todo_line.tab_count = TodoFile.get_tab_count(line)
        todo_line.line_number = line_number
        line_number += 1
        yield todo_line
    end

  end


  def latestNotes
    if (self.contents.nil?)
      return [""]
    end

    reader = StringIO.new(self.contents)
    last = Array.new
    while (line = reader.gets)
      # only lines that start with to do chars are considered todos
      if (!line.empty?)
        last.push line
      end
    end
    return last.last(3)

  end

  def self.importFile(filename, user)
    # import this file using File
    file = File.open(filename, 'r')
   end


  def self.compareFiles(base, compare)

    if (compare == nil)
      puts "compare=nil"
      return base.todo_lines.all
    end
  
   baselines = base.todo_lines.select do |line|
     line
  end

   comparelines = compare.todo_lines.select do |line|
     line
    end


    # find deleted lines - in old, but not new
    return baselines.select do |baseline|
     comparelines.all? do |compareline|
     #  puts baseline.line + ":" +  compareline.line

       baseline.line != compareline.line        
      
     end
    end    

  end



end
