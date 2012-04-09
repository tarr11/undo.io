require 'DropboxNavigator'
namespace :todo do


  task :testrecurse => :environment do
    DropboxNavigator.getChangedFiles User.first
  end

  task :testtodo=> :environment do
    doug = User.find_by_username('dougt')
    metadata = doug.dropbox.client.metadata("/")

  end

  task :dump => :environment do
    user = User.first.todo_files.each do |file|
      file.todo_lines.each do |line|
        puts line.guid.to_s
      end
    end
  end


  task :v5 => :environment do
    ActiveRecord::Base.record_timestamps = false
    User.all.each do |user|
      unless user.username.nil?
        user.is_registered = true
        user.allow_email = true
        user.save!
      end
    end
 end
  task :v5_files => :environment do
    TodoFile.all.each do |file|
      file.file_uuid = UUIDTools::UUID.timestamp_create().to_s
      if file.is_public.nil?
        file.is_public = false
      end
      if file.contents.blank?
        file.destroy
      else
        file.save!
      end
    end
 
  end

  task :delete => :environment do
    User.first.todo_files.each do |file|
      file.todo_lines.delete_all
    end

    User.first.tasks.delete_all
  end

  task :send_email_reminders => :environment do

    start_date = DateTime.now.utc
    end_date = start_date + 2.days
    User.all.each do |user|
      if user.allow_email && user.allow_email_reminders 
        Rails.logger.debug "trying to send reminder to " + user.email
        
        if user.task_folder.send_email_reminders start_date, end_date
          Rails.logger.debug "sent reminder to " + user.email
        else
          Rails.logger.debug "skipped reminder to " + user.email
        end
      end
    end

  end

  task :dbdelete  => :environment do

      ConsumerToken.delete_all

  end

  task :dropbox_doug => :environment do

    doug = User.find_by_username("doug")
    doug.dropbox.sync_delta
  end

  task :dropbox => :environment do

    User.all.each do |user|
      if user.dropbox.nil?
        next
      end
      if user.dropbox.is_authorized?
        user.dropbox.sync_delta
      end
    end

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
