class Photo
  include Mongoid::Document
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

  def persisted?
    !@id.nil?
  end

  def save
    if !persisted?
      gps = EXIFR::JPEG.new(@contents).gps
      location = Point.new(lng: gps.longitude, lat: gps.latitude)
      description = {}
      description[:content_type] = "image/jpeg"
      description[:metadata] = { location: location.to_hash, place: @place }
      @location = Point.new(location.to_hash)
      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      id = Place.mongo_client.database.fs.insert_one(grid_file)
      @id = id.to_s
    else
      doc = Photo.mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(@id)).first
      doc[:metadata][:location] = @location.to_hash
      doc[:metadata][:place] = @place
      Photo.mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(@id)).update_one(doc)
    end
  end
end