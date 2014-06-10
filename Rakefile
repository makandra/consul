require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'

namespace :travis_ci do

  desc 'Things to do before Travis CI begins'
  task :prepare => :slimgems

  desc 'Install slimgems'
  task :slimgems do
    system('gem install slimgems')
  end

end

namespace :all do

  desc "Run specs on all spec apps"
  task :spec do
    success = true
    for_each_directory_of('spec/**/Rakefile') do |directory|
      env = "SPEC=../../#{ENV['SPEC']} " if ENV['SPEC']
      success &= system("cd #{directory} && #{env} bundle exec rake spec")
    end
    fail "Tests failed" unless success
  end

  desc "Bundle all spec apps"
  task :bundle do
    for_each_directory_of('spec/**/Gemfile') do |directory|
      Bundler.with_clean_env do
        system("cd #{directory} && bundle install")
      end
    end
  end

end

def for_each_directory_of(path, &block)
  Dir[path].sort.each do |rakefile|
    directory = File.dirname(rakefile)
    puts '', "\033[4;34m# #{directory}\033[0m", '' # blue underline
    
    if directory.include?('rails-2.3') and RUBY_VERSION != '1.8.7'
      puts 'Skipping - Rails 2.3 requires Ruby 1.8.7'
    elsif directory.include?('rails-4.1') and RUBY_VERSION == '1.8.7'
      puts 'Skipping - Rails 4.1 does not support Ruby 1.8'
    else
      block.call(directory)
    end
  end
end
