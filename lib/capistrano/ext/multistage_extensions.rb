Capistrano::Configuration.instance(:must_exist).load do
  namespace :multistage do
    namespace :sync do
      # Synchronisations tasks
      # Don't you just love metaprogramming? I know I fucking do!
      stages.each do |target_stage|
        stages.reject { |s| s == target_stage }.each do |source_stage|
          desc "Synchronise #{target_stage}'s database with #{source_stage}"
          task "#{target_stage}_database_with_#{source_stage}", :roles => :db do
            # Ask for a confirmation
            ask_for_confirmation "I am going to synchronise '#{target_stage}' database with '#{source_stage}', it means I will overwrite the database of '#{target_stage}' with those of '#{source_stage}', are you really sure you would like to continue (Yes, [No], Abort)", default:'N'

            # Generate a random folder name
            random_folder = random_tmp_file

            # Create the folder
            FileUtils.mkdir_p random_folder

            # Get the database of the source
            system "bundle exec cap #{source_stage} db:export #{random_folder}/database.sql"

            # Send it to the target
            system "bundle exec cap #{target_stage} db:import #{random_folder}/database.sql"

            # Remove the entire folder
            FileUtils.rm_rf random_folder
          end

          desc "Synchronise #{target_stage}'s contents with #{source_stage}"
          task "#{target_stage}_contents_with_#{source_stage}", :roles => :app do
            # Ask for a confirmation
            ask_for_confirmation "I am going to synchronise '#{target_stage}' contents with '#{source_stage}', it means I will overwrite the contents of '#{target_stage}' with those of '#{source_stage}', are you really sure you would like to continue (Yes, [No], Abort)", default:'N'

            # Generate a random folder name
            random_folder = random_tmp_file

            # Create the folder
            FileUtils.mkdir_p random_folder

            # Get the contents of the source
            system "bundle exec cap #{source_stage} content:export #{random_folder}/contents.tar.gz"

            # Send them to the target
            system "bundle exec cap #{target_stage} content:import #{random_folder}/contents.tar.gz"

            # Remove the entire folder
            FileUtils.rm_rf random_folder
          end

          desc "Synchronise #{target_stage} with #{source_stage}"
          task "#{target_stage}_with_#{source_stage}", :roles => [:app, :db], :except => { :no_release => true } do
            # Ask for a confirmation
            ask_for_confirmation "I am going to synchronise '#{target_stage}' with '#{source_stage}', it means I will overwrite both the database and the contents of '#{target_stage}' with those of '#{source_stage}', are you really sure you would like to continue (Yes, [No], Abort)", default:'N'

            # Synchronise the database
            system "bundle exec cap -S force=true multistage:sync:#{target_stage}_database_with_#{source_stage}"

            # Synchronise the contents
            system "bundle exec cap -S force=true multistage:sync:#{target_stage}_contents_with_#{source_stage}"
          end
        end
      end
    end
  end
end
