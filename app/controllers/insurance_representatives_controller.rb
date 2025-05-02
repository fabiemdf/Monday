class InsuranceRepresentativesController < ApplicationController
  def index
    query = <<~GRAPHQL
      {
        boards(ids: "#{ENV['MONDAY_INSURANCE_REPS_BOARD_ID']}") {
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
      @reps = board_data["items_page"]["items"]
      @groups = board_data["groups"]

      # Group representatives by their group
      @reps_by_group = @reps.group_by { |rep| rep.dig("group", "title") }

      # Sort groups by position
      @sorted_groups = @groups.sort_by { |g| g["position"] }.map { |g| g["title"] }
    else
      @reps = []
      @reps_by_group = {}
      @sorted_groups = []
    end

    @reps_data = response
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
            title
          }
          updated_at
        }
      }
    GRAPHQL

    response = MondayApiService.execute_query(query)

    if response["data"] && response["data"]["items"].present?
      @rep = response["data"]["items"][0]

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
      @rep = nil
    end
  end

  def new
    # Add implementation if needed
  end

  def edit
    # Add implementation if needed
  end

  def column_debug
    query = <<~GRAPHQL
      {
        boards(ids: "#{ENV['MONDAY_INSURANCE_REPS_BOARD_ID']}") {
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
end
