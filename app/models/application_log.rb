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
      '<span style="color:#0D0D68">info</span>'
    when Warning
      '<span style="color:#FF8B17">warning</span>'
    when Error
      '<span style="color:red">error</span>'
    end
  end
end
