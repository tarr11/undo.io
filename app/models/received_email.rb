require 'active_model'

class ReceivedEmail
  include ActiveModel::Validations
  attr_accessor :from, :to, :body_plain, :body_stripped, :subject
  validates_presence_of  :from, :to, :body_plain, :body_stripped, :subject

  def initialize(from, to, subject, body_plain, body_stripped)  
    self.from = from
    self.to = to
    self.body_plain = body_plain
    self.body_stripped = body_stripped
    self.subject = subject
  end  

  def from_email
    self.from.scan(/<.*>/).first
  end

  def to_email
    self.to.scan(/<.*>/).first
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

    from_user = User.find_by_email(self.from_email)
    to_user = User.find_by_email(self.to_email)
    
    # send to someone who doesn't exist
    if to_user.nil?
      return
    end
    # if this email doesn't exist, we create a new user with this email
    # they will have an "unvalidated" flag of some kind
    if from_user.nil?
      return
      from_user = User.create_anonymous(self.from_email)
    end
   
    # look for a thread-id somewhere (maybe in the headers or the footer)
    # if none, then create a new file
    # if exists, create as a reply
   
    unless self.reply_to_id.nil? 
      reply_to = TodoFiles.find_by_id(self.reply_to_id)
      unless reply_to.nil?
        # create a copy that the from user sent
        from_user_copy = reply_to.get_copy_of_file(from_user)        
        from_user_copy.contents = self.body_plain
        from_user_copy.save!
        # now share that with the new user
        to_user_copy = from_user_copy.share_with(to_user)
      end
    end

    # we couldn't find that one
    if from_user_copy.nil?
      from_user_copy = from_user.create_note(subject, body_plain)
      to_user_copy = from_user_copy.share_with(to_user)
    end
     
    # recipient gets notified 
    to_user_copy.notify

  end

  def create_anonymous_user(email)
    return nil
  end
end
