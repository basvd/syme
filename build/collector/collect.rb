#!/usr/bin/env ruby
# -*- ruby -*-

# Copyright © 2010 Bas van Doren (applies to modifications)
# Copyright © 2009 Lars Christensen (applies to Ocra source code)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the ‘Software’), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED ‘AS IS’, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require "fileutils"

module Ocra
  VERSION = "1.1.3"

  IGNORE_MODULES = /^enumerator.so$/

  PATH_SEPARATOR = /[\/\\]/

  class << self
    attr_accessor :output_dir
    attr_accessor :extra_dlls
    attr_accessor :files
    attr_accessor :load_autoload
    attr_accessor :force_windows
    attr_accessor :force_console
    attr_accessor :icon_filename
    attr_accessor :quiet
    attr_accessor :autodll
    attr_accessor :show_warnings
  end

  def Ocra.initialize_ocra
    @load_path_before = $LOAD_PATH.dup

    ocrapath = File.dirname(__FILE__)
  end

  def Ocra.parseargs(argv)
    extra_dlls = []
    files = []
    load_autoload = true
    force_windows = false
    force_console = false
    icon_filename = nil
    quiet = false
    autodll = true
    show_warnings = true

    usage = <<EOF
collect.rb [options] script.rb

--out dir        Write to this output directory (default: ocra_out)
--dll dllname    Include additional DLLs from the Ruby bindir.
--quiet          Suppress output.
--help           Display this information.
--windows        Force Windows application (rubyw.exe)
--console        Force console application (ruby.exe)
--no-autoload    Don't load/include script.rb's autoloads
--icon <ico>     Replace icon with a custom one
--version        Display version number
EOF

    while arg = argv.shift
      case arg
      when /\A--out\z/
        out_dir = argv.shift
      when /\A--dll\z/
        extra_dlls << argv.shift
      when /\A--quiet\z/
        quiet = true
      when /\A--windows\z/
        force_windows = true
      when /\A--console\z/
        force_console = true
      when /\A--no-autoload\z/
        load_autoload = false
      when /\A--icon\z/
        icon_filename = argv.shift
        raise "Icon file #{icon_filename} not found.\n" unless File.exist?(icon_filename)
      when /\A--no-autodll\z/
        autodll = false
      when /\A--version\z/
        puts "Ocra #{VERSION}"
        exit
      when /\A--no-warnings\z/
        show_warnings = false
      when /\A--help\z/, /\A--/
        puts usage
        exit
      else
        files << arg
      end
    end

    if files.empty?
      puts usage
      exit
    end

    @output_dir = out_dir || File.join(".", "ocra_out")
    @extra_dlls = extra_dlls
    @quiet = quiet
    @force_windows = force_windows
    @force_console = force_console
    @load_autoload = load_autoload
    @icon_filename = icon_filename
    @autodll = autodll
    @files = files
    @show_warnings = show_warnings
  end

  def Ocra.init(argv)
    parseargs(argv)
    initialize_ocra
  end

  # Force loading autoloaded constants. Searches through all modules
  # (and hence classes), and checks their constants for autoloaded
  # ones, then attempts to load them.
  def Ocra.attempt_load_autoload
    modules_checked = []
    loop do
      modules_to_check = []
      ObjectSpace.each_object(Module) do |mod|
        modules_to_check << mod unless modules_checked.include?(mod)
      end
      break if modules_to_check.empty?
      modules_to_check.each do |mod|
        modules_checked << mod
        mod.constants.each do |const|
          if mod.autoload?(const)
            begin
              mod.const_get(const)
            rescue LoadError
              puts "=== WARNING: #{mod}::#{const} was not loadable" if Ocra.show_warnings
            end
          end
        end
      end
    end
  end

  def Ocra.relative_path(src, tgt)
    a = src.split('/')
    b = tgt.split('/')
    while a.first && a.first.downcase == b.first.downcase
      a.shift
      b.shift
    end
    return tgt if b.first =~ /^[a-z]:/i
    a.size.times { b.unshift '..' }
    return b.join('/')
  end

  # Determines if 'src' is contained in 'tgt' (i.e. it is a subpath of
  # 'tgt'). Both must be absolute paths and not contain '..'
  def Ocra.subpath?(src, tgt)
    src_normalized = src
    tgt_normalized = tgt
    src_normalized =~ /^#{Regexp.escape tgt_normalized}[\/\\]/i
  end

  def Ocra.find_load_path(paths, path)
    if path[1,1] == ":"
      rps = paths.map {|p| relative_path(File.expand_path(p), path) }
      rps.zip(paths).sort_by {|x| x[0].size }.first[1]
    else
      candidates = paths.select { |p| File.exist?(File.expand_path(path, p)) }
      candidates.sort_by {|p| p.size}.last
    end
  end

  def Ocra.build_exe
    @added_load_paths = $LOAD_PATH - @load_path_before

    # Attempt to autoload libraries before doing anything else.
    attempt_load_autoload if Ocra.load_autoload

    # Store the currently loaded files (before we require rbconfig for
    # our own use).
    features = $LOADED_FEATURES.dup

    # Find gemspecs to include
    if defined?(Gem)
      gemspecs = Gem.loaded_specs.map { |name,info| info.loaded_from }
    else
      gemspecs = []
    end

    require 'rbconfig'
    exec_prefix = RbConfig::CONFIG['exec_prefix']
    src_prefix = File.expand_path(File.dirname(Ocra.files[0]))
    sitelibdir = RbConfig::CONFIG['sitelibdir']
    bindir = RbConfig::CONFIG['bindir']
    libruby_so = RbConfig::CONFIG['LIBRUBY_SO']

    instsitelibdir = sitelibdir[exec_prefix.size+1..-1]

    load_path = []

    # Find loaded files
    libs = []
    features.each do |filename|
      path = find_load_path($:, filename)
      if path
        if filename[1,1] == ":"
          filename = relative_path(File.expand_path(path), filename)
        end
        if filename =~ /^\.\.\//
          puts "=== WARNING: Detected a relative require (#{filename}). This is not recommended." if Ocra.show_warnings
        end
        fullpath = File.expand_path(filename, path)
        if subpath?(fullpath, exec_prefix)
          libs << [ fullpath, fullpath[exec_prefix.size+1..-1] ]
        elsif subpath?(fullpath, src_prefix)
          targetpath = "src/" + fullpath[src_prefix.size+1..-1]
          libs << [ fullpath, targetpath ]
          if not @added_load_paths.include?(path) and not load_path.include?(path)
            load_path << File.dirname(targetpath)
          end
        elsif defined?(Gem) and gemhome = Gem.path.find { |pth| subpath?(fullpath, pth) }
          targetpath = File.join("gemhome", relative_path(gemhome, fullpath))
          libs << [ fullpath, targetpath ]
        else
          libs << [ fullpath, File.join(instsitelibdir, filename) ]
        end
      else
        puts "=== WARNING: Couldn't find #{filename}" unless filename =~ IGNORE_MODULES if Ocra.show_warnings
      end
    end

    # Detect additional DLLs
    dlls = Ocra.autodll ? LibraryDetector.detect_dlls : []

    executable = Ocra.files[0].sub(/(\.rbw?)?$/, ".exe")

    windowed = (Ocra.files[0] =~ /\.rbw$/ || Ocra.force_windows) && !Ocra.force_console

    puts "=== Building #{executable}" unless Ocra.quiet
    OcraBuilder.new(executable, windowed) do |sb|
      # Add explicitly mentioned files
      Ocra.files.each do |file|
        if File.directory?(file)
          sb.ensuremkdir(File.join("src",file))
        else
          if subpath?(file, exec_prefix)
            target = file[exec_prefix.size+1..-1]
          else
            target = File.join("src", file)
          end
          sb.createfile(file, target)
        end
      end

      # Add icon
      sb.createfile(@icon_filename, "app.ico") if @icon_filename =~ /\.ico$/

      # Add the ruby executable and DLL
      if windowed
        rubyexe = (RbConfig::CONFIG["rubyw_install_name"] || "rubyw") + ".exe"
      else
        rubyexe = (RbConfig::CONFIG["ruby_install_name"] || "ruby") + ".exe"
      end
      sb.createfile(File.join(bindir, rubyexe), File.join("bin", rubyexe))
      if libruby_so
        sb.createfile(File.join(bindir, libruby_so), File.join("bin", libruby_so))
      end

      # Add detected DLLs
      dlls.each do |dll|
        if subpath?(dll.tr('\\','/'), exec_prefix)
          target = dll[exec_prefix.size+1..-1]
        else
          target = File.join('bin', File.basename(dll))
        end
        sb.createfile(dll, target)
      end

      # Add extra DLLs
      Ocra.extra_dlls.each do |dll|
        sb.createfile(File.join(bindir, dll), File.join("bin", dll))
      end

      # Add gemspecs
      gemspecs.each do |gemspec|
        if subpath?(gemspec, exec_prefix)
          path = gemspec[exec_prefix.size+1..-1]
          sb.createfile(gemspec, path)
        elsif defined?(Gem) and gemhome = Gem.path.find { |pth| subpath?(gemspec, pth) }
          path = File.join('gemhome', relative_path(gemhome, gemspec))
          sb.createfile(gemspec, path)
        else
          raise "#{gemspec} does not exist in the Ruby installation. Don't know where to put it."
        end
      end

      # Add loaded libraries
      libs.each do |path, target|
        sb.createfile(path, target.tr('/', '\\'))
      end

      # Set environment variable
      sb.setenv('RUBYOPT', ENV['RUBYOPT'] || '')
      sb.setenv('RUBYLIB', load_path.uniq.join(';'))
      sb.setenv('GEM_PATH', File.join("gemhome"))

      # Launch the script
      sb.createprocess(File.join("bin", rubyexe), File.join("src", Ocra.files[0]))

      puts "=== Compressing" unless Ocra.quiet
    end
    #puts "=== Finished building #{executable} (#{File.size(executable)} bytes)" unless Ocra.quiet
  end

  module LibraryDetector
    def LibraryDetector.loaded_dlls
      require 'Win32API'

      enumprocessmodules = Win32API.new('psapi', 'EnumProcessModules', ['L','P','L','P'], 'B')
      getmodulefilename = Win32API.new('kernel32', 'GetModuleFileName', ['L','P','L'], 'L')
      getcurrentprocess = Win32API.new('kernel32', 'GetCurrentProcess', ['V'], 'L')

      bytes_needed = 4 * 32
      module_handle_buffer = nil
      process_handle = getcurrentprocess.call()
      loop do
        module_handle_buffer = "\x00" * bytes_needed
        bytes_needed_buffer = [0].pack("I")
        r = enumprocessmodules.call(process_handle, module_handle_buffer, module_handle_buffer.size, bytes_needed_buffer)
        bytes_needed = bytes_needed_buffer.unpack("I")[0]
        break if bytes_needed <= module_handle_buffer.size
      end

      handles = module_handle_buffer.unpack("I*")
      handles.select{|x|x>0}.map do |h|
        str = "\x00" * 256
        r = getmodulefilename.call(h, str, str.size)
        str[0,r]
      end
    end

    def LibraryDetector.detect_dlls
      loaded = loaded_dlls
      exec_prefix = RbConfig::CONFIG['exec_prefix']
      loaded.select do |path|
        Ocra.subpath?(path.tr('\\','/'), exec_prefix) and
          File.basename(path) =~ /\.dll$/i and
          File.basename(path).downcase != RbConfig::CONFIG['LIBRUBY_SO'].downcase
      end
    end
  end

  class OcraBuilder

    def initialize(path, windowed)
      @output_dir = Ocra.output_dir
      @env = {}
      yield(self)

      # Save @env to file
      File.open(File.join(@output_dir, "env.nsh"), "w" ) do |ef|
        @env.each do |key, val|
          ef.puts("!define \"ENV_#{key}\" \"#{val}\"")
        end
      end
    end

    def mkdir(path)
      FileUtils.mkdir_p(path)
    end

    def ensuremkdir(tgt)
      tgt = File.join(@output_dir, tgt)
      unless File.directory? tgt
        puts "m #{tgt}" unless Ocra.quiet
        mkdir(tgt)
      end
    end

    def createfile(src, tgt)
      ensuremkdir(File.dirname(tgt))

      puts "a #{tgt}" unless Ocra.quiet
      FileUtils.cp(src, File.join(@output_dir, tgt))
    end

    def createprocess(image, cmdline)
      puts "l #{image} #{cmdline}" unless Ocra.quiet
      #@env[image] = cmdline
    end

    def setenv(name, value)
      puts "e #{name} #{value}" unless Ocra.quiet
      @env[name] = value
    end

    def close
      # Is this even called?
    end

  end # class OcraBuilder

end # module Ocra

if File.basename(__FILE__) == File.basename($0)
  Ocra.init(ARGV)
  ARGV.clear

  at_exit do
    if $!.nil? or $!.kind_of?(SystemExit)
      Ocra.build_exe
      exit(0)
    end
  end

  puts "=== Loading script to check dependencies" unless Ocra.quiet
  $0 = Ocra.files[0]
  load Ocra.files[0]
end
