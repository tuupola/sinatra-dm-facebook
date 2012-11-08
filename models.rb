class User
  include DataMapper::Resource
  property :id,            Serial
  property :uid,           Integer, :min => 0, :max => 2**32
  property :oauth_token,   String, :length => 255
  property :name,          String
  property :created_at,    DateTime
    
  def first_name
    split = full_name.split(" ", 2)
    split.first
  end

  # Avoid ruby errors if FB did not return name.
  def full_name
    name || ""
  end
  
  def profile_url
    "http://www.facebook.com/profile.php?id=#{uid}"
  end
  
  def image_url
    "https://graph.facebook.com/#{uid}/picture?type=square"
  end
    
end

DataMapper.auto_upgrade!
DataMapper.finalize
