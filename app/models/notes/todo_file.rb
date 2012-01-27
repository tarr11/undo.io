require 'DropboxNavigator'
require "iconv"
require 'diff/lcs'
require 'diff/lcs/array'

class TodoFile < ActiveRecord::Base

  belongs_to :user
#  has_many :todo_lines
  has_many :task_file_revisions

  after_save :save_revision
  attr_accessor :path
  serialize :diff

  searchable do
    text :contents, :stored => true
    text :filename, :stored => true
    time :revision_at
    integer :user_id
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
    DropboxNavigator.DeleteFileInDropbox user, filename
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
    previous = self.task_file_revisions.last
    unless (previous.nil?)
      arrayA = previous.contents.split("\n")
      arrayB = self.contents.split("\n")
      diff = getLcsDiff(arrayA, arrayB)
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
      diff = getLcsDiff(arrayA, arrayB)
      revision.diff = diff
    end
    revision.save

  end

  def saveFromWeb(todofileParams)

    if self.update_attributes!(todofileParams)
      DropboxNavigator.UpdateFileInDropbox(self)
      return true
    else
      return false
    end

  end

  def getLcsDiff(arrayA, arrayB)

#    return nil
   return Diff::LCS::diff(arrayA, arrayB)
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
      diff = getLcsDiff(arrayA, arrayB)

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
            :changedLines => addedLines
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

    all_tasks = false
    if line.lstrip.downcase.include?("!")
      all_tasks = true
    end

    if (line.nil?)
      return
    end

    i = 1
    task = nil
     while (line = reader.gets)
       i = i + 1

       new_task  = ((line.lstrip.downcase.include?("!") || all_tasks) &&  # task marker
            (!line.starts_with?("\t") && !line.starts_with?("  ")) && # not part of another task
            !line.blank?)

       if (new_task && !task.nil?)
         yield task
         task = nil
       end

       if new_task
           task = Task.new
           task.title = line.strip.sub("!","")
           task.file = self
           task.line_number = i
           task.lines = []
           if task.title.starts_with?("x")
                task.completed = true
           end
         elsif (!task.nil? && (line.starts_with?("\t") || line.starts_with?("  ")))
             task.lines.push line.strip
         end
     end
    if !task.nil?
      yield task
    end
  end

  def summary
    if (self.notes.nil?)
      return [""]
    end
    reader = StringIO.new(self.contents)
    return [reader.gets]
  end

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

    # there's prb some more elegant way to cache data, it's not thread-safe anyway
    if !@lines.nil?
      return @lines
    end

    @lines = []
    self.get_lines do |line|
      @lines.push line
    end

    previous = nil
    @lines.each do |line|

      if line.tab_count == 1 && !previous.nil? && previous.tab_count == 0
        previous.line_type = :outline_header
      end
      previous = line

    end
    first_line = @lines.first
    if (!first_line.nil? && !first_line.blank?)
      first_line.line_type = :document_title
    end
    return @lines

  end

  def get_person_notes

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
        todo_line.tab_count = TodoFile.get_tab_count(line)
        todo_line.line_number = line_number
        line_number += 1
        yield todo_line
    end

  end

  def self.get_tab_count(line)
    # each tab counts as 1 tab for now
    # 4 spaces count as a tab

    tab_count = 0
    space_count = 0
    line.each_char{ |c|
      if c == "\t"
        if space_count > 0
          tab_count += (space_count / 4).to_i
          space_count = 0
        end
        tab_count += 1
      elsif c == " "
        space_count += 1
      else
        # stop when we hit a non-whitespace character
        if space_count > 0
          tab_count += (space_count / 4).to_i
        end
        break
      end
    }

    return tab_count

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

=begin
  def self.pushChanges(user, newFile)

    #   newFile = TodoFile.importFile(newFileName, user)
    oldFile = user.todo_files.where(["filename=? and id <> ?", newFile.filename,newFile.id]).order("revision_at DESC").first

    if (!oldFile.nil?)
      puts "Deleted"

      TodoFile.App
      deleted = TodoFile.compareFiles(oldFile, newFile)
      deletedGuids = deleted.map do |line|
        line.guid
      end

      user.tasks.where([ "client_id in (?)", deletedGuids ]).delete_all
      deleted.map do |line|
        puts line.line
      end

    end

    puts "Inserted"
    inserted = TodoFile.compareFiles(newFile, oldFile)

    inserted.each do |line|
      newTask = user.tasks.new  
      newTask.task = line.line
      newTask.client_id = line.guid
      newTask.save
      puts line.line 
    end
  end                                    f

  def self.pushChangesFromTwoFiles(user, oldFile, newFile)
    
    deleted = TodoFile.compareFiles(oldFile, newFile)
    inserted = TodoFile.compareFiles(newFile, oldFile)

    deletedGuids = deleted.map do |line|
      line.guid
    end

    user.tasks.where([ "client_id in (?)", deletedGuids ]).delete_all

    inserted.each do |line|
      newTask = user.tasks.new  
      newTask.task = line.line
      newTask.client_id = line.guid
      newTask.save
    end
=end


end
