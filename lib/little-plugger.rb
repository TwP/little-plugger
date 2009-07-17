
module LittlePlugger

  VERSION = '1.0.0'  # :nodoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  module ClassMethods

    #
    #
    def plugin( *names )
      plugin_names.concat names
    end

    #
    #
    def plugin_names
      @plugin_names ||= []
    end

    #
    #
    def plugins
      load_plugins
      pm = plugin_module
      names = pm.constants.map { |s| s.to_s }
      names.reject! { |n| n =~ %r/^[A-Z_]+$/ }

      h = {}
      names.each do |name|
        sym = ::LittlePlugger.underscore(name).to_sym
        next unless plugin_names.empty? or plugin_names.include? sym
        h[sym] = pm.const_get name
      end
      h
    end

    #
    #
    def initialize_plugins
      plugins.each do |name, klass|
        msg = "initialize_#{name}"
        klass.send msg if klass.respond_to? msg
      end
    end

    #
    #
    def load_plugins
      @loaded ||= {}
      found = {}

      Gem.find_files(File.join(plugin_path, '*.rb')).each do |path|
        found[File.basename(path, '*.rb').to_sym] = path
      end

      :keep_on_truckin while found.map { |name, path|
        next unless plugin_names.empty? or plugin_names.include? name
        next if @loaded[name]
        begin
          @loaded[name] = load path
        rescue LoadError => err
          warn "Error loading #{path.inspect}: #{err.message}. skipping..."
        end
      }.any?
    end

    #
    #
    def plugin_path
      ::LittlePlugger.default_plugin_path(self)
    end

    def plugin_module
      ::LittlePlugger.default_plugin_module(plugin_path)
    end

  end  # module ClassMethods

  # :stopdoc:

  # Called when another object extends itself with LittlePlugger.
  #
  def self.extended( other )
    other.extend ClassMethods
  end

  # Convert the given string from camel case to snake case.
  #
  #    underscore( "FooBar" )    #=> "foo_bar"
  #
  def self.underscore( string )
    string.scan(%r/[A-Z]+(?:[^A-Z]+)?/).map { |s| s.downcase }.join('_')
  end

  # For a given object returns a default plugin path. The path is
  # created by splitting the object's class name on the namespace separator
  # "::" and converting each part of the namespace into an underscored
  # string (see the +underscore+ method). The strings are then joined using
  # the File#join method to give a filesystem path. Appended to this path is
  # the 'plugins' directory.
  #
  #    default_plugin_path( FooBar::Baz )    #=> "foo_bar/baz/plugins"
  #
  def self.default_plugin_path( obj )
    obj = obj.class unless obj.is_a? Module
    ary = obj.name.split('::').map { |str| underscore str }
    File.join(ary, 'plugins')
  end

  #
  #
  def self.default_plugin_module( path )
    path.split(File::SEPARATOR).inject(Object) do |mod, const|
      const = const.split('_').map { |s| s.capitalize }.join
      mod.const_get const
    end
  end
  # :startdoc:

end  # module LittlePlugger


module Kernel

  #
  #
  def LittlePlugger( opts = {} )
    return ::LittlePlugger::ClassMethods if opts.empty?
    Module.new {
      include ::LittlePlugger::ClassMethods

      if opts.key?(:path)
        eval %Q{def plugin_path() #{opts[:path].to_s.inspect} end}
      end

      if opts.key?(:module)
        eval %Q{def plugin_module() #{opts[:module].name} end}
      end

      if opts.key?(:plugins)
        plugins = Array(opts[:plugins]).map {|val| val.to_sym.inspect}.join(',')
        eval %Q{def plugin_names() @plugin_names ||= [#{plugins}] end}
      end
    }
  end
end  # module Kernel

# EOF
