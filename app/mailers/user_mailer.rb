class UserMailer < ActionMailer::Base

  default :from => "notes@undo.io"
  default_url_options[:host] = "undo.io"
   
    def daily_email(user, summary)
      @user = user
      @summary = summary
      @only_path = false
      mail(:to => user.email, :subject => "Your daily notes")
    end


end
