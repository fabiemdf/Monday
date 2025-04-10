# app/helpers/contacts_helper.rb
module ContactsHelper
  def contact_type_badge_class(type)
    type = type.to_s.downcase

    case type
    when /client/
      "bg-success"
    when /vendor/, /contractor/
      "bg-primary"
    when /adjuster/, /agent/, /insurance/
      "bg-info"
    when /lawyer/, /attorney/, /legal/
      "bg-warning"
    else
      "bg-secondary"
    end
  end
end
