class Song < ApplicationRecord
    # belongs_to :artist
    has_and_belongs_to_many :playlists

    BACKEND_URL = 'https://algorhythm-nation.herokuapp.com/'
    FRONTEND_URL = 'http://localhost:3000'
    SPOTIFY_API = 'https://api.spotify.com/v1'

end
