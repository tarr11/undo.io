Factory.define :user do |user|
  user.display_name          "Douglas Tarr"
  user.email                 "doug@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.username              "doug"
end

Factory.define :user2, :class=>User do |user|
  user.display_name          "J'Amy Tarr'"
  user.email                 "jamy@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.username              "jamy"
end

Factory.define :user3, :class=>User do |user|
  user.display_name          "Elijah Tarr'"
  user.email                 "eli@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.username              "elijah"
end

Factory.define :file do |file|
  file.filename   "/foo"
  file.contents   "This is a file."
  file.is_public  false
end