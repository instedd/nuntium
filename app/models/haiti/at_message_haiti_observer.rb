class AtMessageHaitiObserver < ActiveRecord::Observer
  
  observe ATMessage
  
  include HaitiFixes
  
  def before_create(m)
    if HAITI_APP_IDS.include? m.application_id
      m.from = haiti_fixed_number(m.from)
    end
    if APP_REDIRECT_AT_FROM_ID == m.application_id and APP_REDIRECT_PHONE == m.from
      redirect_app m
    end
  ensure
    true
  end
  
end