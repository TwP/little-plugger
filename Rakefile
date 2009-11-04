
begin
  require 'bones'
rescue LoadError
  raise RuntimeError, '### please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'little-plugger'

task :default => 'spec:specdoc'

Bones.disregard_plugin :rubyforge
Bones {
  name 'little-plugger'
  authors 'Tim Pease'
  email 'tim.pease@gmail.com'
  url 'http://gemcutter.org/gems/little-plugger'
  version LittlePlugger::VERSION
  exclude << 'little-plugger.gemspec'
  readme_file 'README.rdoc'
  ignore_file '.gitignore'

  spec.opts << '--color'

  use_gmail
  enable_sudo

  depend_on 'rspec', :development => true
  depend_on 'bones-extras', :development => true
}

# EOF
