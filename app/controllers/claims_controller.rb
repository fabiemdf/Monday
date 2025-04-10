# app/controllers/claims_controller.rb
class ClaimsController < ApplicationController
  before_action :set_claim, only: [ :show, :edit, :update ]

  def index
    @page = params[:page].to_i
    @page = 1 if @page < 1
    @page_size = params[:per_page].to_i
    @page_size = 10 if @page_size < 1 # Default to 10 items per page

    # Get all claims with their column values
    query = <<~GRAPHQL
      query {
        boards(ids: [8768944596]) {
          groups {
            id
            title
          }
          items_page {
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
      result = MondayAPI.execute_query(query)
      @claims = result["data"]["boards"].first
    rescue => e
      Rails.logger.error "Error fetching claims: #{e.message}"
      @claims = nil
    end

    if @claims.present? && @claims.dig("data", "boards", 0, "items_page", "items").present?
      items = @claims.dig("data", "boards", 0, "items_page", "items")

      # Filter by search term if provided
      if params[:search].present?
        search_term = params[:search].downcase
        items = items.select do |item|
          item["name"].downcase.include?(search_term) ||
          item["column_values"].any? do |col|
            col["text"].to_s.downcase.include?(search_term)
          end
        end
      end

      # Sort items if requested
      if params[:sort].present? && params[:direction].present?
        column_key = case params[:sort]
        when "name" then "name"
        when "status" then "status"
        when "file_number" then "text_mkpbm2ed"
        when "claim_number" then "text_mkpb2b25"
        when "policy_number" then "text_mkpbbsfe"
        when "date_of_loss" then "date_mkpbcmn0"
        else "name"
        end

        # Special case for name which is not in column_values
        if column_key == "name"
          items = items.sort_by { |item| item["name"].downcase }
        else
          items = items.sort_by do |item|
            value = if column_key == "status"
                      get_column_by_id_helper(item, column_key)
            else
                      column = item["column_values"].find { |col| col["id"] == column_key }
                      column.present? ? (column["text"] || "").downcase : ""
            end
            value.to_s.downcase
          end
        end

        # Reverse for descending order
        items = items.reverse if params[:direction] == "desc"
      end

      # Group by the group title
      @claims_by_group = items.group_by { |item| item.dig("group", "title") || "Ungrouped" }

      # Sort groups by title
      @sorted_groups = @claims_by_group.keys.sort
    else
      @claims_by_group = {}
      @sorted_groups = []
    end
  end

  def new
    # This action just renders the new.html.erb template
  end

  def show
    # Get a specific claim with all its details
    query = <<~GRAPHQL
      query($itemId: ID!) {
        items(ids: [$itemId]) {
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

    begin
      result = MondayAPI.execute_query(query, { itemId: params[:id] })
      @claim = result["data"]["items"].first
    rescue => e
      Rails.logger.error "Error fetching claim: #{e.message}"
      redirect_to claims_path, alert: "Claim not found"
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

  def columns
    # For debugging column IDs
    client = Monday::Client.new(token: ENV["MONDAY_API_TOKEN"])

    query = <<~GRAPHQL
      query {
        boards(ids: 8768944596) {
          items_page(limit: 1) {
            items {
              id
              name
              column_values {
                id
                type
                text
                value
              }
            }
          }
        }
      }
    GRAPHQL

    @claims = client.query(query)
  end

  private

  def set_claim
    client = Monday::Client.new(token: ENV["MONDAY_API_TOKEN"])

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

    result = client.query(query)

    if result.present? && result.dig("data", "items").present?
      @claim = result.dig("data", "items").first
    else
      redirect_to claims_path, alert: "Claim not found"
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
end
