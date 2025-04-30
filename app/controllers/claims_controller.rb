# app/controllers/claims_controller.rb
class ClaimsController < ApplicationController
  before_action :set_claim, only: [ :show, :edit, :update ]

  # Include helper methods from ApplicationHelper
  include ApplicationHelper

  # Make sure to require the service
  require_relative "../services/monday_api_service"

  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page_size = params[:per_page].to_i
    @page_size = 10 if @page_size < 1 # Default to 10 items per page

    # Set up the Monday client like in insurance_companies_controller
    @monday = MondayClient.new unless defined?(@monday)

    # Get all claims with their column values
    query = <<~GRAPHQL
      query {
        boards(ids: [8768944596]) {
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
      # Use the same approach as in insurance_companies_controller
      response = @monday.query(query)
      @claims_data = response.to_h  # Convert to hash like in insurance_companies_controller

      # Log the response structure for debugging
      Rails.logger.debug "Monday API Response: #{@claims_data.keys}"

      # Extract board data using the approach from insurance_companies_controller
      all_items = @claims_data.dig("data", "boards", 0, "items_page", "items") || []

      # Get all groups for reference
      groups = @claims_data.dig("data", "boards", 0, "groups") || []

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

      # Sort items if requested
      if params[:sort].present? && params[:direction].present?
        direction = params[:direction] == "desc" ? -1 : 1

# Update this section in your ClaimsController
# Around line 120-130 in claims_controller.rb
column_key = case params[:sort]
when "name" then "name"
when "status" then "status"
when "file_number" then "text_mkpbm2ed"  # Added File Number
when "claim_number" then "text_mkpb2b25"
when "client_name" then "text_mkpbjd4h"  # The claim name appears to be the client name
when "insurer" then "dropdown_mkpbw5qq"  # Updated to correct ID for insurance company
when "location" then "text_mkpb1zx4"
else "name"
end

        # Sort using the same approach as insurance_companies_controller
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
            elsif column_key == "numbers"
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
      @claims_by_group = all_items.group_by { |item| item.dig("group", "title") || "Ungrouped" }

      # Sort groups by title
      @sorted_groups = @claims_by_group.keys.sort
    rescue => e
      Rails.logger.error "Error fetching claims: #{e.message}"
      Rails.logger.error "Response: #{@claims_data.inspect}" if defined?(@claims_data)
      flash.now[:alert] = "Error loading claims. Please try again later."
      @claims_by_group = {}
      @sorted_groups = []
    end
  end

  def new
    # This action just renders the new.html.erb template
  end

  def show
    monday_id = params[:id]

    begin
      # Check if API key is present
      if ENV["MONDAY_API_KEY"].blank?
        flash[:alert] = "Monday.com API key is missing. Please check your environment variables."
        redirect_to claims_path and return
      end

      # First, fetch the claim to identify the client connection column
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
        @claim = response["data"]["items"].first

        # Get column values in a more accessible format
        @column_values = {}
        @claim["column_values"].each do |col|
          @column_values[col["id"]] = col["text"].present? ? col["text"] : "N/A"
        end

        # Look for the board relation column that connects to clients
        # Common IDs for board relation columns: board_relation_mkqae8z, board_relation_mkq7zw2f, etc.
        client_relation_column = @claim["column_values"].find { |col|
          col["type"] == "board_relation" && col["value"].present?
        }

        @client = nil

        if client_relation_column && client_relation_column["value"].present?
          # Parse the value to get the linked item IDs
          begin
            relation_value = JSON.parse(client_relation_column["value"])

            if relation_value["linkedPulseIds"] && relation_value["linkedPulseIds"].any?
              linked_item = relation_value["linkedPulseIds"].first
              client_id = linked_item["linkedPulseId"]

              # Now fetch the client information
              client_query = <<~GRAPHQL
                query {
                  items(ids: [#{client_id}]) {
                    id
                    name
                    column_values {
                      id
                      text
                      value
                      type
                    }
                  }
                }
              GRAPHQL

              client_response = MondayApiService.execute_query(client_query)

              if client_response && client_response["data"] &&
                 client_response["data"]["items"] && client_response["data"]["items"].any?
                @client = client_response["data"]["items"].first

                # Get client column values in a more accessible format
                @client_values = {}
                @client["column_values"].each do |col|
                  @client_values[col["id"]] = col["text"].present? ? col["text"] : "N/A"
                end
              end
            end
          rescue => e
            Rails.logger.error("Error parsing client relation: #{e.message}")
          end
        end

        # Render the show view
        render :show
      else
        # More detailed error message
        error_message = "Claim not found or error retrieving claim data."
        if response && response["errors"]
          error_message += " API Errors: #{response["errors"].inspect}"
        end

        Rails.logger.error(error_message)
        flash[:alert] = Rails.env.development? ? error_message : "Claim not found or error retrieving claim data."
        redirect_to claims_path
      end
    rescue => e
      # More detailed error logging
      Rails.logger.error("Error in claims#show: #{e.class.name}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # More informative error message in development
      if Rails.env.development?
        flash[:alert] = "Error: #{e.class.name} - #{e.message}"
      else
        flash[:alert] = "Error retrieving claim data. Please try again later."
      end
      redirect_to claims_path
    end
  end

  def edit
    # Set in before_action
  end

  def update
    client = Monday::Client.new(token: ENV["MONDAY_API_TOKEN"])

    # Build mutation for updating the claim
    mutation = <<~GRAPHQL
      mutation {
        change_multiple_column_values(
          item_id: #{@claim["id"]},#{' '}
          board_id: 8768944596,#{' '}
          column_values: #{column_values_json}
        ) {
          id
        }
      }
    GRAPHQL

    result = client.query(mutation)

    if result.dig("data", "change_multiple_column_values", "id").present?
      redirect_to claim_path(@claim["id"]), notice: "Claim was successfully updated."
    else
      # If the API update fails, re-render the edit form with an error
      flash.now[:alert] = "Failed to update the claim. Please try again."
      render :edit
    end
  end

  private

  def set_claim
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
        @claim = result.dig("data", "items").first
      else
        redirect_to claims_path, alert: "Claim not found"
      end
    rescue => e
      Rails.logger.error "Error fetching claim: #{e.message}"
      redirect_to claims_path, alert: "Error loading claim. Please try again."
    end
  end

  def column_values_json
    # Convert the form parameters to Monday.com column values format
    column_values = {}

    # Map form field names to Monday.com column IDs
    mappings = {
      "status" => "status",
      "claim_number" => "text_mkpb2b25",
      "file_number" => "text_mkpbm2ed",
      "policy_number" => "text_mkpbbsfe",
      "date_of_loss" => "date_mkpbcmn0",
      "client_name" => "text", # Replace with actual column ID
      "amount" => "numbers", # Replace with actual column ID
      "notes" => "long_text" # Replace with actual column ID
    }

    # For each mapping, add the value to column_values if present in params
    mappings.each do |param_name, column_id|
      if params[:claim] && params[:claim][param_name].present?
        value = params[:claim][param_name]

        # Handle different column types
        case column_id
        when "status"
          column_values[column_id] = { "label": value }
        when /^date/
          column_values[column_id] = { "date": value }
        when /^numbers/
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

  # Define get_column_value if it's not already defined in a helper
  def get_column_value(item, column_key)
    # Default fallback to certain IDs based on column key
    case column_key
    when "Status"
      return get_column_by_id_helper(item, "status")
    when "File Number"
      return get_column_by_id_helper(item, "text_mkpbm2ed")
    when "Claim Number"
      return get_column_by_id_helper(item, "text_mkpb2b25")
    when "Policy Number"
      return get_column_by_id_helper(item, "text_mkpbbsfe")
    when "Date of Loss"
      return get_column_by_id_helper(item, "date_mkpbcmn0")
    when "Client Name"
      return get_column_by_id_helper(item, "text_mkpbjd4h")
    when "Insurer"
      return get_column_by_id_helper(item, "dropdown_mkpbw5qq")
    when "Location"
      return get_column_by_id_helper(item, "text_mkpb1zx4")
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
