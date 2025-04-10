module MondayAPI
  class ClaimService
    def self.fetch_claims
      Rails.logger.debug "Starting to fetch claims from Monday.com..."

      query = <<~GRAPHQL
        query {
          boards(ids: [8768750186]) {
            id
            name
            items_page {
              items {
                id
                name
                column_values {
                  id
                  text
                  value
                }
                group {
                  title
                }
                created_at
                updated_at
              }
            }
          }
        }
      GRAPHQL

      begin
        Rails.logger.debug "Executing query: #{query}"
        response = MondayAPI.execute_query(query: query)
        Rails.logger.debug "Raw Monday.com API Response: #{response.inspect}"

        if response["errors"]
          Rails.logger.error "Monday.com API Errors: #{response['errors']}"
          return []
        end

        boards = response.dig("data", "boards")
        if boards.nil? || boards.empty?
          Rails.logger.error "No boards data found in response"
          return []
        end

        # Get the first board's items
        items = boards.first.dig("items_page", "items")
        Rails.logger.debug "Found #{items.size} items"

        items.map do |item|
          {
            id: item["id"],
            name: item["name"],
            column_values: item["column_values"].map { |cv| [ cv["text"], cv["value"] ] }.to_h,
            group: item["group"]["title"],
            created_at: item["created_at"],
            updated_at: item["updated_at"]
          }
        end
      rescue => e
        Rails.logger.error "Error fetching claims from Monday.com: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        []
      end
    end

    private

    def self.format_claim(item)
      Rails.logger.debug "Formatting claim item: #{item.inspect}"

      claim = {
        id: item["id"],
        claim_number: get_column_value(item, "claim_number"),
        client_name: get_column_value(item, "client_name"),
        date_filed: parse_date(get_column_value(item, "date_filed")),
        status: get_column_value(item, "status")&.downcase,
        amount: parse_amount(get_column_value(item, "amount")),
        group: item.dig("group", "title"),
        created_at: item["created_at"],
        updated_at: item["updated_at"]
      }

      Rails.logger.debug "Formatted claim: #{claim.inspect}"
      claim
    end

    def self.get_column_value(item, column_title)
      column = item["column_values"]&.find { |col| col["title"] == column_title }
      Rails.logger.debug "Looking for column '#{column_title}' in item: #{item['column_values']&.map { |c| c['title'] }}"
      Rails.logger.debug "Found column: #{column.inspect}"

      return nil unless column

      case column["value"]
      when "{}"
        nil
      else
        column["value"]
      end
    end

    def self.parse_date(date_string)
      return nil unless date_string
      Date.parse(date_string)
    rescue Date::Error
      nil
    end

    def self.parse_amount(amount_string)
      return 0 unless amount_string
      amount_string.gsub(/[^0-9.]/, "").to_f
    rescue
      0
    end
  end
end
