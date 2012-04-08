class TeamProductRequest < ActiveRecord::Base
  attr_accessible  :email, :feedback
  validates_presence_of :email

  after_save :send_email

  def send_email
    msg = UserMailer.product_request_note( email, feedback)
    msg.deliver
  end

end
