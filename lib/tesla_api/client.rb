module TeslaApi
  class Client
    include HTTParty
    base_uri 'https://owner-api.teslamotors.com/api/1'
    headers 'User-Agent' => "github.com/timdorr/tesla-api v:#{VERSION}"
    format :json

    attr_reader :email, :token, :refresh_token, :client_id, :client_secret

    def initialize(email, client_id = ENV['TESLA_CLIENT_ID'], client_secret = ENV['TESLA_CLIENT_SECRET'])
      @email = email
      @client_id = client_id
      @client_secret = client_secret
    end

    def token=(token)
      @token = token
      self.class.headers 'Authorization' => "Bearer #{token}"
    end

    def expires_in=(seconds)
      @expires_in = seconds.to_f
    end

    def created_at=(timestamp)
      @created_at = Time.at(timestamp.to_f).to_datetime
    end

    def expired_at
      return nil unless defined?(@created_at)
      (@created_at.to_time + @expires_in.to_f).to_datetime
    end

    def expired?
      return true unless defined?(@created_at)
      expired_at <= DateTime.now
    end

    def login!(password)
      response = self.class.post(
          'https://owner-api.teslamotors.com/oauth/token',
          body: {
              grant_type: 'password',
              client_id: client_id,
              client_secret: client_secret,
              email: email,
              password: password
          }
      )

      self.expires_in    = response['expires_in']
      self.created_at    = response['created_at']
      self.token         = response['access_token']
      self.refresh_token = response['refresh_token']
    end

    def vehicles
      self.class.get('/vehicles')['response'].map { |v| Vehicle.new(self.class, email, v['id'], v) }
    end

    private

    attr_writer :refresh_token
  end
end
