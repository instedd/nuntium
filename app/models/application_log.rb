class ApplicationLog < ActiveRecord::Base
  belongs_to :application
  belongs_to :channel
  belongs_to :ao_message
  belongs_to :at_message
  
  Info = 1
  Warning = 2
  Error = 3
  
  def severity_text
    case severity
    when Info
      'info'
    when Warning
      'warning'
    when Error
      'error'
    end
  end
  
  def severity_html
    case severity
    when Info
      'info'
    when Warning
      '<span style="color:yellow">warning</span>'
    when Error
      '<span style="color:red">error</span>'
    end
  end
end
