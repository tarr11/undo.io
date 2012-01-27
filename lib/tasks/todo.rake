require 'DropboxNavigator'
namespace :todo do


  task :testrecurse => :environment do
    DropboxNavigator.getChangedFiles User.first
  end

  task :testtodo=> :environment do
    DropboxNavigator.Sync User.first
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

    DropboxNavigator.SyncAll

  end

  task :dailyemail => :environment do

    User.all.each do |user|
      summary = user.task_folder("/").get_summary(Time.zone.now.beginning_of_day - 1.days, Time.zone.now)
      if summary.length == 0
        next
      end
      puts user.email

      msg = UserMailer.daily_email(user, summary).deliver
      puts msg.encoded
    end

  end
end
