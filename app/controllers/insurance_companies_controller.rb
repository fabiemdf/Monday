# app/controllers/insurance_companies_controller.rb
class InsuranceCompaniesController < ApplicationController
  before_action :set_monday_client

  def index
    query = <<~GRAPHQL
      query {
        boards(ids: 8792259332) {
          name
          items_page(limit: 100) {
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
      response = @monday.query(query)
      @companies_data = response.to_h

      # Get all items
      all_items = @companies_data.dig("data", "boards", 0, "items_page", "items") || []

      # Filter items if search parameter is present
      if params[:search].present?
        search_term = params[:search].downcase
        all_items = all_items.select do |item|
          item["name"].downcase.include?(search_term) ||
          item["column_values"].any? do |col|
            col["text"].to_s.downcase.include?(search_term)
          end
        end
      end

      # Sort items if sort parameter is present
      if params[:sort].present?
        direction = params[:direction] == "desc" ? -1 : 1

        all_items = all_items.sort_by do |item|
          case params[:sort]
          when "name"
            item["name"].to_s.downcase
          when "status"
            get_column_by_id(item, "status").to_s.downcase
          when "contact_person"
            get_column_by_id(item, "text_contact_person").to_s.downcase
          when "contact_email"
            get_column_by_id(item, "email").to_s.downcase
          when "phone"
            get_column_by_id(item, "phone").to_s.downcase
          when "policy_type"
            get_column_by_id(item, "dropdown_policy_type").to_s.downcase
          else
            item["name"].to_s.downcase
          end
        end

        all_items = direction == -1 ? all_items.reverse : all_items
      end

      # Group items by group title
      @companies_by_group = all_items.group_by { |company| company.dig("group", "title") || "All Companies" }

      # Sort groups
      @sorted_groups = @companies_by_group.keys.sort_by { |group| group == "All Companies" ? "AAA" : group }

      # Page size (default to 10 if not specified)
      @page_size = (params[:per_page] || 10).to_i
      @page = (params[:page] || 1).to_i

    rescue => e
      Rails.logger.error("Error fetching insurance companies from Monday: #{e.message}")
      flash.now[:alert] = "Error loading insurance companies. Please try again later."
      @companies_data = {}
      @companies_by_group = {}
      @sorted_groups = []
    end
  end

  def show
    item_id = params[:id]

    query = <<~GRAPHQL
  query {
    boards(ids: 8768944596) {
      items_page(limit: 100) {
        items {
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
    }
  }
GRAPHQL

    # Also fetch related claims
    claims_query = <<~GRAPHQL
      query {
        boards(ids: #{ENV['MONDAY_CLAIMS_BOARD_ID']}) {
          items_page(limit: 100) {
            items {
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
        }
      }
    GRAPHQL

    begin
      # Get insurance company details
      response = @monday.query(query)
      data = response.to_h
      @company = data.dig("data", "items", 0)

      unless @company
        flash[:alert] = "Insurance company not found"
        redirect_to insurance_companies_path
        return
      end

      # Get related claims
      claims_response = @monday.query(claims_query)
      claims_data = claims_response.to_h
      all_claims = claims_data.dig("data", "boards", 0, "items_page", "items") || []

      # Filter claims related to this insurance company
      # Assuming there's a column in claims that stores the insurance company id or name
      company_name = @company["name"]
      @related_claims = all_claims.select do |claim|
        insurer = get_column_value(claim, "Insurer") || get_column_value(claim, "Insurance Company")
        insurer.to_s.downcase == company_name.to_s.downcase
      end

      # Limit to 5 recent claims
      @related_claims = @related_claims.sort_by do |claim|
        date_filed = get_column_value(claim, "Date Filed")
        begin
          Date.parse(date_filed) rescue Date.new(1900, 1, 1)
        rescue
          Date.new(1900, 1, 1)
        end
      end.reverse.first(5)

    rescue => e
      Rails.logger.error("Error fetching insurance company from Monday: #{e.message}")
      flash[:alert] = "Error loading insurance company. Please try again later."
      redirect_to insurance_companies_path
    end
  end

  def columns
    query = <<~GRAPHQL
      query {
        boards(ids: 8792259332) {
          name
          items_page(limit: 1) {
            items {
              id
              name
              column_values {
                id
                title
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
      response = @monday.query(query)
      @companies = response.to_h
    rescue => e
      Rails.logger.error("Error fetching insurance companies from Monday: #{e.message}")
      flash.now[:alert] = "Error loading insurance companies. Please try again later."
      @companies = {}
    end

    render :column_debug
  end

  private

  def set_monday_client
    @monday = MondayClient.new
  end

  # Helper methods for views
  helper_method :get_column_by_id, :get_column_value

  def get_column_by_id(item, column_id)
    return "N/A" unless item && item["column_values"]

    column = item["column_values"].find { |col| col["id"] == column_id }
    return "N/A" unless column

    # Extract the value from the column
    if column["value"].present?
      begin
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
          when "dropdown"
            return value_data["labels"].first if value_data["labels"].present?
          end

          # Common patterns
          return value_data["text"] if value_data["text"].present?
          return value_data["value"] if value_data["value"].present?
          return value_data["label"] if value_data["label"].present?

          # For object values
          if value_data.is_a?(Hash)
            non_empty_values = value_data.values.select(&:present?)
            return non_empty_values.first.to_s if non_empty_values.any?
          end
        else
          # String value
          if column["value"].start_with?('"') && column["value"].end_with?('"')
            return column["value"][1..-2]
          else
            return column["value"]
          end
        end
      rescue JSON::ParserError
        return column["value"]
      end
    end

    # Fall back to text field
    return column["text"] if column["text"].present?

    "N/A"
  end

  def get_column_value(item, column_key)
    # Try to find a matching column with the closest ID
    item["column_values"].each do |col|
      if col["text"].to_s.downcase.include?(column_key.downcase) ||
         (col["title"] && col["title"].to_s.downcase.include?(column_key.downcase))
        return get_column_by_id(item, col["id"])
      end
    end

    # Return N/A if nothing found
    "N/A"
  end
end
