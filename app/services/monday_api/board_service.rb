module MondayAPI
  class BoardService
    def self.fetch_boards
      Rails.logger.debug "Starting to fetch boards from Monday.com..."

      query = <<~GRAPHQL
        query {
          boards {
            id
            name
            columns {
              id
              title
              type
            }
            groups {
              id
              title
            }
          }
        }
      GRAPHQL

      begin
        Rails.logger.debug "Executing query: #{query}"

        # Use the execute_query method from MondayAPI module
        result = MondayAPI.execute_query(query: query)
        Rails.logger.debug "Raw Response: #{result.inspect}"

        if result["errors"]
          Rails.logger.error "Monday.com API Errors: #{result['errors']}"
          return []
        end

        boards = result.dig("data", "boards")
        if boards.nil?
          Rails.logger.error "No boards data found in response"
          return []
        end

        Rails.logger.debug "Found #{boards.size} boards"
        boards.each do |board|
          Rails.logger.debug "Board: #{board['name']} (ID: #{board['id']})"
          Rails.logger.debug "  Columns: #{board['columns'].map { |c| c['title'] }.join(', ')}"
          Rails.logger.debug "  Groups: #{board['groups'].map { |g| g['title'] }.join(', ')}"
        end

        boards
      rescue => e
        Rails.logger.error "Unexpected error fetching boards: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        []
      end
    end
  end
end
