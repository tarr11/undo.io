include ActionView::Helpers::TextHelper

class UserMailer < ActionMailer::Base
   add_template_helper(TaskFolderHelper)

   def product_request_note(email, feedback)
     @email = email
     @feedback = feedback
     mail(:from=>"product-requests@undo.io", :to=>"douglas.tarr@gmail.com", :subject=>"Product request!")
   end

    def shared_note(from_user, to_user, file)
      @from_user =  from_user
      @to_user = to_user
      @file = file
      from =  from_user.username + "@" + EMAIL_REPLY_TO_DOMAIN 
      unless from_user.display_name.nil?
        from = from_user.display_name +  " <" + from + ">" 
      end
      mail(:from => from,:reply_to=>from, :to => to_user.email_or_unverified_email, :subject => file.shortName)
    end
    
    def reminder_note(from_user, events)
      @from_user =  from_user
      @to_user = from_user
      @events = events
      if @events.nil?
        raise 'no events'
      end
      from =  from_user.username + "@" + EMAIL_REPLY_TO_DOMAIN 
      unless from_user.display_name.nil?
        from = from_user.display_name +  " <" + from + ">" 
      end
      subject = "undo.io Reminder: You have " + pluralize(events.length, "event") + " soon" 
      mail(:from => from,:reply_to=>from, :to => from_user.email, :subject => subject)
    end

end

