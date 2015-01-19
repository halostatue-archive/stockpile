# -*- encoding: utf-8 -*-
# stub: stockpile 1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "stockpile"
  s.version = "1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2015-01-19"
  s.description = "FIX (describe your package)"
  s.email = ["halostatue@gmail.com"]
  s.executables = ["stockpile"]
  s.extra_rdoc_files = ["Contributing.rdoc", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Contributing.rdoc", "History.rdoc", "Licence.rdoc", "README.rdoc"]
  s.files = [".autotest", ".gemtest", ".minitest.rb", ".travis.yml", "Contributing.rdoc", "Gemfile", "History.rdoc", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "bin/stockpile", "lib/stockpile.rb", "test/minitest_config.rb", "test/test_stockpile.rb", "test/test_stockpile_redis_connector.rb"]
  s.homepage = "https://stockpile.github.io/"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.rubygems_version = "2.2.2"
  s.summary = "FIX (describe your package)"
  s.test_files = ["test/test_stockpile.rb", "test/test_stockpile_redis_connector.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.5"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<fakeredis>, ["~> 0.5"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-around>, ["~> 0.3"])
      s.add_development_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_development_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_development_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_development_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_development_dependency(%q<minitest-rerun>, ["~> 0.1"])
      s.add_development_dependency(%q<rake>, [">= 10.0"])
      s.add_development_dependency(%q<redis-namespace>, ["~> 1.5"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.5"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<fakeredis>, ["~> 0.5"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-around>, ["~> 0.3"])
      s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_dependency(%q<minitest-rerun>, ["~> 0.1"])
      s.add_dependency(%q<rake>, [">= 10.0"])
      s.add_dependency(%q<redis-namespace>, ["~> 1.5"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.5"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<fakeredis>, ["~> 0.5"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.5"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-around>, ["~> 0.3"])
    s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
    s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
    s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
    s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
    s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
    s.add_dependency(%q<minitest-rerun>, ["~> 0.1"])
    s.add_dependency(%q<rake>, [">= 10.0"])
    s.add_dependency(%q<redis-namespace>, ["~> 1.5"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
