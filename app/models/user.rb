class User < ActiveRecord::Base


  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, , :lockable, :timeoutable and :omniauthable
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :time_zone, :username,:login, :display_name, :allow_email

  attr_accessor :login

  with_options :if => :is_registered_user? do |user|
    user.validates_uniqueness_of :username, :email
    user.validates_presence_of :username, :email, :display_name
    user.validates_presence_of :password, :on => :create
    devise :registerable,:database_authenticatable,:confirmable,
            :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:login]

   
  end

  # user who hasn't registered, and came in via email
  with_options :if => :is_not_registered_user? do |user|
    user.validates_presence_of :unverified_email 
    user.validates_uniqueness_of :unverified_email
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
  has_many :task_file_revisions
  has_many :files_shared_with_user, :through => :shared_files, :source => :todo_file
  has_many :shared_files
  has_many :alerts
  attr_accessible :avatar
    has_attached_file :avatar, {
                      :styles => { :medium => "300x300>",
                                   :thumb => "100x100>" },
                      :default_url => "missing.png"
        }.merge(PAPERCLIP_STORAGE_OPTIONS)

  def thumbnail
  end

  before_create :whitelisted, :if => :check_whitelist?

  def active_for_authentication?
    super && is_registered_user? 
  end
  
  def email_required?
    return is_registered
  end 

  def inactive_message
    is_registered_user? ? super : :special_condition_is_not_valid
  end
 
  def check_whitelist?

     if is_not_registered_user?
       return false
     end
      if Rails.env.production?
        return true 
      end
      return false
  end 
  def is_production?
  end

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
    files = self.todo_files.where("filename like ?", filename).to_a
    if files.length == 0
      return filename
    end
    start_with = 1
    while (true)
      replacement_filename = filename + "_" + start_with.to_s
     unless files.include?(replacement_filename) 
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
      user.save!
      return user 
  end

  def task_folder (path="/")
    TaskFolder.new(self, path)
  end

  def file(filename)
    self.todo_files.find(:all, :conditions => ["filename = ?", "#{filename}"]).first
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
