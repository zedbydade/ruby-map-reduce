Gem::Specification.new do |s|
  s.name        = 'reduce_map'
  s.version     = '0.0.1'
  s.summary     = 'This framework is designed to provide a fully multi-threaded, distributed and asynchronous approach to MapReduce processing.'
  s.description = 'Ruby map/reduce framework'
  s.authors     = ['Francisco Paradela']
  s.email       = 'franciscoleite.dev@protonmail.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    =
    'https://rubygems.org/gems/map_reduce'
  s.license = 'MIT'

  s.add_runtime_dependency 'async', '2.12.0'
  s.add_runtime_dependency 'grpc', '1.62.0'
end
