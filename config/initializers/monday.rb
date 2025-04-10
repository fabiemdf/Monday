require "net/http"
require "json"

module MondayAPI
  class << self
    def execute_query(query:, variables: {})
      Rails.logger.debug "Starting Monday.com API query execution..."
      Rails.logger.debug "Query: #{query}"
      Rails.logger.debug "Variables: #{variables.inspect}"

      begin
        uri = URI("https://api.monday.com/v2")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request["Authorization"] = "Bearer #{ENV['MONDAY_API_TOKEN']}"

        request.body = {
          query: query,
          variables: variables
        }.to_json

        Rails.logger.debug "Sending request to Monday.com API..."
        response = http.request(request)
        Rails.logger.debug "Response status: #{response.code}"
        Rails.logger.debug "Response body: #{response.body}"

        if response.code != "200"
          Rails.logger.error "API Error: #{response.code} - #{response.body}"
          return {}
        end

        JSON.parse(response.body)
      rescue => e
        Rails.logger.error "Error executing Monday.com API query: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        raise e
      end
    end
  end
end
