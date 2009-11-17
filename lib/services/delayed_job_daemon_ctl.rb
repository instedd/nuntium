require 'win32/service'
require 'rbconfig'
include Win32
include Config

SERVICE_NAME = 'NuntiumWorker'
SERVICE_DISPLAYNAME = 'Nuntium Worker'

# Quote the full path to deal with possible spaces in the path name.
ruby = File.join(CONFIG['bindir'], 'ruby').tr('/', '\\')
path = ' "' + File.dirname(File.expand_path($0)).tr('/', '\\')
path += '\delayed_job_daemon.rb"'
cmd = ruby + path

# You must provide at least one argument.
raise ArgumentError, 'No argument provided' unless ARGV[0]

case ARGV[0].downcase
   when 'install'
      Service.new(
         :service_name     => SERVICE_NAME,
         :display_name     => SERVICE_DISPLAYNAME,
         :description      => 'Runs nuntium jobs',
         :binary_path_name => cmd
      )
      puts 'Service ' + SERVICE_NAME + ' installed'      
   when 'start'
      if Service.status(SERVICE_NAME).current_state != 'running'
         Service.start(SERVICE_NAME)
         while Service.status(SERVICE_NAME).current_state != 'running'
            puts 'One moment...' + Service.status(SERVICE_NAME).current_state
            sleep 1
         end
         puts 'Service ' + SERVICE_NAME + ' started'
      else
         puts 'Already running'
      end
   when 'stop'
      if Service.status(SERVICE_NAME).current_state != 'stopped'
         Service.stop(SERVICE_NAME)
         while Service.status(SERVICE_NAME).current_state != 'stopped'
            puts 'One moment...' + Service.status(SERVICE_NAME).current_state
            sleep 1
         end
         puts 'Service ' + SERVICE_NAME + ' stopped'
      else
         puts 'Already stopped'
      end
   when 'uninstall', 'delete'
      if Service.status(SERVICE_NAME).current_state != 'stopped'
         Service.stop(SERVICE_NAME)
      end
      while Service.status(SERVICE_NAME).current_state != 'stopped'
         puts 'One moment...' + Service.status(SERVICE_NAME).current_state
         sleep 1
      end
      Service.delete(SERVICE_NAME)
      puts 'Service ' + SERVICE_NAME + ' deleted'
   when 'pause'
      if Service.status(SERVICE_NAME).current_state != 'paused'
         Service.pause(SERVICE_NAME)
         while Service.status(SERVICE_NAME).current_state != 'paused'
            puts 'One moment...' + Service.status(SERVICE_NAME).current_state
            sleep 1
         end
         puts 'Service ' + SERVICE_NAME + ' paused'
      else
         puts 'Already paused'
      end
   when 'resume'
      if Service.status(SERVICE_NAME).current_state != 'running'
         Service.resume(SERVICE_NAME)
         while Service.status(SERVICE_NAME).current_state != 'running'
            puts 'One moment...' + Service.status(SERVICE_NAME).current_state
            sleep 1
         end
         puts 'Service ' + SERVICE_NAME + ' resumed'
      else
         puts 'Already running'
      end
   else
      raise ArgumentError, 'unknown option: ' + ARGV[0]
end

