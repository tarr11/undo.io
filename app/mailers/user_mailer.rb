class UserMailer < ActionMailer::Base
   add_template_helper(TaskFolderHelper)

    def daily_email(user, summary)
      @user = user
      @summary = summary
      @only_path = false
      mail(:to => user.email, :subject => "Your daily notes")
    end

    def shared_note(from_user, to_user, file)
      @from_user =  from_user
      @to_user = to_user
      @file = file
      mail(:from => from_user.email, :to => to_user.email, :subject => file.shortName)
    end

end
