Factory.define :user do |user|
  user.display_name          "Douglas"
  user.email                 "doug@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.username              "doug"
end

Factory.define :user2, :class=>User do |user|
  user.display_name          "J Tarr'"
  user.email                 "jamy@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.username              "jamy"
end

Factory.define :user3, :class=>User do |user|
  user.display_name          "Elijah'"
  user.email                 "eli@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.username              "elijah"
end
Factory.define :user_unverified, :class=>User do |user|
  user.unverified_email     "unverified+22@example.com"
  user.password              "foobar"
  user.password_confirmation "foobar"
  user.is_registered         false
  user.allow_email           true
end


Factory.define :file do |file|
  file.filename   "/foo"
  file.contents   "This is a file.\n! This is a task\nx! #recipe This is a completed task.\n This is a date 3/15/2012"
  file.edit_source  "web"
  file.is_public  false
end

Factory.define :file2, :class=>TodoFile do |file|
  file.filename   "/foo2"
  file.contents   "This is a different file.\n! This is a task\nx! #recipe This is a completed task.\n This is a date 3/15/2012"
  file.is_public  false
  file.edit_source  "web"
end

Factory.define :public_file, :class=>TodoFile do |file|
  file.filename   "/foo-public"
  file.contents   "This is a public file."
  file.is_public  true
  file.edit_source  "web"
end
Factory.define :dropbox_token do |token|

end

Factory.define :delta, :class=>Array do |delta|

end
