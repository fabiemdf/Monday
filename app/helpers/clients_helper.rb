# app/helpers/clients_helper.rb
module ClientsHelper
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

  # Alias the method to the new name for future use
  alias_method :get_column_value_by_title, :get_column_value
end
