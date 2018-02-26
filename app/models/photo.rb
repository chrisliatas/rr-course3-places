class Photo

  def self.mongo_client
    Mongoid::Clients.default
  end
end