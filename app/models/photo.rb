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

  def self.all(offset = 0, limit = 0)
    mongo_client.database.fs.find.skip(offset).limit(limit).map { |doc| Photo.new(doc) }
  end

  def self.find(id)
    doc = mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(id)).first
    Photo.new(doc) unless doc.nil?
  end

  def contents
    f = Photo.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id))

    if f
      bfr = ""
      f.chunks.reduce([]) do |x, chunk|
        bfr << chunk.data.data
      end
      return bfr
    end
  end

  def destroy
    Photo.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end

  def find_nearest_place_id(maxdis)
    place = Place.near(@location, maxdis).limit(1).projection(:_id => 1).first
    if place.nil?
      return nil
    else
      return place[:_id]
    end
  end

  def place
    Place.find(@place.to_s) unless @place.nil?
  end

  def place=(place)
    @place = if place.class == Place
               BSON::ObjectId.from_string(place.id)
             elsif place.class == String
               BSON::ObjectId.from_string(place)
             else
               place
             end
  end

  def self.find_photos_for_place id
    mongo_client.database.fs.find('metadata.place' => BSON::ObjectId.from_string(id))
  end
end
