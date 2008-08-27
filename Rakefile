require 'ftools'

target_locations = [
  File::expand_path("~/Applications/"),
  "/Applications/"
]

desc "Build and install (or upgrade) GitX"
task :install => [:uninstall_app, :build_app, :install_app]
desc "Clean build directory, uninstall application"
task :uninstall => [:clean_app, :uninstall_app]
desc "Clean build directory"
task :clean => [:clean_app]

desc "Build gitX using XCode"
task :build_app do
  system("xcodebuild")
end

task :clean_app do
  system("xcodebuild -alltargets clean OBJROOT=build/ SYMROOT=build/")
end

desc "Copies the built GitX.app to the application folder"
task :install_app do
  target_locations.each do |loc|
    if File.directory?(loc)
      puts "Copying to (#{loc})"
      File.copy("build/Release/GitX.app/", loc)
      break
    end
  end
end

desc "Remove GitX.app from ~/Applications/ or /Applications/"
task :uninstall_app do
  found = false
  target_locations.each do |loc|
    cur_path = File.join(loc, "GitX.app")
    puts "Checking #{cur_path}"
    if File.exists?( cur_path )
      puts "Removing GitX.app from #{cur_path}"
      system("rm", "-rf", cur_path)
      found = true
      break
    end
  end
  puts "Couldn't find installed GitX.app" unless found
end

desc "Creates a zip file with current GitX"
task :create_zip do
  if ENV["STABLE"]
    name = "GitXStable"
  else
    name = "GitX"
  end

  delete = File.directory?("build/Release")
  system("xcodebuild")
  system("cd build/Release && zip -r #{name}.app.zip GitX.app")
  system("mv build/Release/#{name}.app.zip .")
  system("rm -rf build/Release") if delete
  system("upload #{name}.app.zip") # This is a local script -- Pieter
end