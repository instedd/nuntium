class ThrottledJob < ActiveRecord::Base
  belongs_to :channel
  
   # Add a job to the queue with channel_id as the first argument
  def self.enqueue(*args)
    channel_id = args.shift
  
    object = args.shift
    unless object.respond_to?(:perform)
      raise ArgumentError, 'Cannot enqueue items which do not respond to perform'
    end
    self.create(:channel_id => channel_id, :payload_object => object)
  end
  
  def payload_object
    @payload_object ||= deserialize(self['handler'])
  end
  
  def payload_object=(object)
    self['handler'] = object.to_yaml
  end
  
  private
 
  def deserialize(source)
    handler = YAML.load(source) rescue nil

    unless handler.respond_to?(:perform)
      if handler.nil? && source =~ ParseObjectFromYaml
        handler_class = $1
      end
      attempt_to_load(handler_class || handler.class)
      handler = YAML.load(source)
    end

    return handler if handler.respond_to?(:perform)

    raise DeserializationError,
      'Job failed to load: Unknown handler. Try to manually require the appropriate file.'
  rescue TypeError, LoadError, NameError => e
    raise DeserializationError,
      "Job failed to load: #{e.message}. Try to manually require the required file."
  end

  # Constantize the object so that ActiveSupport can attempt
  # its auto loading magic. Will raise LoadError if not successful.
  def attempt_to_load(klass)
     klass.constantize
  end
  
end
