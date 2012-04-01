# Read about factories at https://github.com/thoughtbot/factory_girl

Factory.define :received_email do |email|
 email.from                 "User One <doug@example.com>"
 email.to                   "User Two <jamy@example.com>"
 email.subject              "Test Subject"
 email.body_plain           "This is a message\nsome more stuff\n --\nSome footer stuff\nMore Footer stuff"
 email.body_stripped        "This is a message\nsome more stuff\n --\nSome footer stuff\nMore Footer stuff"
end

Factory.define :reply_email, :class=>ReceivedEmail do |email|

 email.from                 "User One <doug@example.com>"
 email.to                   "User Two <jamy@example.com>"
 email.subject              "Test Subject"
  email.body_plain          "Really

On Sun, Apr 1, 2012 at 8:41 AM, Douglas Tarr
<doug@undo-staging.mailgun.org>wrote:

 Something
  Tabbed
    Third tab


"
   email.body_stripped          "Really

On Sun, Apr 1, 2012 at 8:41 AM, Douglas Tarr
<doug@undo-staging.mailgun.org>wrote:

 Something
  Tabbed
    Third tab


"
      
end
