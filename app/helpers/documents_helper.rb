# app/helpers/documents_helper.rb
module DocumentsHelper
  def document_type_badge_class(type)
    type = type.to_s.downcase

    case type
    when /pdf/
      "bg-danger"
    when /word/, /doc/
      "bg-primary"
    when /excel/, /spreadsheet/, /xls/
      "bg-success"
    when /image/, /photo/, /jpg/, /png/
      "bg-info"
    when /contract/
      "bg-warning"
    when /invoice/, /bill/
      "bg-secondary"
    when /insurance/, /policy/
      "bg-dark"
    when /report/
      "bg-info"
    else
      "bg-secondary"
    end
  end

  def document_status_badge_class(status)
    status = status.to_s.downcase

    case status
    when /draft/
      "bg-warning"
    when /final/, /approved/
      "bg-success"
    when /signed/
      "bg-primary"
    when /pending/, /review/
      "bg-info"
    when /expired/, /archived/
      "bg-secondary"
    when /rejected/
      "bg-danger"
    else
      "bg-secondary"
    end
  end
end
