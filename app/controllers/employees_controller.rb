class EmployeesController < ApplicationController
  def index
    query = <<~GRAPHQL
      {
        boards(ids: "#{ENV['MONDAY_EMPLOYEES_BOARD_ID']}") {
          items_page(limit: 500) {
            items {
              id
              name
              group {
                id
                title
              }
              column_values {
                id
                text
                value
                type
              }
            }
          }
          groups {
            id
            title
            position
          }
        }
      }
    GRAPHQL

    response = MondayApiService.execute_query(query)

    if response["data"] && response["data"]["boards"].present?
      board_data = response["data"]["boards"][0]
      @employees = board_data["items_page"]["items"]
      @groups = board_data["groups"]

      # Group employees by their group
      @employees_by_group = @employees.group_by { |employee| employee.dig("group", "title") }

      # Sort groups by position
      @sorted_groups = @groups.sort_by { |g| g["position"] }.map { |g| g["title"] }
    else
      @employees = []
      @employees_by_group = {}
      @sorted_groups = []
    end

    @employees_data = response
  end

  def show
    query = <<~GRAPHQL
      {
        items(ids: ["#{params[:id]}"]) {
          id
          name
          group {
            title
          }
          column_values {
            id
            text
            value
            type
          }
          updated_at
        }
      }
    GRAPHQL

    response = MondayApiService.execute_query(query)

    if response["data"] && response["data"]["items"].present?
      @employee = response["data"]["items"][0]

      # Fetch related claims
      related_claims_query = <<~GRAPHQL
        {
          items(ids: ["#{params[:id]}"]) {
            subitems {
              id
              name
              column_values {
                id
                text
                value
                type
              }
            }
          }
        }
      GRAPHQL

      claims_response = MondayApiService.execute_query(related_claims_query)
      @related_claims = claims_response.dig("data", "items", 0, "subitems") || []
    else
      @employee = nil
    end
  end

  def new
    # Add implementation if needed
  end

  def edit
    @employee = fetch_employee_from_monday(params[:id])
    render_error_and_redirect if @employee.nil?
  end

  def update
    result = MondayApiService.update_employee(
      params[:id],
      employee_params
    )

    if result && !result["errors"]
      flash[:success] = "Employee updated successfully!"
      redirect_to employees_path
    else
      @employee = fetch_employee_from_monday(params[:id])
      error_message = if result["errors"]
        result["errors"].map { |e| e["message"] }.join(", ")
      else
        "Unknown error occurred while updating employee"
      end
      flash.now[:error] = "Failed to update employee: #{error_message}"
      render :edit
    end
  end

  def column_debug
    query = <<~GRAPHQL
      {
        boards(ids: "#{ENV['MONDAY_EMPLOYEES_BOARD_ID']}") {
          columns {
            id
            title
            type
            settings_str
          }
        }
      }
    GRAPHQL

    response = MondayApiService.execute_query(query)
    @columns = response.dig("data", "boards", 0, "columns") || []
  end

  private

  def employee_params
    params.require(:employee).permit(
      :name,
      :email,
      :phone,
      :position,
      :status,
      :notes
    )
  end

  def fetch_employee_from_monday(id)
    query = <<~GRAPHQL
      query {
        items(ids: [#{id}]) {
          id
          name
          column_values {
            id
            text
            value
            type
          }
          group {
            id
            title
          }
          updated_at
        }
      }
    GRAPHQL

    response = MondayApiService.execute_query(query)
    response.dig("data", "items", 0)
  end
end
