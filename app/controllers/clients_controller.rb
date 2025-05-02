# app/controllers/clients_controller.rb
class ClientsController < ApplicationController
  before_action :set_client, only: [ :show, :edit, :update ]

  # Include helper methods from ApplicationHelper
  include ApplicationHelper

  # Make sure to require the service
  require_relative "../services/monday_api_service"

  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page_size = params[:per_page].to_i
    @page_size = 10 if @page_size < 1 # Default to 10 items per page

    # Set up the Monday client
    @monday = MondayClient.new unless defined?(@monday)

    # Get all clients with their column values
    # Replace the board ID with your actual Monday.com Clients Board ID
    board_id = ENV["MONDAY_CLIENTS_BOARD_ID"] || "8768750185"
    query = <<~GRAPHQL
      query {
        boards(ids: [#{ENV['MONDAY_CLIENTS_BOARD_ID']}]) {
          groups {
            id
            title
          }
          items_page(limit: 500) {
            items {
              id
              name
              group {
                id
                title
              }
              column_values {
                id
                text
                value
                type
              }
            }
          }
        }
      }
    GRAPHQL

    begin
      # Execute the query
      response = @monday.query(query)
      @clients_data = response.to_h

      # Log the response structure for debugging
      Rails.logger.debug "Monday API Response for clients: #{@clients_data.keys}"

      # Extract board data
      all_items = @clients_data.dig("data", "boards", 0, "items_page", "items") || []

      # Get all groups for reference
      groups = @clients_data.dig("data", "boards", 0, "groups") || []

      # Filter by search term if provided
      if params[:search].present?
        search_term = params[:search].downcase
        all_items = all_items.select do |item|
          item["name"].downcase.include?(search_term) ||
          item["column_values"].any? do |col|
            col["text"].to_s.downcase.include?(search_term)
          end
        end
      end

      # Filter by status if provided
      if params[:status].present?
        status_term = params[:status].downcase
        all_items = all_items.select do |item|
          status_col = item["column_values"].find { |col| col["id"] == "status" }
          if status_col && status_col["text"].present?
            status_col["text"].downcase == status_term
          else
            false
          end
        end
      end

      # Sort items if requested
      if params[:sort].present?
        sort_method, sort_direction = params[:sort].split("_")
        direction = sort_direction == "desc" ? -1 : 1

        # Determine the column to sort by
        column_key = case sort_method
        when "name" then "name"
        when "status" then "status"
        when "phone" then "phone" # You'll need to update these IDs
        when "email" then "email" # to match your actual Monday.com
        when "address" then "address" # column IDs
        when "person" then "person"
        when "date" then "date"
        else "name"
        end

        # Sort the items
        all_items = all_items.sort_by do |item|
          if column_key == "name"
            item["name"].to_s.downcase
          else
            value = get_column_by_id_helper(item, column_key)

            # Special handling for date and numbers
            if column_key.start_with?("date_")
              begin
                Date.parse(value.to_s) rescue Date.new(1900, 1, 1)
              rescue
                Date.new(1900, 1, 1)
              end
            elsif column_key.start_with?("numeric_")
              begin
                value.to_f
              rescue
                0.0
              end
            else
              value.to_s.downcase
            end
          end
        end

        # Apply sort direction
        all_items = direction == -1 ? all_items.reverse : all_items
      end

      # Group by group title
      @clients_by_group = all_items.group_by { |item| item.dig("group", "title") || "Ungrouped" }

      # Sort groups by title
      @sorted_groups = @clients_by_group.keys.sort
    rescue => e
      Rails.logger.error "Error fetching clients: #{e.message}"
      Rails.logger.error "Response: #{@clients_data.inspect}" if defined?(@clients_data)
      flash.now[:alert] = "Error loading clients. Please try again later."
      @clients_by_group = {}
      @sorted_groups = []
    end
  end

  def show
    monday_id = params[:id]

    begin
      # Check if API key is present
      if ENV["MONDAY_API_KEY"].blank?
        flash[:alert] = "Monday.com API key is missing. Please check your environment variables."
        redirect_to clients_path and return
      end

      # First, fetch the client details
      query = <<~GRAPHQL
        query {
          items(ids: [#{monday_id}]) {
            id
            name
            group {
              id
              title
            }
            column_values {
              id
              text
              value
              type
            }
          }
        }
      GRAPHQL

      response = MondayApiService.execute_query(query)

      if response && response["data"] && response["data"]["items"] && response["data"]["items"].any?
        @client = response["data"]["items"].first

        # Get column values in a more accessible format
        @column_values = {}
        @client["column_values"].each do |col|
          @column_values[col["id"]] = col["text"].present? ? col["text"] : "N/A"
        end

        # Fetch related claims for this client
        @related_claims = fetch_related_claims(monday_id)

        # Render the show view
        render :show
      else
        # More detailed error message
        error_message = "Client not found or error retrieving client data."
        if response && response["errors"]
          error_message += " API Errors: #{response["errors"].inspect}"
        end

        Rails.logger.error(error_message)
        flash[:alert] = Rails.env.development? ? error_message : "Client not found or error retrieving client data."
        redirect_to clients_path
      end
    rescue => e
      # More detailed error logging
      Rails.logger.error("Error in clients#show: #{e.class.name}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # More informative error message in development
      if Rails.env.development?
        flash[:alert] = "Error: #{e.class.name} - #{e.message}"
      else
        flash[:alert] = "Error retrieving client data. Please try again later."
      end
      redirect_to clients_path
    end
  end

  def new
    # This action just renders the new.html.erb template
  end

  def edit
    # Set in before_action
  end

  def update
    client = Monday::Client.new(token: ENV["MONDAY_API_TOKEN"])

    # Build mutation for updating the client

    mutation = <<~GRAPHQL
      mutation {
        change_multiple_column_values(
          item_id: #{@client["id"]},#{' '}
          board_id: 8768750185,#{' '}
          column_values: #{column_values_json}
        ) {
          id
        }
      }
    GRAPHQL

    result = client.query(mutation)

    if result.dig("data", "change_multiple_column_values", "id").present?
      redirect_to client_path(@client["id"]), notice: "Client was successfully updated."
    else
      # If the API update fails, re-render the edit form with an error
      flash.now[:alert] = "Failed to update the client. Please try again."
      render :edit
    end
  end

  def columns
    @monday = MondayClient.new unless defined?(@monday)

    # Query to get column information for the clients board
    query = <<~GRAPHQL
      query {
        boards(ids: [8768750185]) {
          columns {
            id
            title
            type
            settings_str
          }
          items_page(limit: 1) {
            items {
              id
              name
              column_values {
                id
                title
                type
                text
                value
              }
            }
          }
        }
      }
    GRAPHQL

    response = @monday.query(query)
    @clients = response.to_h
  end

  private

  def set_client
    @monday = MondayClient.new unless defined?(@monday)

    query = <<~GRAPHQL
      query {
        items(ids: [#{params[:id]}]) {
          id
          name
          group {
            id
            title
          }
          column_values {
            id
            type
            text
            value
          }
        }
      }
    GRAPHQL

    begin
      response = @monday.query(query)
      result = response.to_h

      if result.present? && result.dig("data", "items").present?
        @client = result.dig("data", "items").first
      else
        redirect_to clients_path, alert: "Client not found"
      end
    rescue => e
      Rails.logger.error "Error fetching client: #{e.message}"
      redirect_to clients_path, alert: "Error loading client. Please try again."
    end
  end

  def fetch_related_claims(client_id)
    # Query Monday.com for claims related to this client
    # This implementation depends on your data structure
    # We'll look for a column in Claims that relates to the client

    query = <<~GRAPHQL
      query {
        boards(ids: [#{ENV['MONDAY_CLIENTS_BOARD_ID']}]) {
          items_page(limit: 100) {
            items {
              id
              name
              column_values {
                id
                title
                type
                text
                value
              }
            }
          }
        }
      }
    GRAPHQL

    begin
      response = MondayApiService.execute_query(query)

      if response && response["data"] && response["data"]["boards"] && response["data"]["boards"].any?
        all_claims = response["data"]["boards"].first["items_page"]["items"] || []

        # Filter claims related to this client
        # This filtering logic depends on how clients and claims are linked in your Monday.com board
        related_claims = all_claims.select do |claim|
          # Look for columns that might reference the client
          client_relation_column = claim["column_values"].find { |col|
            col["type"] == "board_relation" && col["value"].present?
          }

          if client_relation_column && client_relation_column["value"].present?
            begin
              relation_value = JSON.parse(client_relation_column["value"])

              if relation_value["linkedPulseIds"] && relation_value["linkedPulseIds"].any?
                # Check if any linked item is this client
                relation_value["linkedPulseIds"].any? { |item| item["linkedPulseId"].to_s == client_id.to_s }
              else
                false
              end
            rescue => e
              Rails.logger.error("Error parsing claim relation: #{e.message}")
              false
            end
          else
            # Also check for text columns that might have the client name
            client_name = @client["name"].downcase
            claim["column_values"].any? { |col|
              col["text"].present? && col["text"].downcase.include?(client_name)
            }
          end
        end

        return related_claims
      end
    rescue => e
      Rails.logger.error("Error fetching related claims: #{e.message}")
    end

    []
  end

  def column_values_json
    # Convert the form parameters to Monday.com column values format
    column_values = {}

    # Map form field names to Monday.com column IDs
    # You'll need to update these IDs to match your actual Monday.com column IDs
    mappings = {
      "status" => "status",
      "name" => "name",
      "phone" => "phone", # Update with your actual column ID
      "email" => "email", # Update with your actual column ID
      "address" => "address", # Update with your actual column ID
      "city" => "city", # Update with your actual column ID
      "state" => "state", # Update with your actual column ID
      "zip" => "zip", # Update with your actual column ID
      "notes" => "long_text" # Update with your actual column ID
    }

    # For each mapping, add the value to column_values if present in params
    mappings.each do |param_name, column_id|
      if params[:client] && params[:client][param_name].present?
        value = params[:client][param_name]

        # Handle different column types
        case column_id
        when "status"
          column_values[column_id] = { "label": value }
        when /^date/
          column_values[column_id] = { "date": value }
        when /^numeric/
          column_values[column_id] = { "number": value.to_f }
        when /^long_text/
          column_values[column_id] = { "text": value }
        else
          column_values[column_id] = value
        end
      end
    end

    # Convert to JSON for the API
    column_values.to_json
  end

  def get_column_by_id_helper(item, column_id)
    return "N/A" unless item && item["column_values"]

    # Find the column with the exact ID
    column = item["column_values"].find { |col| col["id"] == column_id }

    # If exact ID not found, try finding by column type or partial ID match
    if column.nil?
      column = item["column_values"].find { |col| col["id"].include?(column_id) || col["type"] == column_id }
    end

    return "N/A" unless column

    # Extract the value from the column
    if column["value"].present?
      begin
        # Try to parse as JSON if it looks like a JSON object
        if column["value"].start_with?("{") && column["value"].end_with?("}")
          value_data = JSON.parse(column["value"])

          # Handle different column types
          case column["type"]
          when "people"
            if value_data["personsAndTeams"] && value_data["personsAndTeams"].any?
              persons = value_data["personsAndTeams"].map { |p| p["name"] }
              return persons.join(", ")
            end
          when "color", "status"
            return value_data["label"] if value_data["label"].present?
          when "date"
            return value_data["date"] if value_data["date"].present?
          when "numeric", "numbers"
            return value_data["number"] if value_data.key?("number") && value_data["number"].present?
          when "phone"
            return value_data["phone"] if value_data["phone"].present?
          when "email"
            return value_data["email"] if value_data["email"].present?
          when "text"
            return value_data["text"] if value_data["text"].present?
          when "long_text"
            return value_data["text"] if value_data["text"].present?
          end

          # If we couldn't extract a specific type, check for common patterns
          return value_data["text"] if value_data["text"].present?
          return value_data["value"] if value_data["value"].present?
          return value_data["label"] if value_data["label"].present?

          # For object values, get first non-empty value
          if value_data.is_a?(Hash)
            non_empty_values = value_data.values.select(&:present?)
            return non_empty_values.first.to_s if non_empty_values.any?
          end
        else
          # If it's just a string value (like with text columns), return it directly
          # Strip quotes if it's a JSON string
          if column["value"].start_with?('"') && column["value"].end_with?('"')
            return column["value"][1..-2]
          else
            return column["value"]
          end
        end
      rescue JSON::ParserError
        # If JSON parsing fails, just return the raw value
        return column["value"]
      end
    end

    # Fall back to text field if available
    return column["text"] if column["text"].present?

    # Return N/A if nothing found
    "N/A"
  end

  # Helper methods for views
  helper_method :get_column_by_id_helper, :get_column_value

  # Define get_column_value
  def get_column_value(item, column_key)
    # Default fallback to certain IDs based on column key
    case column_key
    when "Status"
      return get_column_by_id_helper(item, "status")
    when "Phone"
      return get_column_by_id_helper(item, "phone")
    when "Email"
      return get_column_by_id_helper(item, "email")
    when "Address"
      return get_column_by_id_helper(item, "address")
    when "City"
      return get_column_by_id_helper(item, "city")
    when "State"
      return get_column_by_id_helper(item, "state")
    when "ZIP"
      return get_column_by_id_helper(item, "zip")
    when "Person"
      return get_column_by_id_helper(item, "person")
    end

    # Try to find a matching column with the closest ID
    item["column_values"].each do |col|
      if col["text"].to_s.downcase.include?(column_key.downcase)
        return get_column_by_id_helper(item, col["id"])
      end
    end

    # Return N/A if nothing found
    "N/A"
  end
end
