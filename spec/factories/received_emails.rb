# Read about factories at https://github.com/thoughtbot/factory_girl

Factory.define :received_email do |email|
 email.from                 "User One <doug@example.com>"
 email.to                   "User Two <jamy@example.com>"
 email.subject              "Test Subject"
 email.body_plain           "This is a message"
 email.body_stripped        "This is a message"
end
