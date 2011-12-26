namespace :todo do

  task :import => :environment do

    user = User.first
    filename = "/home/douglastarr/dev/todo/sample.txt"
    todo = TodoFile.new
    todo.importFile filename, user

  end

  task :dump => :environment do
    user = User.first.todo_files.each do |file|
      file.todo_lines.each do |line|
        puts line.guid.to_s
      end
    end
  end

  task :compare => :environment do
    user = User.first
    filename1 =  "/home/douglastarr/dev/todo/sample.txt" 
    filename2 =  "/home/douglastarr/dev/todo/sample2.txt"
    file1 = TodoFile.importFile(filename1, user)
    file2 = TodoFile.importFile(filename2, user)

    TodoFile.compareFiles file1, file2
  end

  task :push => :environment do
    user = User.first
    filename1 =  "/home/douglastarr/dev/todo/sample.txt" 
#    file1 = TodoFile.importFile(filename1, user)

    TodoFile.pushChanges user, filename1
  end

  task :delete => :environment do
    User.first.todo_files.each do |file|
      file.todo_lines.delete_all
    end

    User.first.tasks.delete_all
  end

  task :dbdelete  => :environment do

      ConsumerToken.delete_all
  end

  task :dropbox => :environment do
    
    User.all.each do |user|
      if user.dropbox.nil?
        next
      end
      puts user.email 
      

      user.dropbox.client.metadata("/")['contents'].each do |fileinfo|
      
        filename = fileinfo['path']
        puts filename
        text = user.dropbox.client.get_file(filename)
        todo = TodoFile.pushChangesFromText user, filename, text
    
      end
    end

  end

  task :dailyemail => :environment do

    User.all.each do |user|
      if user.tasks.count == 0
        next
      end
      puts user.email
      UserMailer.daily_email(user).deliver
    end

  end
end
