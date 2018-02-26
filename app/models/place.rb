class Place
  include Mongoid::Document

  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize(params)
    @id = params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
    @address_components = params[:address_components].map { |a| AddressComponent.new(a) } unless params[:address_components].nil?
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    mongo_client[:places]
  end

  def self.load_all(file)
    collection.insert_many(JSON.parse(file.read))
  end

  def self.find_by_short_name(short_name)
    collection.find("address_components.short_name" => short_name)
  end

  def self.to_places(places)
    places.map { |place| Place.new(place) }
  end

  def self.find(id)
    place = collection.find(_id: BSON::ObjectId.from_string(id)).first
    Place.new(place) unless place.nil?
  end

  def self.all(offset = 0, limit = 0)
    places = collection.find.skip(offset).limit(limit)
    to_places(places)
  end
end
