module DaemonController

  require 'win32/service'
  require 'rbconfig'
  include Win32
  include Config
  
  def run(option)

    raise ArgumentError, 'No argument provided' unless option
  
    # Quote the full path to deal with possible spaces in the path name.
    ruby = File.join(CONFIG['bindir'], 'ruby').tr('/', '\\')
    path = ' "' + File.dirname(File.expand_path($0)).tr('/', '\\')
    path += '\\'+ @service_file + '"'
    cmd = ruby + path + ' ' + @service_parameters
  
    case option.downcase
       
       when 'install'
          Service.new(
             :service_name    => @service_name,
             :display_name     => @service_displayname,
             :description      => @service_description,
             :binary_path_name => cmd
          )
          puts 'Service ' + @service_name + ' installed'      
       
       when 'start'
          if Service.status(@service_name).current_state != 'running'
             Service.start(@service_name)
             while Service.status(@service_name).current_state != 'running'
                puts 'One moment...' + Service.status(@service_name).current_state
                sleep 1
             end
             puts 'Service ' + @service_name + ' started'
          else
             puts 'Already running'
          end
       
       when 'stop'
          if Service.status(@service_name).current_state != 'stopped'
             Service.stop(@service_name)
             while Service.status(@service_name).current_state != 'stopped'
                puts 'One moment...' + Service.status(@service_name).current_state
                sleep 1
             end
             puts 'Service ' + @service_name + ' stopped'
          else
             puts 'Already stopped'
          end
       
       when 'uninstall', 'delete'
          if Service.status(@service_name).current_state != 'stopped'
             Service.stop(@service_name)
          end
          while Service.status(@service_name).current_state != 'stopped'
             puts 'One moment...' + Service.status(@service_name).current_state
             sleep 1
          end
          Service.delete(@service_name)
          puts 'Service ' + @service_name + ' deleted'
       
       when 'pause'
          if Service.status(@service_name).current_state != 'paused'
             Service.pause(@service_name)
             while Service.status(@service_name).current_state != 'paused'
                puts 'One moment...' + Service.status(@service_name).current_state
                sleep 1
           end
           puts 'Service ' + @service_name + ' paused'
        else
           puts 'Already paused'
        end
        
      when 'resume'
        if Service.status(@service_name).current_state != 'running'
           Service.resume(@service_name)
           while Service.status(@service_name).current_state != 'running'
              puts 'One moment...' + Service.status(@service_name).current_state
              sleep 1
           end
           puts 'Service ' + @service_name + ' resumed'
        else
           puts 'Already running'
        end
      
     when 'info'
       puts @service_name + ': ' + @service_description
       
     when 'help'
       puts 'Invoke with one of the following: install, start, stop, pause, resume, uninstall, delete, info, help'
     
     else
        raise ArgumentError, "Unknown option: '#{option}'" 

    end
  end
end