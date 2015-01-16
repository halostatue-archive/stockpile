# -*- ruby -*-

require "rubygems"
require "hoe"



Hoe.spec "stockpile" do
  # HEY! If you fill these out in ~/.hoe_template/minitest-travis/Rakefile.erb,
  # you'll never have to touch them again!
  # (delete this comment too, of course)

  developer('FIX', 'FIX@example.com')

  self.history_file = 'History.rdoc'
  self.readme_file = 'README.rdoc'
  self.extra_rdoc_files = FileList["*.rdoc"].to_a

  license "MIT" # FIX this should match the license in the README
  # self.licenses = [ "MIT", ... ]

  self.extra_dev_deps << ['hoe-doofus', '~> 1.0']
  self.extra_dev_deps << ['hoe-gemspec2', '~> 1.1']
  self.extra_dev_deps << ['hoe-git', '~> 1.5']
  self.extra_dev_deps << ['hoe-rubygems', '~> 1.0']
  self.extra_dev_deps << ['hoe-travis', '~> 1.2']
  self.extra_dev_deps << ['minitest', '~> 5.4']
  self.extra_dev_deps << ['rake', '~> 10.0']

  # self.extra_dev_deps << ['simplecov', '~> 0.7']
end

=begin
namespace :test do
  task :coverage do
    spec.test_prelude = [
      'require "simplecov"',
      'SimpleCov.start("test_frameworks") { command_name "Minitest" }',
      'gem "minitest"'
    ].join('; ')
    Rake::Task['test'].execute
  end
end
=end

# vim: syntax=ruby
