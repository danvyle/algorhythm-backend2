class Song < ApplicationRecord
    # belongs_to :artist
    has_and_belongs_to_many :playlists

    BACKEND_URL = 'https://algorhythm-nation.herokuapp.com'
    FRONTEND_URL = 'https://algorhythm-nation-front.herokuapp.com/'
    SPOTIFY_API = 'https://api.spotify.com/v1'

end
