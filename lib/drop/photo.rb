module Drop
  class Photo < Liquid::Drop
    delegate :file?,
             :to => :photo

    def initialize(photo)
      @photo = photo
    end
    
    def url
      photo.url
    end
    
    def blast_url
      photo.url :blast
    end
    
    def facebook_url
      photo.url :facebook
    end
    
    def standard_url
      photo.url :standard
    end

    def alternate_standard_url
      photo.url :alternate_standard
    end
    
    def thumbnail_url
      photo.url :thumbnail
    end
    
    def email_url
      photo.url :email
    end
    
    private
    
    def photo
      @photo
    end
  end
end
