# app/services/monday_api/client_service.rb
module MondayAPI
  class ClientService
    def self.fetch_clients
      Rails.logger.debug "Starting to fetch clients from Monday.com..."

      query = <<~GRAPHQL
        query {
          boards(ids: [8768750185]) {
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
            groups {
              id
              title
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
          return {}
        end

        boards = response.dig("data", "boards")
        if boards.nil? || boards.empty?
          Rails.logger.error "No boards data found in response"
          return {}
        end

        # Return the first board's data in the format expected by the view
        board = boards.first
        {
          "groups" => board["groups"],
          "items_page" => board["items_page"]
        }
      rescue => e
        Rails.logger.error "Error fetching clients from Monday.com: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        {}
      end
    end

    def self.fetch_client(client_id)
      query = <<~GRAPHQL
        query {
          items(ids: [#{client_id}]) {
            id
            name
            column_values {
              id
              text
              value
            }
            subitems {
              id
              name
            }
          }
        }
      GRAPHQL

      response = MondayAPI.execute_query(query)

      if response["errors"]
        Rails.logger.error("Monday API GraphQL Errors: #{response['errors']}")
        return nil
      end

      response["data"]["items"].first
    rescue => e
      Rails.logger.error("Error fetching client from Monday.com: #{e.message}")
      Rails.logger.error("Error backtrace: #{e.backtrace.join("\n")}")
      nil
    end

    private

    def self.format_client(item)
      {
        id: item["id"],
        name: item["name"],
        email: get_column_value(item, "email"),
        phone: get_column_value(item, "phone"),
        address: get_column_value(item, "address"),
        group: item.dig("group", "title"),
        created_at: item["created_at"],
        updated_at: item["updated_at"]
      }
    end

    def self.get_column_value(item, column_title)
      column = item["column_values"]&.find { |col| col["text"] == column_title }
      return nil unless column

      case column["value"]
      when "{}"
        nil
      else
        column["value"]
      end
    end
  end
end
