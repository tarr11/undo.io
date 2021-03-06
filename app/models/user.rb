class User < ActiveRecord::Base


  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, , :lockable, :timeoutable and :omniauthable
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :time_zone, :username,:login, :display_name, :allow_email, :allow_email_reminders
    devise :registerable,:database_authenticatable,:confirmable,
            :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:login]


  attr_accessor :login

  with_options :if => :is_registered_user? do |user|
    user.validates_uniqueness_of :username, :email, :case_sensitive => false
    user.validates_presence_of :username, :email, :display_name
    user.validates_presence_of :password, :on => :create
   
  end

  # user who hasn't registered, and came in via email
  with_options :if => :is_not_registered_user? do |user|
    user.validates_presence_of :unverified_email 
    user.validates_uniqueness_of :unverified_email, :case_sensitive => false
  end

  before_validation(:on => :create) do
    unless self.username.nil?
      self.is_registered = true
    end
  end
  has_many :client_applications
  has_many :tokens, :class_name => "OauthToken", :order => "authorized_at desc", :include => [:client_application]
  has_many :todo_files
  has_many :tasks
  has_many :applications
  has_many :todo_lines

  has_one :task_folder
  has_one :dropbox, :class_name => "DropboxToken", :dependent => :destroy
  has_one :dropbox_state
  
  has_many :task_file_revisions
  has_many :files_shared_with_user, :through => :shared_files, :source => :todo_file
  has_many :shared_files
  has_many :alerts
  has_many :suggestions
  has_many :user_follows

  attr_accessible :avatar
    has_attached_file :avatar, {
                      :styles => { :medium => "300x300>",
                                   :thumb => "100x100>" },
                      :default_url => "missing.png"
        }.merge(PAPERCLIP_STORAGE_OPTIONS)


  before_create :whitelisted, :if => :check_whitelist?
  before_create :set_defaults

  def set_defaults
  end

  def active_for_authentication?
    super && is_registered_user? 
  end

  def follows
    self.user_follows.map{|a| a.follow_user}
  end

  def is_following?(follow_user)
     !UserFollow.find_by_user_id_and_follow_user_id(self.id, follow_user.id).nil?
  end

  def unfollow(user_to_follow)
    followUser = UserFollow.find_by_user_id_and_follow_user_id(self.id, user_to_follow.id)
    followUser.destroy
  end
  
  def follow(user_to_follow)
    self.user_follows.create!(:follow_user_id => user_to_follow.id)
  end

  def email_required?
    return is_registered
  end 

  def inactive_message
    is_registered_user? ? super : :special_condition_is_not_valid
  end
 
  def check_whitelist?

    return false
=begin
       if is_not_registered_user?
       return false
     end
     
      if Rails.env.production?
        return true 
      end
      return false
=end
  end 

  
  #http://stackoverflow.com/questions/3802179/how-to-autobuild-an-associated-polymorphic-activerecord-object-in-rails-3
  def dropbox_state_with_build
    dropbox_state_without_build || build_dropbox_state
  end
  
  alias_method_chain :dropbox_state, :build

  def is_registered_user?
    return self.is_registered
  end

  def is_not_registered_user?
    return !self.is_registered
  end

  def email_or_unverified_email
    if is_not_registered_user?
      return self.unverified_email
    end
    return self.email
  end
   def self.find_for_database_authentication(warden_conditions)
     conditions = warden_conditions.dup
     login = conditions.delete(:login)
     where(conditions).where(["lower(username) = :value OR lower(email) = :value", { :value => login.strip.downcase }]).first
   end

  def whitelisted
      beta_user = BetaTester.find_by_email self.email
      if beta_user.nil?
        errors.add self.email, "is not on our invitation list"
        return false
      end
  end


  def suggest_filename(filename)
    # suggests a new file name to avoid collisions
    files = self.todo_files.where("lower(filename) like ?", filename.downcase + '%').to_a 
    if files.length == 0
      return filename
    end
    start_with = 1
    while (true)
      replacement_filename = filename + "-" + start_with.to_s
     if self.file(replacement_filename).nil?
       return replacement_filename
     end
     start_with += 1
    end
  end

  def build_note(subject, body)
    note = self.todo_files.new
    note.filename = suggest_filename("/" + subject)
    note.contents = body
    note.is_public = false
    return note

  end
  
  def user_folder_name
    if is_registered?
      return self.username
    else
      return self.unverified_email
    end
  end

  def self.create_anonymous_user(email)
      user = User.new 
      user.unverified_email = email
      # should probably find a non-hacky way to do this
      # if is_registered=false, they can't login, so it doesn't matter what this pwd is
      user.password = "123456"
      user.is_registered = false 
      user.skip_confirmation!
      user.allow_email = true
      user.allow_email_reminders = false
      user.save!
      return user 
  end

  def task_folder (path="/")
    TaskFolder.new(self, path)
  end

  def file(filename)
    self.todo_files.find(:all, :conditions => ["lower(filename) = ?", "#{filename.downcase}"]).first
  end

  def get_all_tags
    self.task_folder("/").to_enum(:get_tag_notes).to_a
  end

   protected

 # Attempt to find a user by it's email. If a record is found, send new
 # password instructions to it. If not user is found, returns a new user
 # with an email not found error.
 def self.send_reset_password_instructions(attributes={})
   recoverable = find_recoverable_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
   recoverable.send_reset_password_instructions if recoverable.persisted?
   recoverable
 end

 def self.find_recoverable_or_initialize_with_errors(required_attributes, attributes, error=:invalid)
   (case_insensitive_keys || []).each { |k| attributes[k].try(:downcase!) }

   attributes = attributes.slice(*required_attributes)
   attributes.delete_if { |key, value| value.blank? }

   if attributes.size == required_attributes.size
     if attributes.has_key?(:login)
        login = attributes.delete(:login)
        record = find_record(login)
     else
       record = where(attributes).first
     end
   end

   unless record
     record = new

     required_attributes.each do |key|
       value = attributes[key]
       record.send("#{key}=", value)
       record.errors.add(key, value.present? ? error : :blank)
     end
   end
   record
 end

 def self.find_record(login)
   where(["username = :value OR email = :value", { :value => login }]).first
 end
end
