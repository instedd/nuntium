class AtMessageHaitiObserver < ActiveRecord::Observer
  
  observe ATMessage
  include HaitiFixes
  
  def before_create(m)
    if HAITI_APP_IDS.include? m.application_id
      m.from = haiti_fixed_number(m.from)
    end
  end
  
end