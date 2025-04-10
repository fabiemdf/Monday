# app/helpers/insurance_companies_helper.rb
module InsuranceCompaniesHelper
  def status_badge_class(status)
    status = status.to_s.downcase

    case status
    when /active/, /enabled/
      "bg-success"
    when /inactive/, /disabled/
      "bg-secondary"
    when /pending/, /waiting/
      "bg-warning"
    when /suspended/
      "bg-danger"
    else
      "bg-secondary"
    end
  end

  def policy_type_badge_class(type)
    type = type.to_s.downcase

    case type
    when /health/
      "bg-info"
    when /auto/, /car/, /vehicle/
      "bg-primary"
    when /home/, /property/, /homeowner/
      "bg-success"
    when /life/
      "bg-dark"
    when /business/, /commercial/, /liability/
      "bg-warning"
    else
      "bg-secondary"
    end
  end
end
