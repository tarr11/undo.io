class UserFollow < ActiveRecord::Base

  belongs_to :user
  belongs_to :follow_user, :foreign_key=>"follow_user_id", :class_name=>"User"
  validates_uniqueness_of :follow_user_id, :scope => :user_id
  validates_presence_of :user, :follow_user
  after_create do 

    msg = FollowMessage.find_by_user_id_and_follow_user_id(self.user_id, self.follow_user_id)
    if msg.nil?
      FollowMessage.create :user_id=>self.user_id, :follow_user_id => self.follow_user_id
    end
  end
end
