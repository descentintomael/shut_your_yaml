require 'yaml'

namespace :db do
  task :config do
    # Local variables
    configuration_data = {}
    
    # Templates for standard configurations
    # TODO: Some of these variables like socket are dependent on which OS is being used, need to add in functionality to auto-set that correctly
    # TODO: Need to research production db configurations to see if they are any different.
    template_configs = {"SQLite" =>  {"adapter" => "sqlite3", "database" => "db/development.sqlite3", "pool" => "5", "timeout" => "5000"}, "MySQL" =>  {"adapter" => "mysql2", "encoding" => "utf8", "database" => "blog_development", "pool" => "5", "username" => "root", "password" => "", "socket" => "/tmp/mysql.sock"}, "PostgreSQL" =>  {"adapter" => "postgresql", "encoding" => "unicode", "database" => "blog_development", "pool" => "5", "username" => "blog", "password" => ""}, "JRuby SQLite" =>  {"adapter" => "jdbcsqlite3", "database" => "db/development.sqlite3"}, "JRuby MySQL" =>  {"adapter" => "jdbcmysql", "database" => "blog_development", "username" => "root", "password" => ""}, "JRuby PostgreSQL" =>  {"adapter" => "jdbcpostgresql", "encoding" => "unicode", "database" => "blog_development", "username" => "blog", "password" => ""}}
    
    # Required functions
    # Function for getting the user's input choice and repeating until the user enters a valid choice
    # TODO: consider making the input case insensitive
    def get_user_input(allowed_input = [])
      # check to make sure that a non-empty array was passed in
      if !allowed_input.instance_of? Array or allowed_input.empty?
        return ''
      end
      # Remove duplicate values from the valid choices
      allowed_input = allowed_input.uniq
      # Convert all to strings
      allowed_input.map! {|x| x.to_s}
      # Loop until the user enters something valid
      begin
        print "Please enter your choice [#{allowed_input.join(' ')}]: "
        user_input = gets
        # Remove the white space
        user_input.chomp!
      end while not allowed_input.include? user_input
      user_input
    end
    
    # Flow of this task
    # 1) Check for config/database.yml
    #   a) if exists, delete it?
    #     i ) yes - delete file
    #     ii) no - load data into variables
    # 2) Check for line in .gitignore for config/database.yml
    #   a) if exists, do nothing
    #   b) if !exists, ask to add it
    # 3) If config in variables, for each verify configuration to user
    #   a) ask if they wish to change any of the configuration
    #     i) if yes, offer to replace it with standard configuration for SQLite, MySQL, PostGres, or any of the others, check to see what OS the user is using and make sure that the configuration matches that
    #     ii) offer to allow variable changes line by line
    # 4) Check to see if production, testing, or development are missing
    #   a) same as (3a)
    # 5) Offer to add in any custom named configurations
    #   a) same as (3a)
    
    # Step (1)
    if File.exists?('config/database.yml')
      puts "Your database.yml file already exists."
      puts "1) delete current configuration file"
      puts "2) modify current configuration file"
      user_choice = get_user_input((1..2).to_a)
      
      if user_choice == '1' # if the user chose to delete the file do that
        begin
          puts "Deleting configuration file"
          File.delete('config/database.yml')
        rescue Errno::ENOENT => e
          puts "Odd, there was an error deleting it.  Might have been deleted in the meantime."
        end
      elsif user_choice == '2' # if the user wants to keep the file, load it into memory
        puts "Reading in current configuration"
        configuration_data = YAML::load(File.open('config/database.yml'))
      end
    end
    
    # Step (2)
    file_ignore_exists = false
    # Check to see if the database file is ignored in the git ignore file
    if File.exists?('.gitignore')
      file_ignore_exists = File.readlines('.gitignore').include? "config/database.yml\n"
    end
    
    if not file_ignore_exists
      puts "Your database.yml file is not ignore in your gitignore file, this could be a"
      puts "major security vulnerability if you store your code remotely."
      puts "Would you like me to add this to your gitignore file?"
      user_choice = get_user_input(['y','n'])
      
      if user_choice == 'y'
        File.open('.gitignore', 'a') {|f| f.write("config/database.yml\n") }
      end
    end
    
    # Step (3)
    if not configuration_data.empty?
      configuration_data.each do |config|
        puts config.first
      end
    end
      
  end
end