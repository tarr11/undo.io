class EmailController < ApplicationController
   skip_before_filter :verify_authenticity_token

   def post
     # process various message parameters:
     sender  = params['from']
     recipient = params['recipient']
     subject = params['subject']

     # get the "stripped" body of the message, i.e. without
     # the quoted part
     body_stripped = params["stripped-text"]
     body_plain = params["body-plain"]

     # process all attachments:
     count = params['attachment-count'].to_i
     count.times do |i|
       stream = params["attachment-#{i+1}"]
       filename = stream.original_filename
       data = stream.read()
     end
     @received_email = ReceivedEmail.new(sender, recipient, subject, body_plain, body_stripped) 
     @received_email.process
     render :text => "OK"

   end
end
