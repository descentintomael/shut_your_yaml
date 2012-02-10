Shut Your Yaml
==============

Description
-----------
This is a rake task for setting up your database.yml file for Rails.  I created this because you aren't 
supposed to store that file in your DVCS due to security concerns and it can sometimes be a pain to set 
it up properly on new systems.  This task comes complete with the sample database configurations from
[RailsGuides](http://guides.rubyonrails.org/getting_started.html) and allows the user to edit the 
individual fields.

Getting Started
---------------
1. Clone the repo
    
    `git clone git://github.com/descentintomael/shut_your_yaml.git`
    
2. Link it into your rails app
    
    `cd shut_your_yaml`
    
    `ln -s shut_your_yaml.rake /path/to/your/rails/app/syy.rake`
    
3. Run rake to process it
    
    `rake -f syy.rake db:config`
    
4. Follow the on screen prompts to complete the database configuration

TODO
----
The following still needs to be completed.  See comments in the code for any I missed here.

* Create a backup of the database.yml file before deleting or modifying it
* Add that backup to the .gitignore or some place outside the Rails app
* Add in OS dependent variables (such as the MySQL socket path)
* Add in environment name dependent variables (such as the nam of the sqlite file)
* Pretty up the template code in the rake file (a never-ending single line is not pretty)
* Use some sort of templating language like mustache to handle the templates
* Figure out a way of marking different configuration fields as a particular data type
