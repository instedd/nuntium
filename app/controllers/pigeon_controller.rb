class PigeonController < ApiAuthenticatedController
  helper Pigeon::Engine.helpers
  layout 'pigeon'

  def new
    unless params[:kind]
      return render :select_kind
    end

    @pigeon_channel = Pigeon::NuntiumChannel.new kind: params[:kind]
  end

  def create
    @pigeon_channel = Pigeon::NuntiumChannel.new kind: params[:channel][:kind]
    @pigeon_channel.assign_attributes params[:channel_data]

    @channel = Channel.from_hash @pigeon_channel.attributes.reject { |k,v| k == 'configuration' }, :json
    @channel.name = params[:channel][:name]
    @channel.configuration = @pigeon_channel.attributes[:configuration]
    @channel.account = @account
    @channel.application = @application
    if @channel.save
      render :done
    else
      @channel.errors.each do |name, message|
          if @pigeon_channel.attributes.include? name
            @pigeon_channel.errors.add name, message
          elsif @pigeon_channel.configuration.include? name
            @pigeon_channel.errors.add "configuration[#{name}]", message
          else
            @pigeon_channel.errors.add :base, "#{name} #{message}"
          end
        end

      render :new
    end
  end
end
