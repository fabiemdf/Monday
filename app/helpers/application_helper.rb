# app/helpers/application_helper.rb
module ApplicationHelper
  # Helper method for determining sort arrow direction
  def sortable_column(title, column)
    direction = (params[:sort] == column && params[:direction] == "asc") ? "desc" : "asc"
    link_to claims_path(sort: column, direction: direction, page: params[:page], search: params[:search]), class: "text-decoration-none text-dark" do
      concat title
      if params[:sort] == column
        concat " "
        concat content_tag(:i, nil, class: "bi #{direction == 'desc' ? 'bi-arrow-up' : 'bi-arrow-down'}")
      else
        concat " "
        concat content_tag(:i, nil, class: "bi bi-arrow-down-up text-muted")
      end
    end
  end
end
