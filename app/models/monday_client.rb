# app/models/monday_client.rb
# Place this file in the app/models directory for Rails autoloading
require "net/http"
require "uri"
require "json"

class MondayClient
  API_URL = "https://api.monday.com/v2"

  def initialize
    @api_key = ENV["MONDAY_API_KEY"] || "eyJhbGciOiJIUzI1NiJ9.eyJ0aWQiOjM0OTQ4ODM4MywiYWFpIjoxMSwidWlkIjo1ODgzMzI4OSwiaWFkIjoiMjAyNC0wNC0xOVQxMDoyNjo0OC4wMDBaIiwicGVyIjoibWU6d3JpdGUiLCJhY3RpZCI6MjI2NjU3MDIsInJnbiI6InVzZTEifQ.1fcBqPcyKSfEN0VF-6M2ecVu1gGBg2D2vE6OTSHbEKg"  # Replace with your actual API key if not using ENV
  end

  def query(query_str, variables = {})
    uri = URI.parse(API_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = @api_key
    request.body = {
      query: query_str,
      variables: variables
    }.to_json

    response = http.request(request)

    if response.code.to_i >= 200 && response.code.to_i < 300
      JSON.parse(response.body)
    else
      Rails.logger.error("Monday API error: #{response.code} - #{response.body}")
      raise "Monday API error: #{response.code} - #{response.body}"
    end
  end
end
