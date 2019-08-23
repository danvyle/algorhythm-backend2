class PlaylistsController < ApplicationController
    # before_action :set_user

    BACKEND_URL = 'https://algorhythm-nation.herokuapp.com'
    FRONTEND_URL = 'https://algorhythm-nation.netlify.com'
    SPOTIFY_API = 'https://api.spotify.com/v1'

    def index
        # returns only the current user's playlists
        current_user = User.find_by(access_token: params[:token])
        playlists = current_user.playlists
        render json: playlists
    end

    def show
        playlist = Playlist.find(params[:id])
        playlist.fetch_songs(params[:token])
        render json: {playlist: playlist, songs: playlist.songs}
    end

    def new
        # getting the parameters from the front end
        popularity = params[:popularity]
        key = params[:key]
        acousticness = params[:acousticness]
        danceability = params[:danceability]
        energy = params[:energy]
        instrumentalness = params[:instrumentalness]
        liveness = params[:liveness]
        loudness = params[:loudness]
        speechiness = params[:speechiness]
        valence = params[:valence]
        tempo = params[:tempo]
    end

    def create
        current_user = User.find_by(access_token: params[:token])
        if current_user.access_token_expired?
            current_user.update_token
        end

        # ! this post is to create a playlist
        header = {
            'Authorization': "Bearer #{current_user.access_token}",
            'Content-Type': 'application/json'
        }
        body = {
            name: "#{params[:playlistname]} [Algorhythms]",
        }
        playlist_response = RestClient.post("https://api.spotify.com/v1/users/#{current_user.spotify_id}/playlists", body.to_json, header)
        playlist_params = JSON.parse(playlist_response.body)

        playlist = Playlist.new
        name = playlist_params['name']
        href = playlist_params['href']
        user_id = current_user.id
        spotify_id = playlist_params['id']

        playlist.update(name: name, href: href, user_id: user_id, spotify_id: spotify_id)

        # ! this post is to add tracks to the playlist
        tracks_body = {
            uris: params[:uris]
        }

        tracks_response = RestClient.post("https://api.spotify.com/v1/playlists/#{playlist.spotify_id}/tracks", tracks_body.to_json, header)
        tracks_params = JSON.parse(tracks_response.body)

        songs_array = params[:uris]
        songs_array.each{|song| playlist.songs << Song.find_by(uri: song)}


    end

    private

    def set_user
        # sets the current user using id before any actions
        current_user = User.find_by(access_token: params[:token])
    end

end
