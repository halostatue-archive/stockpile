# -*- encoding: utf-8 -*-
# stub: stockpile 2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "stockpile"
  s.version = "2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Austin Ziegler"]
  s.date = "2016-04-05"
  s.description = "Stockpile is a simple key-value store connection manager framework. Stockpile\nitself does not implement a connection manager, but places expectations for\nimplemented connection managers. So far, only Redis has been implemented\n(stockpile-redis).\n\nStockpile also provides an adapter so that its functionality can be accessed\nfrom within a module.\n\nRelease 2.0 fixes an issue when Stockpile options are provided with an\nOpenStruct, originally reported as\n{stockpile-redis#1}[https://github.com/halostatue/stockpile-redis/issues/1].\nSupport for Ruby 1.9 has been dropped."
  s.email = ["halostatue@gmail.com"]
  s.extra_rdoc_files = ["Code-of-Conduct.md", "Contributing.rdoc", "History.md", "Licence.rdoc", "Manifest.txt", "README.rdoc"]
  s.files = [".autotest", ".gemtest", ".minitest.rb", ".rubocop.yml", ".simplecov-prelude.rb", ".travis.yml", ".workenv", "Code-of-Conduct.md", "Contributing.rdoc", "Gemfile", "History.md", "Licence.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "lib/stockpile.rb", "lib/stockpile/base.rb", "lib/stockpile/memory.rb", "test/minitest_config.rb", "test/test_stockpile.rb", "test/test_stockpile_base.rb"]
  s.homepage = "https://github.com/halostatue/stockpile/"
  s.licenses = ["MIT"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0")
  s.rubygems_version = "2.5.1"
  s.summary = "Stockpile is a simple key-value store connection manager framework"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>, ["~> 5.8"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_development_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_development_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_development_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_development_dependency(%q<minitest-bonus-assertions>, ["~> 2.0"])
      s.add_development_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_development_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_development_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_development_dependency(%q<rake>, [">= 10.0"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<hoe>, ["~> 3.15"])
    else
      s.add_dependency(%q<minitest>, ["~> 5.8"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
      s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5"])
      s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
      s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
      s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
      s.add_dependency(%q<minitest-bonus-assertions>, ["~> 2.0"])
      s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
      s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
      s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
      s.add_dependency(%q<rake>, [">= 10.0"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<hoe>, ["~> 3.15"])
    end
  else
    s.add_dependency(%q<minitest>, ["~> 5.8"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-doofus>, ["~> 1.0"])
    s.add_dependency(%q<hoe-gemspec2>, ["~> 1.1"])
    s.add_dependency(%q<hoe-git>, ["~> 1.5"])
    s.add_dependency(%q<hoe-travis>, ["~> 1.2"])
    s.add_dependency(%q<minitest-autotest>, ["~> 1.0"])
    s.add_dependency(%q<minitest-bisect>, ["~> 1.2"])
    s.add_dependency(%q<minitest-bonus-assertions>, ["~> 2.0"])
    s.add_dependency(%q<minitest-focus>, ["~> 1.1"])
    s.add_dependency(%q<minitest-moar>, ["~> 0.0"])
    s.add_dependency(%q<minitest-pretty_diff>, ["~> 0.1"])
    s.add_dependency(%q<rake>, [">= 10.0"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<hoe>, ["~> 3.15"])
  end
end
