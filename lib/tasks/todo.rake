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

end
