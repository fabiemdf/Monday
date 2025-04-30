class MondayApiService
  require "net/http"
  require "uri"
  require "json"

  def self.execute_query(query, variables = {})
    # Check if API key is present
    api_key = ENV["MONDAY_API_KEY"]
    if api_key.blank?
      Rails.logger.error("Monday.com API Key is missing or blank")
      return { "errors" => [ { "message" => "API key is missing. Please set the MONDAY_API_KEY environment variable." } ] }
    end

    uri = URI.parse("https://api.monday.com/v2")
    request = Net::HTTP::Post.new(uri)

    # Make sure to use the correct API key format
    request["Authorization"] = api_key.start_with?("Bearer ") ? api_key : "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request["API-Version"] = "2023-10" # Use a specific API version

    request.body = JSON.dump({
      query: query,
      variables: variables
    })

    # Log request details (without sensitive info)
    Rails.logger.debug("Monday.com API Request to: #{uri}")
    Rails.logger.debug("Monday.com API Key present: #{api_key.present?}")
    Rails.logger.debug("Monday.com API Key length: #{api_key&.length}")

    response = nil
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.read_timeout = 30 # Increase timeout to 30 seconds
      response = http.request(request)
    end

    # Log response details
    Rails.logger.debug("Monday.com API Response Code: #{response.code}")

    if response.code == "200"
      parsed_response = JSON.parse(response.body)

      # Check for API errors
      if parsed_response["errors"]
        Rails.logger.error("Monday.com API Returned Errors: #{parsed_response["errors"].inspect}")
      end

      parsed_response
    else
      Rails.logger.error("Monday.com API Error: #{response.code} - #{response.body}")
      { "errors" => [ { "message" => "API returned status code #{response.code}", "details" => response.body } ] }
    end
  rescue => e
    Rails.logger.error("Monday.com API Request Error: #{e.class.name} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    { "errors" => [ { "message" => "Exception: #{e.message}" } ] }
  end
end
