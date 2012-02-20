class UserMailer < ActionMailer::Base


    def daily_email(user, summary)
      @user = user
      @summary = summary
      @only_path = false
      mail(:to => user.email, :subject => "Your daily notes")
    end


end
