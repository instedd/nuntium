module MessageFilter

  def build_ao_messages_filter
    @ao_page = params[:ao_page]
    @ao_page = 1 if @ao_page.blank?    
    @ao_search = params[:ao_search]
    @ao_previous_search = params[:ao_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @ao_page = 1 if !@ao_previous_search.blank? and @ao_previous_search != @ao_search
    @ao_conditions = build_message_filter(@ao_search)
  end
  
  def build_at_messages_filter
    @at_page = params[:at_page]
    @at_page = 1 if @at_page.blank?    
    @at_search = params[:at_search]
    @at_previous_search = params[:at_previous_search]
    # Reset pages if search changes (so as to not stay in a later page that doesn't exist in the new result set)
    @at_page = 1 if !@at_previous_search.blank? and @at_previous_search != @at_search
    @at_conditions = build_message_filter(@at_search)
  end
  
  def build_message_filter(search)
    search = Search.new(search)
    conds = ['application_id = :application_id', { :application_id => @application.id }]
    if !search.search.nil?
      conds[0] += ' AND ([id] = :search_exact OR [guid] = :search_exact OR [channel_relative_id] = :search_exact OR [from] LIKE :search OR [to] LIKE :search OR subject LIKE :search OR body LIKE :search)'
      conds[1][:search_exact] = search.search
      conds[1][:search] = '%' + search.search + '%'
    end
    
    [:id, :guid, :channel_relative_id, :tries].each do |sym|
      if !search[sym].nil?
        conds[0] += " AND [#{sym}] = :#{sym}"
        conds[1][sym] = search[sym]
      end
    end
    [:from, :to, :subject, :body, :state].each do |sym|
      if !search[sym].nil?
        conds[0] += " AND [#{sym}] LIKE :#{sym}"
        conds[1][sym] = '%' + search[sym] + '%'
      end
    end
    if !search[:after].nil?
      begin
        after = Time.parse(search[:after])
        conds[0] += ' AND timestamp >= :after'
        conds[1][:after] = after
      rescue
      end
    end
    if !search[:before].nil?
      begin
        before = Time.parse(search[:before])
        conds[0] += ' AND timestamp <= :before'
        conds[1][:before] = before
      rescue
      end
    end
    conds
  end

end