class UserMailer < ActionMailer::Base
   add_template_helper(TaskFolderHelper)

    def shared_note(from_user, to_user, file)
      @from_user =  from_user
      @to_user = to_user
      @file = file
      mail(:from => from_user.email,:reply_to=>from_user.username + "@" + EMAIL_REPLY_TO_DOMAIN , :to => to_user.email_or_unverified_email, :subject => file.shortName)
    end

end

