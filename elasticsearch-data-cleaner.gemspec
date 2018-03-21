Gem::Specification.new do |s|
  s.name        = 'elasticsearch-data-cleaner'
  s.version     = '0.1.4'
  s.date        = '2018-03-21'
  s.summary     = "Command line tool for removing old Elasticsearch data (indices and types)"
  s.description = "Command line tool which helps remove old ES indices and types"
  s.authors     = ["Maksim Podlesnyi"]
  s.email       = ['mpodlesnyi@smartling.com', 'itops@smartling.com']
  s.files       = ["lib/elasticsearch-data-cleaner.rb"]
  s.executables << 'elasticsearch-data-cleaner'
  s.homepage    = 'https://github.com/Smartling/elasticsearch-data-cleaner'
  s.license     = 'GPL-3.0'
  s.add_runtime_dependency 'faraday', '~> 0.14'
end
