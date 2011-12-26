class UserMailer < ActionMailer::Base

  default :from => "todo@douglastarr.com"
   
    def daily_email(user)
      @user = user
      @url  = "http://young-cloud-4159.herokuapp.com"
      @tasks = user.tasks.all
      mail(:to => user.email, :subject => "Daily Todo List")
    end


end
