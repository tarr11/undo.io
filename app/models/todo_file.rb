require 'DropboxNavigator'
require "iconv"
require 'diff/lcs'
require 'diff/lcs/array'

class TodoFile < ActiveRecord::Base

  belongs_to :user
  belongs_to :copied_from, :class_name => "TodoFile", :foreign_key => "copied_from_id"
  belongs_to :thread_source, :class_name => "TodoFile", :foreign_key => "thread_source_id"
  belongs_to :reply_to, :class_name => "TodoFile", :foreign_key => "reply_to_id"

  has_many :task_file_revisions
  has_many :copied_to, :class_name => "TodoFile", :foreign_key => "copied_from_id"
  has_many :shared_with_users, :through => :shared_files, :source=>:user
  has_many :shared_files
  has_many :suggestions

  validates_inclusion_of :is_public, :in => [true, false]
  validates_presence_of :filename,  :user_id, :file_uuid, :edit_source, :revision_at
  validates_uniqueness_of :filename, :scope => :user_id, :case_sensitive => false
  validates_uniqueness_of :file_uuid
  
  # filename can't be "/"
  validates :filename, :exclusion => { :in =>["/"], 
    :message => "Filename %{value} is reserved." }
  attr_accessible :filename, :contents, :is_public, :edit_source
  attr_accessor :changed_lines
  after_save :save_revision, :update_dropbox
  serialize :diff
  before_validation :set_revision_at
  
  before_validation do
    self.file_uuid = UUIDTools::UUID.timestamp_create().to_s
  end


  def set_revision_at
    if self.edit_source == 'web'
      self.revision_at = Time.now.utc
    end
  end

  searchable do
    text :contents, :stored => true
    text :filename, :stored => true
    time :revision_at
    integer :user_id
    boolean :is_public
  end
  handle_asynchronously :solr_index, :queue => 'solr'
  handle_asynchronously :remove_from_index, :queue => 'solr'


  def in_reply_to
    # our note, that this note is in reply to
    # user1.note -> user2.read_only_copy -> user2.writable_copy -> user1.reply
    # this should find user1.note from user1.reply

    # there are 3 cases
    # 1 - this was not copied from anything, return nil
    if self.reply_to.nil?
      return nil
    end
    # 2 - copied from another of our files, return that
    if !self.copied_from.nil? && self.copied_from.user_id == self.user_id
      return self.copied_from
    end
    # 3 - copied from someone else's file.  the idea here is that
    # we *may* have a copy of whatever they were replying to here
    # so we try and find it in our files
    # that we own, we can show that
    if !self.copied_from.nil? && self.copied_from.user_id != self.user_id
      reply = self.copied_from.reply_to
      # this is not a reply to anything
      if reply.nil?
        return nil
      end 
      
      # direct reply
      if reply.user_id == self.user_id
        return reply
      end
      # maybe something we were copied on
      our_copy = self.user.todo_files.find_by_reply_to_id(reply.id)
      unless our_copy.nil?
        return our_copy
      end
      
    end

    return nil

  end

  
  def move(new_filename)

      oldName = self.filename
      self.filename = self.user.suggest_filename(new_filename)
      return self.save!

  end

  def current_revision
	task_file_revisions.last
  end

  def get_copy_of_file(user)

	# copy from_user.file1 to to_user.file2
		
 	# REPLY: If file1 is a copy of something to_user wrote, put the reply under /to_user/file1.copied_from.filename/replies
		# filename does not include reply
		# like username, there's a special column for the replies
		# /[username]/path...path/[replies]
		# todo_file = [user_id, path, reply_from_user_id, reply_number]
		# file.copied_to(user).filename/replies/from_user/[n]
			# ie., /doug/path/to/file/replies/jamy
			# link that file to this one
			# if this file exists, there may be multiple replies, we use the same logic as above to name it
				# /doug/path/to/file/replies/jamy/2
		# if this is a reply, to a reply, etc, it could be replying in the inbox etc
			# /jamy/inbox/doug/path/to/file/replies/doug
		# or it could be somewhere else if the linked file was moved
			# /jamy/my/path/to/file/replies/doug

	# FORWARDED: if file1 is a copy of file of by someone else, look to see if to_user already has that file 
		# treat this as a reply to that note (append as a reply)
			# Step1: doug creates file
				# /doug/path/to/file
			# Step2: doug sends to jamy, julie
				# /jamy/inbox/doug/path/to/file
				# /julie/inbox/doug/path/to/file
			# Step3: julie forwards to elijah
				# /elijah/inbox/doug/path/to/file/replies/julie
			# Step4: jamy moves file
				# /jamy/new/path/here
			# Step5: elijah replies to julie, adds in jamy and doug
				# /julie/doug/path/to/file/replies/elijah
				# /jamy/new/path/here/replies/elijah
				# /doug/path/to/file/replies/elijah
			# Step6: doug replies to eli, julie, jamy
				# /elijah/inbox/doug/path/to/file/replies/doug
				# /julie/inbox/doug/path/to/file/replies/doug
				# /jamy/new/path/here/replies/doug
			# Step7: doug replies again to eli, julie, jamy
				# /elijah/inbox/doug/path/to/file/replies/doug/2
				# /julie/inbox/doug/path/to/file/replies/doug/2
				# /jamy/new/path/here/replies/doug/2
						
		# file1.copied_from.find_copied_to_by_user_id(user2.user_id)
		# /julie/inbox/doug/path/to/file/replies/jamy

	# SEND: If file1 is not a copy of file2, we put this file in /user/inbox/from_user/filename by default
		# ie., /jamy/inbox/doug/path/to/file

	# we do not overwrite files, we create another
		# /jamy/inbox/doug/path/to/file/2
		# /jamy/inbox/doug/path/to/file/3
		# this new file is linked back to the original file


	# there are two links backwards
	# one is the direct copied_from link, where this file was copied directly from
	# this is used for seeing changes
	# the other is the original source.  This determines where the note is placed (the "thread")
	# this is just a cached file, and can be recalculated by walking the tree back to the source
	# if that file exists, we append a number to it, until we can find one that doesn't exist
  new_file = user.todo_files.new
  new_file.copied_from = self
  new_file.contents = self.contents
  new_file.is_public = false
  new_file.edit_source = "web"
  if user != self.user
    new_file.is_read_only = true
    new_file.reply_to = self
  else
    # if you are copying your own file, you don't want to reply to yourself, you want to reply to whomever sent it
    new_file.reply_to = self.reply_to
  end
  
  unless self.thread_source.nil?
    # see if this user already has a file from this thread
    original_source = user.todo_files.find_by_id(self.thread_source.id)
    # from the original source
    unless original_source.nil?
      user_thread_source = original_source
    else
      user_thread_source = user.todo_files.find_by_thread_source_id_and_reply_number(self.thread_source_id,0)
    end
  end

  if user_thread_source.nil?
    new_file.filename = user.suggest_filename("/inbox/" + self.user.user_folder_name + self.filename)
    new_file.thread_source = self
    new_file.reply_number = 0
  else
    replies = user_thread_source.replies
    # There is probably a race condition RIGHT HERE (reply_number is a bad idea)
    # I chose to ignore that fact while developing this code, as it is not that big of a deal right now 
    if replies.length > 0
      reply_number = replies.sort_by{|a| a.reply_number}.reverse.first.reply_number + 1
    else
      reply_number = 1
    end 
    new_file.filename = user.suggest_filename(user_thread_source.filename + "/replies/" + self.user.user_folder_name + "/reply-" + reply_number.to_s)
    new_file.reply_number = reply_number
    new_file.thread_source = self.thread_source
  end

    return new_file

			
  end

  def sent_to
    sent_copies.map{|a| a.user}.uniq
  end

  def sent_copies    
    TodoFile.where(:copied_from_id => self.id).select{|a| a.user_id != self.user_id}
  end
  
  def was_sent_to_other_user?
    return sent_copies.length > 0
  end

  def self.is_email?(address)

    return address.include?('@')

  end

  def self.get_user_by_username_or_email(person)
    
    if TodoFile.is_email?(person)
      user = User.find_by_email(person)
      unless user.nil?
        return user
      end      
      user = User.find_by_unverified_email(person)
      return user
    end 
    user = User.find_by_username(person)
    return user

  end

  def share_with_person(person)
    user = TodoFile.get_user_by_username_or_email(person)
    if user.nil?
      if TodoFile.is_email?(person)
        user = User.create_anonymous_user(person)
      end
    end
    unless user.nil?
      return share_with(user)
    end
    return nil
  end

  def share_with(user)
   
	# create a new copy each time
    new_file = get_copy_of_file(user)
    new_file.save!
    user.alerts.create! :message => SharedNoteAlert.new 
    if user.allow_email
      msg = UserMailer.shared_note(self.user, user, new_file)
      msg.deliver
    end
    return new_file
  end

  def user_who_wrote_this

    if self.is_read_only? && !self.copied_from.nil?
      return self.copied_from.user
    end

    return self.user

  end
  def unshare_with(user)
    shared_file = user.shared_files.find_by_todo_file_id(self.id)
    shared_file.destroy()
  end

  def copied_revision
    unless copied_task_file_revision_id.nil?
      copied_from.task_file_revisions.find_by_id(copied_task_file_revision_id)
    end
  end
  def all_copies
    return self.copied_to.map{|a| a}
  end

  def other_people_copies
    return all_copies.select {|a| a.user.id != self.user.id}
  end

  def replies
    unless thread_source.nil?
      self.user.todo_files.where(:thread_source_id=>self.thread_source_id).select{|a| a.id != self.id}
    else
      self.user.todo_files.where(:thread_source_id=>self.id).select{|a| a.id != self.id}
    end
  end

  def new_replies
    replies.each do |reply|
      reply.shared_files.find_by_user_id(self.user_id)
    end
  end

  def is_copied?
    return !copied_from.nil?
  end

  def was_sent?
    
  end
  def has_replied?
    unless self.copied_from.nil?
      unless self.shared_with_users.select{|a| a.id == copied_from.user_id}.length == 0
        return true
      end
    end
    return false
  end

  def merge(base_file, new_file, current_file)

      dmp = DiffMatchPatch.new
      dmp.patch_deleteThreshold=0.1
      patches = dmp.patch_make(base_file, new_file)
      return dmp.patch_apply(patches, current_file).first

  end

  def accept(compare_file)

    if compare_file.copied_from_id == self.id
      self.contents = merge(compare_file.copied_revision.contents, compare_file.contents, self.contents)
      self.save
      compare_file.copied_task_file_revision_id = self.current_revision.id
    elsif self.copied_from_id == compare_file.id
      self.contents = merge(self.copied_revision.contents, compare_file.contents,  self.contents)
      self.save
      compare_file.copied_task_file_revision_id = self.current_revision.id
    end
    # merges the changes from compare_file into the current file, and marks the compare_filed share as viewed
    compare_file.save

  end

  def send_reply()
    # shares this version back to the original owner
    original_user = copied_from.user
    shared_item = original_user.shared_files.find_by_todo_file_id(self.id)
    if shared_item.nil?
      original_user.shared_files.create! :todo_file => self
    end
    original_user.alerts.create! :message => ReplyAlert.new
    if original_user.allow_email
      msg = UserMailer.shared_note(self.user, original_user, self)
      msg.deliver
    end
  end

  def copy(user, filename, revision_uuid)

    raise "revision_uuid cannot be nill" if revision_uuid.nil?

    new_file= user.todo_files.new
    new_file.filename = filename
    new_file.contents = self.contents
    new_file.user = user
    new_file.is_public = false
    new_file.copied_from_id = self.id
    new_file.edit_source = self.edit_source
    revision = self.task_file_revisions.find_by_revision_uuid(revision_uuid)
    if revision.nil?
      raise "No Revision"
    end
    new_file.copied_task_file_revision_id = revision.id
    return new_file

  end

  def make_public()
      update_attributes!(:is_public=>true, :published_at=> DateTime.now.utc)
  end

  def make_private()
      update_attributes!(:is_public=>false)
  end

  def slideshow
    return Slideshow.new(self)
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

      update_attributes!(:contents=>new_file)
  end

  def self.saveFile(user, filename, file, revisionDate, revisionCode)
    # TODO: refactor this
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
    revision.revision_uuid = UUIDTools::UUID.timestamp_create().to_s
    revision.edit_source = self.edit_source
    unless (previous.nil?)
      arrayA = previous.contents.split("\n")
      arrayB = self.contents.split("\n")
      diff = TodoFile.getLcsDiff(arrayA, arrayB)
      revision.diff = diff
    end
    revision.save


  end

  def update_dropbox
    unless self.edit_source == 'dropbox' 
      DropboxNavigator.delay(:queue=>'dropbox').UpdateFileInDropbox(self)
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

     if (line.nil?)
      return
    end

    i = 1
    task = nil
    parent_line = nil
    prev_line = nil
     TodoFile.formatted_lines(self.contents).each do |line|
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

  def get_undo_links
    self.contents.scan(/\/[\S]+\S/)
  end

 def get_linked_files
    files = get_undo_links.map do |filename|
      TaskFolder.get_file_from_path filename
    end

    files.select{|a| !a.nil?}
  end

  def self.formatted_lines(text_to_format)

    # create a directed graph of the document

    lines = []
    self.get_lines(text_to_format) do |line|
      lines.push line
    end

    stack = []
    lines.each do |line|

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

    first_line = lines.first
    if (!first_line.nil? && !first_line.blank?)
      first_line.line_type = :document_title
    end
    return lines

  end


  def get_events
    events = self.slideshow.to_enum(:get_events).to_a
  end

  def get_event_notes_old
    # copy/paste from get_person_notes
    # forgive me, future me!
    last_tab_count = 0
    note = nil

    TodoFile.formatted_lines.each do |line|
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
    TodoFile.formatted_lines(self.contents).each do |line|

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
    TodoFile.formatted_lines(self.contents).each do |line|
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

  def get_lines_from_content
    TodoFile.get_lines self.contents do |line|
      yield line
    end 
  end

  def self.get_lines(text_to_split)

    if (text_to_split.nil?)
      return
    end

    reader = StringIO.new(text_to_split)
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

  def self.format_replacement_content(suggestion)

    content = suggestion.replacement_content
    original_content = suggestion.task_file_revision.contents[suggestion.start_pos..suggestion.start_pos + suggestion.content_length]
#    parts = suggestion.replacement_content.split("\n")
    html = "<div class='hide suggestion-parent' username='" + suggestion.user.username + "'>"
    html += "<div class='compare-header'>Original</div>"
    html += "<div class='original-content'>"
    html += original_content
    html += "</div>"
    html += "<div class='compare-header'>New</div>"
#    if parts.length <= 1 
      html += "<div class='suggestion-content'>" + suggestion.replacement_content + "</div>"
#    else
#      html += "<div class='suggestion-content'>" + parts[0] + "</div>"
#      (1..parts.length).each do |index|
#        unless parts[index].nil?
#          html += "<div class='break-line suggestion-content'>"
#          html += parts[index]
#          html += "</div>"
#        end
#      end 
#    end
    html += "</div>"
    return html 
  end

  def self.apply_suggestions(text, suggestions)
    suggestions = suggestions.sort_by{|a| a.start_pos}
    suggestion = suggestions.shift
    pos = 0
    final_doc = ""
    line_num = 0
    suggestion_number = 0
    text.each_char do |char|
      while !suggestion.nil? &&  suggestion.start_pos == pos do
        final_doc += "<div id='suggestion-marker-" + suggestion.id.to_s + "' class='suggestion hide'><i class='toggle-suggestion icon-comment' suggestion-id='" + suggestion.id.to_s + "'></i></div>"
        suggestion = suggestions.shift
        suggestion_number += 1
      end
     final_doc += char
     pos += 1
 #    if char == "\n"
 #       # marker for lines on html
 #       final_doc += "<span style='display:none;' line-number='" + line_num.to_s + "'></span>"
 #       line_num += 1
 #     end
 
    end
    return final_doc

  end

  def get_snippet_around(text, max_lines)

    lines = []

    formatted_lines = TodoFile.formatted_lines(self.contents).to_a
    formatted_lines.each do |line|
      if lines.length > max_lines
        break
      end

      if lines.length > 0 && !line.text.strip.blank?
        lines.push line
      end

      if line.text.downcase.match(text.downcase)
        lines.push line 
      end
    end

    if lines.length == 0
      lines = formatted_lines.first(max_lines).to_a
    end
    return lines
  end

  def get_related_tag_notes

      tags = []
      # get a list of people, and all the notes that they are in

      these_tags = []
      self.get_tag_notes do |note|
        note.tags.each do |tag|
          these_tags.push tag
        end
      end

      these_tags = these_tags.uniq

      user.task_folder("/").get_tag_notes do |note|
        if note.file.filename == self.filename
          next
        end

        note.tags.each do |tag|
          unless these_tags.include?(tag)
            next
          end

          tags.push OpenStruct.new(
            :tag=> tag,
            :file => note.file
          )
        end

      end

      tags = tags.uniq{|a| [a.tag, a.file]}
      related_tags = tags.group_by {|group| group.tag}
      return related_tags

  end
end
