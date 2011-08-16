module MessageSearch
  extend ActiveSupport::Concern

  module ClassMethods
    def search(search)
      def esc(name)
        ActiveRecord::Base.connection.quote_column_name name.to_s
      end

      result = self

      search = Search.new search

      if search.search
        if search.search.integer?
          result = result.where "id = :exact_search OR #{esc :guid} LIKE :search OR channel_relative_id LIKE :search OR #{esc :from} LIKE :search OR #{esc :to} LIKE :search OR subject LIKE :search OR body LIKE :search", :search => "%#{search.search}%", :exact_search => search.search
        else
          result = result.where "#{esc :guid} LIKE :search OR channel_relative_id LIKE :search OR #{esc :from} LIKE :search OR #{esc :to} LIKE :search OR subject LIKE :search OR body LIKE :search", :search => "%#{search.search}%"
        end
      end

      [:id, :tries].each do |sym|
        if search[sym]
          op, val = Search.get_op_and_val search[sym]
          result = result.where "#{esc sym} #{op} ?", val.to_i
        end
      end
      [:guid, :channel_relative_id, :from, :to, :subject, :body, :state].each do |sym|
        result = result.where "#{esc sym} LIKE ?", "%#{search[sym]}%" if search[sym]
      end
      if search[:after]
        after = Time.smart_parse search[:after]
        result = result.where "timestamp >= ?", after if after
      end
      if search[:before]
        before = Time.smart_parse search[:before]
        result = result.where "timestamp <= ?", before if before
      end
      if search[:updated_at]
        updated_at = Time.smart_parse search[:updated_at]
        result = result.where "updated_at >= ? AND updated_at < ?", updated_at, (updated_at + 1.day) if updated_at
      end
      result = result.joins(:channel).where 'channels.name = ?', search[:channel] if search[:channel]
      result = result.joins(:application).where 'applications.name = ?', search[:application] if search[:application]
      result
    end
  end
end
