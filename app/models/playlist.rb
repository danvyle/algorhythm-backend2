class Playlist < ApplicationRecord
    belongs_to :user
    has_and_belongs_to_many :songs
    # has_many :artists, :through => :songs

    BACKEND_URL = 'https://algorhythm-nation.herokuapp.com/'
    FRONTEND_URL = 'http://localhost:3000'
    SPOTIFY_API = 'https://api.spotify.com/v1'

    def fetch_songs(token)
        current_user = User.find_by(access_token: token)
        if current_user.access_token_expired?
            current_user.update_token
        end

        header = {Authorization: "Bearer #{token}"}

        #! using the endpoint to get playlist's tracks
        tracks_response = RestClient.get(self.href, header)

        # convert response.body to json
        tracks_params = JSON.parse(tracks_response.body)
        songs = tracks_params['tracks']['items']

        self.save_songs(songs, token)

    end

    def save_songs(array, token)

        header = {Authorization: "Bearer #{token}"}
        array.each do |song|

            song = song['track']
            spotify_id = song['id']

            @target_song = Song.find_by(spotify_id: spotify_id)

            if !@target_song
            # if the song not found in the database, create a new song
                name = song['name']
                duration_ms = song['duration_ms']
                href = song['href']
                popularity = song['popularity']
                img = song['album']['images'][1]['url']
                artist_array = []
                song['artists'].each{|artist| artist_array << artist['name']}
                artist_array = artist_array.join(', ')
                uri = song['uri']

                # doing another fetch for audio features
                #! using the endpoint to get the track's audio features
                track_response = RestClient.get("#{SPOTIFY_API}/audio-features/#{spotify_id}", header)
                # convert response.body to json
                track_params = JSON.parse(track_response.body)

                danceability = track_params['danceability']
                key = track_params['key']
                acousticness = track_params['acousticness']
                energy = track_params['energy']
                instrumentalness = track_params['instrumentalness']
                liveness = track_params['liveness']
                loudness = track_params['loudness']
                speechiness = track_params['speechiness']
                valence = track_params['valence']
                tempo = track_params['tempo']

                @target_song = Song.create(name: name, duration_ms: duration_ms, href: href, popularity: popularity, danceability: danceability, key: key, acousticness: acousticness, energy: energy, instrumentalness: instrumentalness, liveness: liveness, loudness: loudness, speechiness: speechiness, valence: valence, tempo: tempo, img: img, artist: artist_array, uri: uri, spotify_id: spotify_id)

                self.songs << @target_song
            else
               @target_song
            end
        end
    end


    def energy(level)
        min_range = level - 0.125
        min_range < 0 ? min_range = 0 : min_range
        max_range = level + 0.125
        max_range > 1 ? max_range = 1 : max_range

        # filter songs based on energy level

    end

end
