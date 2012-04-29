class FollowMessage < ActiveRecord::Base
  belongs_to :user
  belongs_to :follow_user, :foreign_key=>"follow_user_id", :class_name=>"User"
  validates_uniqueness_of :follow_user_id, :scope => :user_id
  validates_presence_of :user, :follow_user
  attr_accessible :user_id, :follow_user_id

  after_create do 
    msg = UserMailer.follow_message(self.user, self.follow_user)   
    msg.deliver
  end
end
