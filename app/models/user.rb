class User < ActiveRecord::Base

  include ::Apps

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:login]

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :time_zone, :username,:login

  attr_accessor :login

  validates_uniqueness_of :username, :email
  validates_presence_of :username, :password, :email

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

  def thumbnail
    if self.username == "tarr11"
      return "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-snc4/369783_599826078_209700476_q.jpg"
    else
      return "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-ash2/369935_717081119_1425821949_q.jpg"
    end
  end

  before_create :whitelisted

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
