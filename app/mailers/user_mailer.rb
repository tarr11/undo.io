class UserMailer < ActionMailer::Base
   add_template_helper(TaskFolderHelper)

    def shared_note(from_user, to_user, file)
      @from_user =  from_user
      @to_user = to_user
      @file = file
      from =  from_user.username + "@" + EMAIL_REPLY_TO_DOMAIN 
      unless from_user.display_name.nil?
        from = from +  " <" + from_user.display_name + ">" 
      end
      mail(:from => from,:reply_to=>from, :to => to_user.email_or_unverified_email, :subject => file.shortName)
    end

end

