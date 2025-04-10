# app/helpers/claims_helper.rb
module ClaimsHelper
  def status_badge_class(status)
    status = status.to_s.downcase

    case status
    when /pending/
      "bg-warning"
    when /approved/, /accepted/, /complete/, /completed/
      "bg-success"
    when /rejected/, /declined/, /denied/
      "bg-danger"
    when /in progress/, /processing/, /working/
      "bg-info"
    when /waiting/, /on hold/
      "bg-secondary"
    else
      "bg-secondary"
    end
  end

  # Direct access to column by ID - more reliable
  def get_column_by_id(item, column_id)
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

  # The original method for backward compatibility
  def get_column_value(item, column_key)
    # Default fallback to certain IDs based on column key
    case column_key
    when "Status"
      return get_column_by_id(item, "status")
    when "File Number"
      return get_column_by_id(item, "text_mkpbm2ed")
    when "Claim Number"
      return get_column_by_id(item, "text_mkpb2b25")
    when "Policy Number"
      return get_column_by_id(item, "text_mkpbbsfe")
    when "Date of Loss"
      return get_column_by_id(item, "date_mkpbcmn0")
    end

    # Try to find a matching column with the closest ID
    item["column_values"].each do |col|
      if col["text"].to_s.downcase.include?(column_key.downcase)
        return get_column_by_id(item, col["id"])
      end
    end

    # Return N/A if nothing found
    "N/A"
  end
end
