class AdjustersController < ApplicationController
  def index
    query = <<~GRAPHQL
      {
        boards(ids: "#{ENV['MONDAY_ADJUSTERS_BOARD_ID']}") {
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
      @adjusters = board_data["items_page"]["items"]
      @groups = board_data["groups"]

      # Group adjusters by their group
      @adjusters_by_group = @adjusters.group_by { |adjuster| adjuster.dig("group", "title") }

      # Sort groups by position
      @sorted_groups = @groups.sort_by { |g| g["position"] }.map { |g| g["title"] }
    else
      @adjusters = []
      @adjusters_by_group = {}
      @sorted_groups = []
    end

    @adjusters_data = response
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
      @adjuster = response["data"]["items"][0]

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
      @adjuster = nil
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
        boards(ids: "#{ENV['MONDAY_ADJUSTERS_BOARD_ID']}") {
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
