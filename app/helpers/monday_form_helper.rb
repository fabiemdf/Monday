# app/helpers/monday_form_helper.rb
module MondayFormHelper
  # Convert a Monday.com column value to a form-friendly format
  def monday_to_form_value(claim, column_key, default_value = nil)
    value = get_column_value(claim, column_key)
    return default_value if value == "N/A"

    # Handle different value types
    case column_key
    when "Date of Loss", "Date Filed"
      begin
        Date.parse(value).strftime("%Y-%m-%d") rescue value
      rescue
        value
      end
    when "Amount"
      begin
        value.to_f
      rescue
        value
      end
    else
      value
    end
  end

  # Get available status options from the Monday.com board
  def monday_status_options(claim)
    # Try to find the status column
    status_column = claim["column_values"].find { |col| col["id"] == "status" }
    return [] unless status_column && status_column["value"].present?

    begin
      # Parse the column settings to extract available options
      value_data = JSON.parse(status_column["value"])
      return [] unless value_data.is_a?(Hash)

      # Extract the current status
      current_status = value_data["label"] if value_data["label"].present?

      # Return a simple array for now - in a real implementation,
      # you would query the Monday.com API for all available status options
      # This is a placeholder for demonstration
      statuses = Claim::STATUSES.map(&:humanize)

      # Make sure the current status is included
      statuses << current_status if current_status.present? && !statuses.include?(current_status)

      # Return as value pairs for select inputs
      statuses.map { |s| [ s, s.downcase.gsub(/\s+/, "_") ] }
    rescue JSON::ParserError
      # Fallback to application defaults
      Claim::STATUSES.map { |s| [ s.humanize, s ] }
    end
  end

  # Format a value for display in a form
  def format_form_value(value, column_type)
    return nil if value.nil? || value == "N/A"

    case column_type
    when "date"
      begin
        Date.parse(value).strftime("%Y-%m-%d") rescue value
      rescue
        value
      end
    when "numeric", "numbers"
      begin
        value.to_f
      rescue
        value
      end
    else
      value
    end
  end

  # Convert form values to Monday.com API format
  def form_to_monday_format(params)
    column_values = {}

    # Map parameters to Monday.com column formats
    params.each do |key, value|
      next if value.blank?

      column_id = case key
      when "status" then "status"
      when "claim_number" then "text_mkpb2b25"
      when "file_number" then "text_mkpbm2ed"
      when "client_name" then "text" # Replace with actual column ID
      when "policy_number" then "text_mkpbbsfe"
      when "date_of_loss" then "date_mkpbcmn0"
      when "amount" then "numbers" # Replace with actual column ID
      when "insurer" then "text" # Replace with actual column ID
      when "notes" then "long_text" # Replace with actual column ID
      when "next_steps" then "long_text" # Replace with actual column ID
      else nil
      end

      next unless column_id

      # Format the value based on column type
      column_values[column_id] = case column_id
      when "status"
                                  { "label": value.humanize }
      when /^date/
                                  { "date": value }
      when /^numbers/
                                  { "number": value.to_f }
      when /^long_text/
                                  { "text": value }
      else
                                  value
      end
    end

    column_values.to_json
  end
end
