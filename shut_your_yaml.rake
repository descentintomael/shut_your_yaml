require 'yaml'

namespace :db do
  task :config do
    # Local variables
    configuration_data = {}
    
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
        user_input = STDIN.gets
        # Remove the white space
        user_input.chomp!
      end while not allowed_input.include? user_input
      user_input
    end
    
    # Function for setting up or modifying a configuration
    # Test cases (will create test framework later):
    #   1) name and current config are blank, should ask for name and which config to use
    #   2) name is given, config is blank, should ask for which config to use
    #   3) name is blank, config is given, should ask for the name and then ask for what to do with the given config
    #   4) name and config are given, should ask for what to do with the config
    def setup_configuration (name = "", current_config = {})
      # Templates for standard configurations
      # TODO: Some of these variables like socket are dependent on which OS is being used, need to add in functionality to auto-set that correctly
      # TODO: Need to research production db configurations to see if they are any different.
      # TODO: make this pretty, one line is ugly
      template_configs = {"SQLite" =>  {"adapter" => "sqlite3", "database" => "db/development.sqlite3", "pool" => "5", "timeout" => "5000"}, "MySQL" =>  {"adapter" => "mysql2", "encoding" => "utf8", "database" => "blog_development", "pool" => "5", "username" => "root", "password" => "", "socket" => "/tmp/mysql.sock"}, "PostgreSQL" =>  {"adapter" => "postgresql", "encoding" => "unicode", "database" => "blog_development", "pool" => "5", "username" => "blog", "password" => ""}, "JRuby SQLite" =>  {"adapter" => "jdbcsqlite3", "database" => "db/development.sqlite3"}, "JRuby MySQL" =>  {"adapter" => "jdbcmysql", "database" => "blog_development", "username" => "root", "password" => ""}, "JRuby PostgreSQL" =>  {"adapter" => "jdbcpostgresql", "encoding" => "unicode", "database" => "blog_development", "username" => "blog", "password" => ""}}
      
      # If the name is empty or not a string ask the user for the name of the current working environment
      if !name.instance_of? String or name.empty?
        print "Please enter the name of this database environment: "
        begin
          name = STDIN.gets
          name.chomp!
        end while name.empty?
      end
      
      # If the current configuration is not empty, print it out and then ask the user if they would like to edit it
      if current_config.instance_of? Hash and !current_config.empty?
        puts "Editing the environment #{name}, here is the current configuration"
        current_config.each { |key, val| puts "\t#{key}: #{val}" }
        puts "What would you like to do with this configuration?"
        puts "1) Edit this configuration"
        puts "2) Replace this configuration"
        puts "3) Delete this configuration"
        user_choice = get_user_input((1..3).to_a)
        
        if user_choice == '1'
          # User wants to edit the configuration row by row
          current_config.each do |key,val|
            print "Current val for #{key} is #{val}. Press [Enter] to keep or type in your val: "
            new_val = STDIN.gets
            new_val = val.to_s if new_val == "\n"
            current_config.merge!({key => new_val.chomp})
          end
          # Ask the user if they'd like to add more values
          begin
            puts "Would you like to add another value?"
            continue_choice = get_user_input(['y','n'])
            
            if continue_choice == 'y'
              print "Please enter a name for the val: "
              key = STDIN.gets
              key.chomp!
              if !key.empty?
                print "Please enter a value: "
                val = STDIN.gets
                current_config.merge!({key => val.chomp})
              end
            end
          end while continue_choice == 'y'
        elsif user_choice == '2'
          # User wants to replace this with soemthing else
          current_config = {}
        elsif user_choice == '3'
          # User wants to delete this so just return an empty hash
          return {}
        end
      end
      
      # if the current config is empty then suggest to use either the templates or create a custom configuration
      if current_config.empty?
        puts "The current configuration is empty, please select a template from below or choose to create a custom configuration."
        key_index = 1
        template_configs.each_key { |key| puts "#{key_index}) #{key}"; key_index += 1}
        puts "#{key_index}) Custom Configuration"
        user_choice = get_user_input((1..key_index).to_a)
        
        if user_choice.to_i <= template_configs.size
          # User wants to use a template
          chosen_template = template_configs.keys[user_choice.to_i - 1]
          current_config = template_configs[chosen_template]
          # Print out the template data and ask the user if they'd like to edit it
          puts "You've chosen #{chosen_template} with the following values:"
          current_config.each { |key, val| puts "\t#{key}: #{val}" }
          puts "Would you like to edit it?"
          edit_choice = get_user_input(['y','n'])
          
          if edit_choice == 'y'
            # User wants to edit the configuration row by row
            current_config.each do |key,val|
              print "Current val for #{key} is #{val}. Press [Enter] to keep or type in your val: "
              new_val = STDIN.gets
              new_val = val if new_val == "\n"
              current_config.merge!({key => new_val.chomp})
            end
            # Ask the user if they'd like to add more values
            begin
              puts "Would you like to add another value?"
              continue_choice = get_user_input(['y','n'])

              if continue_choice == 'y'
                print "Please enter a name for the val: "
                key = STDIN.gets
                key.chomp!
                if !key.empty?
                  print "Please enter a value: "
                  val = STDIN.gets
                  current_config.merge!({key => val.chomp})
                end
              end
            end while continue_choice == 'y'
          end
        else
          # User wants a custom configuration
          begin
            print "What do you want the name for the first val to be? "
            key = STDIN.gets
            key.chomp!
          end while key.empty?
          print "and the value? "
          val = STDIN.gets
          current_config.merge!({key => val.chomp})
          
          # Ask the user if they'd like to add more values
          begin
            puts "Would you like to add another value?"
            continue_choice = get_user_input(['y','n'])

            if continue_choice == 'y'
              print "Please enter a name for the val: "
              key = STDIN.gets
              key.chomp!
              if !key.empty?
                print "Please enter a value: "
                val = STDIN.gets
                current_config.merge!({key => val.chomp})
              end
            end
          end while continue_choice == 'y'
        end
      end
      
      return {name => current_config}
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
      configuration_data.each_key do |key| 
        begin
          puts "Current configuration contains the environment #{key}, what would you like to do with this environment?"
          puts "1) Edit it"
          puts "2) Delete it"
          puts "3) View it"
          puts "4) Skip it"
          user_choice = get_user_input((1..4).to_a)
          
          if user_choice.to_i == 1
            # User wants to edit this configuration
            setup_configuration(key, configuration_data[key])
          elsif user_choice.to_i == 2
            # User wants to delete this configuration
            configuration_data.delete(key)
          elsif user_choice.to_i == 3
            # User wants to view this configuration
            puts "Environment #{key}"
            configuration_data[key].each { |config_key, config_val| puts "\t#{config_key}: #{config_val}" }
          end
        end while user_choice == "3"
      end
    end
    
    # Step (4)
    if !configuration_data.has_key? "development"
      # configuration doesn't have the development environment, suggest adding it
      puts "The configuration doesn't have a development environment, would you like to add it?"
      user_choice = get_user_input(['y','n'])
      if user_choice == 'y'
        setup_configuration("development", {})
      end
    end
    
    if !configuration_data.has_key? "test"
      # configuration doesn't have the test environment, suggest adding it
      puts "The configuration doesn't have a test environment, would you like to add it?"
      user_choice = get_user_input(['y','n'])
      if user_choice == 'y'
        setup_configuration("test", {})
      end
    end
    
    if !configuration_data.has_key? "production"
      # configuration doesn't have the production environment, suggest adding it
      puts "The configuration doesn't have a production environment, would you like to add it?"
      user_choice = get_user_input(['y','n'])
      if user_choice == 'y'
        setup_configuration("development", {})
      end
    end
    
    # Step (5)
    begin
      puts "Would you like to add another configuration environment?"
      user_choice = get_user_input(['y','n'])
      if user_choice == 'y'
        setup_configuration()
      end
    end while user_choice == 'y'
  end
end