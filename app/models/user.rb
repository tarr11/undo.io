class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :time_zone

  has_many :client_applications
  has_many :tokens, :class_name => "OauthToken", :order => "authorized_at desc", :include => [:client_application]
  has_many :todo_files 
  has_many :tasks
  has_many :applications
  has_many :todo_lines

  has_one :task_folder
  has_one :dropbox, :class_name => "DropboxToken", :dependent => :destroy
  has_many :task_file_revisions

  before_create :whitelisted

  def whitelisted
      beta_user = BetaTester.find_by_email self.email
      if beta_user.nil?
        errors.add self.email, "is not on our invitation list"
      end
  end

  def task_folder (path="/")
    TaskFolder.new(self, path)
  end

  def file(filename)
    self.todo_files.find(:all, :conditions => ["filename = ?", "#{filename}"]).first
  end
end
