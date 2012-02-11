#!/usr/bin/env ruby

home = ENV['HOME']

def symlinkable? file
  return true if File.extname(file).empty?
  return true if file == 'tmux.conf'
  return true if file == 'bin'
  return true if file == 'vim'
  return false
end

# Regular dotfiles
Dir.chdir File.dirname(__FILE__) do
  cur_dir = Dir.pwd.sub(home + '/', '')

  Dir['*'].each do |file|
    next unless symlinkable? file
    target_name = file == 'bin' ? file : ".#{file}"
    target = File.join(home, target_name)
    unless File.exist? target
      system %[ln -vsf #{File.join(cur_dir, file)} #{target}]
    end
  end
end

# SSH files
Dir.chdir File.join(File.dirname(__FILE__), "ssh") do
  cur_dir = Dir.pwd.sub(home + '/', '')
  
  if (/ssh-rsa/ === File.read('known_hosts'))  
    Dir['*'].each do |file|
      target = File.join(home, ".ssh", file)
      unless File.exist? target
        system %[ln -vsf #{File.join(cur_dir, file)} #{target}]
      end
    end
  else
    puts "Skipping content for .ssh as the contents are still encrypted."
  end # if
end