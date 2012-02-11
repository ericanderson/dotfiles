#!/usr/bin/env ruby

def symlinkable? file
  return true if File.extname(file).empty?
  return true if file == 'tmux.conf'
  return true if file == 'bin'
  return true if file == 'vim'
  return false
end

def target_for(file)
  if file == 'bin'
    File.join(ENV['HOME'], file)
  else
    File.join(ENV['HOME'], "." + file)
  end
end

# Regular dotfiles
Dir.chdir File.dirname(__FILE__) do
  cur_dir = Dir.pwd.sub(ENV['HOME'] + '/', '')

  Dir['*'].each do |file|
    next unless symlinkable? file
    unless File.exist? target_for(file)
      system %[ln -vsf #{File.join(cur_dir, file)} #{target_for(file)}]
    end
  end
end