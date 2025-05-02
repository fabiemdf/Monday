module InsuranceRepresentativesHelper
  def format_phone_number(phone)
    return "N/A" if phone.blank?

    # Remove any non-digit characters
    digits = phone.gsub(/\D/, "")

    case digits.length
    when 10
      "(#{digits[0, 3]}) #{digits[3, 3]}-#{digits[6, 4]}"
    when 11
      if digits.start_with?("1")
        "+1 (#{digits[1, 3]}) #{digits[4, 3]}-#{digits[7, 4]}"
      else
        digits
      end
    else
      phone
    end
  end

  def format_email(email)
    return "N/A" if email.blank?
    mail_to(email, email, class: "text-decoration-none")
  end

  def status_badge_class(status)
    case status.to_s.downcase
    when "active"
      "bg-success"
    when "inactive"
      "bg-secondary"
    when "pending"
      "bg-warning"
    else
      "bg-info"
    end
  end
end
