class Photo
  attr_accessor :id, :location
  attr_writer :contents

  def initialize(params = nil)
    @id = params[:_id].to_s unless params.nil?
    @location = Point.new(params[:metadata][:location]) unless params.nil?
    @place = params[:metadata][:place] unless params.nil?
  end
  
  def self.mongo_client
    Mongoid::Clients.default
  end
end