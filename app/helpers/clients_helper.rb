# app/helpers/clients_helper.rb
module ClientsHelper
  # Helper method for determining badge class for statuses
  def status_badge_class(status)
    case status.to_s.downcase
    when "active"
      "bg-success"
    when "inactive"
      "bg-secondary"
    when "pending"
      "bg-warning"
    when "claim closed"
      "bg-success"
    when "in progress"
      "bg-primary"
    when "stuck"
      "bg-danger"
    when "done"
      "bg-success"
    when "denied"
      "bg-danger"
    else
      "bg-info"
    end
  end

  # Keep the original method name for backward compatibility
  def get_column_value(item, column_title)
    return "N/A" unless item && item["column_values"]

    # Try to find the column with the matching title
    column = item["column_values"].find do |col|
      # Check for exact title match or case-insensitive match
      col["title"] == column_title ||
      (col["title"] && col["title"].downcase == column_title.downcase)
    end

    # If we can't find by title, try to find a column with a matching ID that might represent the field
    if column.nil?
      column = item["column_values"].find do |col|
        col["id"] && col["id"].downcase.include?(column_title.downcase)
      end
    end

    return "N/A" unless column

    # Extract the value
    if column["value"].present?
      # Handle JSON stored in value field
      begin
        value_data = JSON.parse(column["value"])

        # Handle different column types
        if column["id"].include?("person") || column["id"].include?("people")
          # Person column type
          if value_data["personsAndTeams"]
            persons = value_data["personsAndTeams"].map { |p| p["name"] }
            return persons.join(", ")
          end
        elsif column["id"].include?("status")
          # Status column type
          return value_data["label"] if value_data["label"]
        elsif column["id"].include?("phone")
          # Phone column type
          return value_data["phone"] if value_data["phone"]
        elsif column["id"].include?("email")
          # Email column type
          return value_data["email"] if value_data["email"]
        elsif column["id"].include?("text")
          # Text column type
          return value_data["text"] if value_data["text"]
        end

        # If we couldn't extract a specific type, return something meaningful
        return value_data.values.first.to_s if value_data.values.first.present?
      rescue JSON::ParserError => e
        # If it's not JSON, just return the raw value
        return column["value"]
      end
    end

    # Fall back to text field if available
    return column["text"] if column["text"].present?

    # Return N/A if nothing found
    "N/A"
  end

  # Helper method to get column value by ID
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

  # Helper method for Monday.com status options
  def monday_status_options(item)
    # Default options if we can't determine from the item
    default_options = [
      [ "Active", "active" ],
      [ "Inactive", "inactive" ],
      [ "Pending", "pending" ]
    ]

    # Try to extract status options from the item if available
    status_column = item["column_values"].find { |col| col["id"] == "status" || col["title"].downcase == "status" }

    if status_column.present? && status_column["value"].present?
      begin
        # Parse the JSON value to extract available options
        status_data = JSON.parse(status_column["value"])

        if status_data["changed_at"].present?
          # This seems to be a regular status column with settings
          return default_options
        end

        if status_data["index"].present?
          # Try to find the available options
          # This is a complex task usually requiring an API call to Monday.com
          # For simplicity, we'll return defaults here
          return default_options
        end
      rescue => e
        # If there's an error parsing, just use defaults
        return default_options
      end
    end

    # Return defaults if we couldn't determine options
    default_options
  end

  # Sortable column helper - matches the functionality in ApplicationHelper
  def sortable_column(title, column)
    direction = (params[:sort] == "#{column}_asc") ? "#{column}_desc" : "#{column}_asc"
    link_to clients_path(sort: direction, page: params[:page], search: params[:search], status: params[:status]), class: "text-decoration-none text-dark" do
      concat title
      if params[:sort]&.start_with?(column)
        concat " "
        concat content_tag(:i, nil, class: "bi #{params[:sort].end_with?('desc') ? 'bi-arrow-up' : 'bi-arrow-down'}")
      else
        concat " "
        concat content_tag(:i, nil, class: "bi bi-arrow-down-up text-muted")
      end
    end
  end

  # Alias the method to the new name for future use
  alias_method :get_column_value_by_title, :get_column_value
end
