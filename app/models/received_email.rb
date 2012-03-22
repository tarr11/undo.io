require 'active_model'
require 'active_support'
class ReceivedEmail
  include ActiveModel::Validations
  attr_accessor :from, :to, :body_plain, :body_stripped, :subject, :from_user, :to_user, :from_user_copy, :to_user_copy
  validates_presence_of  :from, :to, :body_plain, :body_stripped, :subject


  def self.extract_email(email_string)

    match = email_string.match(/<(?<email>.*)>/)
    unless match.nil?
      return match["email"]
    end
  end

  def from_email
    ReceivedEmail.extract_email(@from)
  end
  def to_email
    ReceivedEmail.extract_email(@to)
  end

  def reply_to_id
    match = self.body_plain.match(/reply_to_id:(?<id>[^\b]+)\b/)
    unless match.nil?
      return match["id"]
    end
    return nil
  end

  def process

    # find the user with this email

    Rails.logger.debug "DEBUG-EMAIL:" + self.to_email
    @from_user = User.find_by_email(self.from_email)
    @to_user = User.find_by_email(self.to_email)
    
    # send to someone who doesn't exist
    if @to_user.nil?
      return
    end
    # if this email doesn't exist, we create a new user with this email
    # they will have an "unvalidated" flag of some kind
    if @from_user.nil?
      return
      @from_user = User.create_anonymous(self.from_email)
    end
   
    # look for a thread-id somewhere (maybe in the headers or the footer)
    # if none, then create a new file
    # if exists, create as a reply
   
    unless self.reply_to_id.nil? 
      reply_to = TodoFiles.find_by_id(self.reply_to_id)
      unless reply_to.nil?
        # create a copy that the from user sent
        @from_user_copy = reply_to.get_copy_of_file(@from_user)        
        @from_user_copy.contents = self.body_plain
        # now share that with the new user
        @to_user_copy = from_user_copy.share_with(@to_user)
      end
    end

    # we couldn't find that one
    if @from_user_copy.nil?
      @from_user_copy = @from_user.build_note(subject, body_plain)
      @to_user_copy = @from_user_copy.share_with(@to_user)
    end
    Rails.logger.debug "DEBUG:NIL:" + self.from_user_copy.nil?.to_s
  end

  def create_anonymous_user(email)
    return nil
  end
end
