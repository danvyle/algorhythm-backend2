class User < ApplicationRecord
    has_many :playlists
    has_many :songs, :through => :playlists

    BACKEND_URL = 'https://algorhythm-nation.herokuapp.com'
    FRONTEND_URL = 'https://algorhythm-nation-front.herokuapp.com/'
    SPOTIFY_API = 'https://api.spotify.com/v1'

    def access_token_expired?
        # returns true if access_token is older than 55 minutes, based on update_at
        (Time.now.utc - self.updated_at) > 3300
    end

    def update_token
        # request new access token using refresh token
        # create body of request
        body = {
            grant_type: 'refresh_token',
            refresh_token: self.refresh_token,
            client_id: ENV['CLIENT_ID'],
            client_secret: ENV['CLIENT_SECRET']
        }
        # send the request and update the user's access token
        auth_response = RestClient.post('https://accounts.spotify.com/api/token', body)
        auth_params = JSON.parse(auth_response)
        self.update(access_token: auth_params['access_token'])
    end

    def fetch_spotify_data
        if self.access_token_expired?
            self.update_token
        end

        self.fetch_library
        self.fetch_playlists
    end

    def fetch_library

        if self.access_token_expired?
            self.update_token
        end

        token = self.access_token
        header = {Authorization: "Bearer #{token}"}
        #! using the endpoint to get the user's library of tracks
        library_response = RestClient.get("#{SPOTIFY_API}/me/tracks?limit=50", header)
        # max limit is 50

        # convert response.body to json
        library_params = JSON.parse(library_response.body)
        total_tracks = library_params['total']

        # Create a new library playlist for relating the user's songs that are not associated with a Spotify playist
        library_playlist = Playlist.create(user_id: self.id, name: "#{self.username} - Library")
        songs = library_params['items']

        library_playlist.save_songs(songs, token)
    end

    def fetch_playlists

        if self.access_token_expired?
            self.update_token
        end

        token = self.access_token
        header = { Authorization: "Bearer #{token}" }
        #! using the endpoint to get the user's playists
        playlists_response = RestClient.get("#{SPOTIFY_API}/me/playlists?limit=50", header)
        # max limit is 50

        # convert response.body to json
        playlists_params = JSON.parse(playlists_response.body)

        playlists = playlists_params['items']
        playlists.each do |list|
            user_id = self.id
            spotify_id = list['id']

            newplaylist = Playlist.find_or_create_by(spotify_id: spotify_id)

            name = list['name']
            href = list['href']
            total_tracks = list['tracks']['total']

            newplaylist.update(user_id: user_id, name: name, href: href, total_tracks: total_tracks)

        end
    end
end
