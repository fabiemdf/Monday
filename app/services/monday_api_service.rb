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

  def self.fetch_notes_for_linked_items(item_ids, notes_column_id)
    return [] if item_ids.blank?
    query = <<~GRAPHQL
      query {
        items(ids: [#{item_ids.join(',')}]) {
          id
          name
          column_values {
            id
            text
          }
        }
      }
    GRAPHQL

    response = execute_query(query)
    items = response.dig("data", "items") || []
    items.map do |item|
      {
        id: item["id"],
        name: item["name"],
        notes: item["column_values"].find { |col| col["id"] == notes_column_id }&.dig("text"),
        created_on: item["column_values"].find { |col| col["id"] == "text_mkq7k95" }&.dig("text"),
        entered_by: item["column_values"].find { |col| col["id"] == "text_mkq73g37" }&.dig("text")
      }
    end
  end

  def self.update_employee(id, attributes)
    mutations = []

    # Name update
    if attributes[:name].present?
      mutations << <<~GRAPHQL
        change_name: change_multiple_column_values(
          item_id: #{id},
          board_id: #{ENV['MONDAY_EMPLOYEES_BOARD_ID']},
          column_values: "{\\"name\\" : \\"#{attributes[:name]}\\"}"
        ) {
          id
        }
      GRAPHQL
    end

    # Email update
    if attributes[:email].present?
      mutations << <<~GRAPHQL
        change_email: change_multiple_column_values(
          item_id: #{id},
          board_id: #{ENV['MONDAY_EMPLOYEES_BOARD_ID']},
          column_values: "{\\"email_mkqhvt92\\": {\\"text\\": \\"#{attributes[:email]}\\", \\"email\\": \\"#{attributes[:email]}\\"}}"
        ) {
          id
        }
      GRAPHQL
    end

    # Phone update
    if attributes[:phone].present?
      phone_value = JSON.generate({ "phone": attributes[:phone], "countryShortName": "US" })
      mutations << <<~GRAPHQL
        change_phone: change_multiple_column_values(
          item_id: #{id},
          board_id: #{ENV['MONDAY_EMPLOYEES_BOARD_ID']},
          column_values: "{\\"phone_mkqhkyce\\": #{phone_value.gsub('"', '\\"')}}"
        ) {
          id
        }
      GRAPHQL
    end

    # Position update
    if attributes[:position].present?
      mutations << <<~GRAPHQL
        change_position: change_multiple_column_values(
          item_id: #{id},
          board_id: #{ENV['MONDAY_EMPLOYEES_BOARD_ID']},
          column_values: "{\\"text_mkqh1hrb\\": \\"#{attributes[:position]}\\"}"
        ) {
          id
        }
      GRAPHQL
    end

    # Status update
    if attributes[:status].present?
      mutations << <<~GRAPHQL
        change_status: change_multiple_column_values(
          item_id: #{id},
          board_id: #{ENV['MONDAY_EMPLOYEES_BOARD_ID']},
          column_values: "{\\"status\\": \\"#{attributes[:status]}\\"}"
        ) {
          id
        }
      GRAPHQL
    end

    return if mutations.empty?

    mutation = <<~GRAPHQL
      mutation {
        #{mutations.join("\n")}
      }
    GRAPHQL

    # Debug logging
    if Rails.env.development?
      Rails.logger.debug("\n\n=== Monday.com Mutation ===")
      Rails.logger.debug(mutation)
      Rails.logger.debug("=== End Mutation ===\n")
    end

    result = execute_query(mutation)

    # Debug logging
    if Rails.env.development?
      Rails.logger.debug("\n\n=== Monday.com Response ===")
      Rails.logger.debug(JSON.pretty_generate(result))
      Rails.logger.debug("=== End Response ===\n")
    end

    result
  end
end
