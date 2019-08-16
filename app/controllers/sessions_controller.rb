class SessionsController < ApplicationController

  BACKEND_URL = 'http://localhost:8888'
  FRONTEND_URL = 'http://localhost:3000'
  SPOTIFY_API = 'https://api.spotify.com/v1'

  def login
    # requests the user to authorize linking to their spotify account
    query_params = {
        client_id: ENV['CLIENT_ID'],
        response_type: "code",
        redirect_uri: "#{BACKEND_URL}/callback",
        scope: "user-library-read playlist-read-collaborative playlist-modify-private playlist-modify-public playlist-read-private user-top-read",
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
          redirect_to 'http://localhost:8888/login/failure'
      else
          # assemble and send request to spotify for access and refresh token
          body = {
              grant_type: 'authorization_code',
              code: params[:code],
              redirect_uri: 'http://localhost:8888/callback',
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
          #! using the endpoint to get the user data
          user_response = RestClient.get("#{SPOTIFY_API}/me", header)
          # convert response.body to json fro assignment
          user_params = JSON.parse(user_response.body)
          
          # If the user already exists, set @user to the user, else create a new User
          if User.find_by(username: user_params['display_name'])
              @user = User.find_by(username: user_params['display_name'])
          else
              @user = User.create(
                  username: user_params['display_name'],
                  spotify_id: user_params['id'],
                  href: user_params['href'])
              @user.update(access_token: auth_params['access_token'], refresh_token: auth_params['refresh_token'])
              # fetch user's playlists
              @user.fetch_playlists
              # fetches user's spotify data to save into the db -- this is a slow process
              # @user.fetch_spotify_data
            end
          session[:user_id] = @user.id
          # redirect user to main page
          # FIXME: update to the correct route
          redirect_to "#{FRONTEND_URL}/user"
      end
  end

  def loginFailure
      puts 'login failure here'
      redirect_to "#{BACKEND_URL}/error"
  end

  def destroy
    session.clear
    redirect_to "#{FRONTEND_URL}"
  end

end
