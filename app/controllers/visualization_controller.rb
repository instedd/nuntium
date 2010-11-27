class VisualizationController < AccountAuthenticatedController
  def ao_state_by_day
    messages_state_by_day :ao
  end

  def at_state_by_day
    messages_state_by_day :at
  end

  private

  def messages_state_by_day(kind)
    @hide_title = true
    @kind = kind
    @two_months_ago = Date.today - 2.months
    if @two_months_ago.year == Date.today.year
      @prefix = "#{Date.today.year}-"
      @month_and_day = "concat(month(updated_at), '-', day(updated_at))"
    else
      @month_and_day = "concat(toDate(updated_at))"
    end
    @two_months_ago = @two_months_ago.strftime '%Y-%m-%d'
    render 'messages_state_by_day'
  end
end
