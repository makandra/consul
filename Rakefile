require 'rake'
require 'bundler/gem_tasks'

desc 'Default: Run all specs.'
task :default => 'all:spec'

namespace :travis_ci do

  desc 'Things to do before Travis CI begins'
  task :prepare => [:compatible_rubygems]

  desc 'Ensure compatible Rubygems version for Ruby 1.8'
  task :compatible_rubygems do
    if RUBY_VERSION == '1.8.7'
      system "rvm rubygems latest-1.8 --force"
    end
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
    elsif directory.include?('rails-3.2') && RUBY_VERSION >= '2.2.0'
      puts 'Skipping - Rails 3.2.13 does not support Ruby 2.2+'
    elsif directory.include?('rails-4.2') && (RUBY_VERSION < '1.9.3' || RUBY_VERSION >= '2.4.0')
      puts 'Skipping - Rails 4.2 requires Ruby 1.9.3+ .. 2.3.x'
    elsif directory.include?('rails-5.1') && RUBY_VERSION < '2.2.2'
      puts 'Skipping - Rails 5 requires Ruby 2.2.2+'
    else
      block.call(directory)
    end
  end
end
