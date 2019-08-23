class UsersController < ApplicationController

    BACKEND_URL = 'https://algorhythm-nation.herokuapp.com'
    FRONTEND_URL = 'https://algorhythm-nation.netlify.com'
    SPOTIFY_API = 'https://api.spotify.com/v1'

    def login
        # requests the user to authorize linking to their spotify account
        query_params = {
            client_id: ENV['CLIENT_ID'],
            response_type: "code",
            redirect_uri: "#{BACKEND_URL}/callback",
            scope: "user-library-read
                    playlist-read-collaborative
                    playlist-modify-private
                    playlist-modify-public
                    playlist-read-private
                    user-top-read
                    streaming
                    user-read-email",
            show_dialog: true
        }
        url = 'https://accounts.spotify.com/authorize/'
        # redirects user's browser to Spotify's authorization page, which details scopes the app is requestiong
        redirect_to "#{url}?#{query_params.to_query}"
    end

    def callback
        if params[:error]
            # return error if there is one
            puts 'LOGIN ERROR', params
            redirect_to 'https://algorhythm-nation.herokuapp.com/login/failure'
        else
            # assemble and send request to spotify for access and refresh token
            body = {
                grant_type: 'authorization_code',
                code: params[:code],
                redirect_uri: 'https://algorhythm-nation.herokuapp.com/callback',
                client_id: ENV['CLIENT_ID'],
                client_secret: ENV['CLIENT_SECRET']
            }
            auth_response = RestClient.post('https://accounts.spotify.com/api/token', body)
            # convert response body to json for assignment
            auth_params = JSON.parse(auth_response.body)

            # assemble and send request to Spotify for user profile information
            header = {
                Authorization: "Bearer #{auth_params['access_token']}"
            }

            user_response = RestClient.get("#{SPOTIFY_API}/me", header)
            # convert response.body to json fro assignment
            user_params = JSON.parse(user_response.body)

            # If the user already exists, set @user to the user, else create a new User
            if User.find_by(username: user_params['display_name'])
                @user = User.find_by(username: user_params['display_name'])
                if @user.access_token_expired?
                    @user.update_token
                end
            else
                @user = User.create(
                    username: user_params['display_name'],
                    spotify_id: user_params['id'],
                    href: user_params['href'])
                @user.update(access_token: auth_params['access_token'], refresh_token: auth_params['refresh_token'])
            end
            # fetch user's playlists
            @user.fetch_playlists
            @user.fetch_library

            # pass back the access token to the front end
            redirect_to "https://algorhythm-nation.netlify.com/user?token=#{@user.access_token}"
        end
    end

    def loginFailure
        puts 'login failure here'
        redirect_to "#{FRONTEND_URL}/error"
    end

    def index
        current_user = User.find_by(access_token: params[:token])
        render json: current_user
    end

    private

        def set_user

        end

end
