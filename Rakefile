desc "Collect dependencies and environment variables"
task :collect do
  # TODO: Recursive dirs
  ruby "build/collector/collect.rb --windows --dll rubyw.exe.manifest --out build/app SymeApp.rb theme/* theme/*/*"
end

file "build/app/env.nsh" => :collect
file "build/Syme.exe" => :launcher

desc "Build launcher"
task :launcher => ["build/app/env.nsh"] do

  # NSIS should be installed
  require 'win32/registry'
  nsis_path = Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\NSIS') do |entry| entry.read_s "" end

  sh "\"#{nsis_path}\\makensis.exe\" /V2 build\\syme.nsi"
end

desc "Create zip package"
task :package => [:collect, "build/Syme.exe"] do
  cd "build"
  sh "zip -x app/env.nsh -r syme.zip app/* Syme.exe"
  cd ".."
end

desc "Delete built files"
task :clean do
  rm_rf "build/app"
  rm_f "build/Syme.exe"
end

task :info do
  puts "Gathering info..."
  require "SymeApp"
  info = `.ignore/cloc.exe *.*  Rakefile build lib theme models gui`
  puts "-------------------------------------------------------------------------------"
  puts SYME_NAME
  puts "Version: #{SYME_VERSION}"
  puts "-------------------------------------------------------------------------------"
  puts info

end

task :default => [:package, :clean, :info]
