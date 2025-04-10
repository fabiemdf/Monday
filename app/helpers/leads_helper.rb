# app/helpers/leads_helper.rb
module LeadsHelper
  def lead_status_badge_class(status)
    status = status.to_s.downcase

    case status
    when /new/, /fresh/
      "bg-info"
    when /qualified/, /hot/
      "bg-success"
    when /contacted/
      "bg-primary"
    when /follow[-\s]?up/
      "bg-warning"
    when /converted/
      "bg-success"
    when /lost/, /dead/, /closed/
      "bg-danger"
    when /nurturing/
      "bg-secondary"
    else
      "bg-secondary"
    end
  end
end
