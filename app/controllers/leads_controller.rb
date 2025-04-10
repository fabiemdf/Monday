# app/controllers/leads_controller.rb
class LeadsController < ApplicationController
  before_action :set_monday_client

  def index
    query = <<~GRAPHQL
      query {
        boards(ids: 8778422410) {
          name
          items_page(limit: 100) {
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
        }
      }
    GRAPHQL

    begin
      response = @monday.query(query)
      @leads_data = response.to_h

      # Get all items
      all_items = @leads_data.dig("data", "boards", 0, "items_page", "items") || []

      # Filter items if search parameter is present
      if params[:search].present?
        search_term = params[:search].downcase
        all_items = all_items.select do |item|
          item["name"].downcase.include?(search_term) ||
          item["column_values"].any? do |col|
            col["text"].to_s.downcase.include?(search_term)
          end
        end
      end

      # Sort items if sort parameter is present
      if params[:sort].present?
        direction = params[:direction] == "desc" ? -1 : 1

        all_items = all_items.sort_by do |item|
          case params[:sort]
          when "name"
            item["name"].to_s.downcase
          when "status"
            get_column_by_id(item, "status").to_s.downcase
          when "source"
            get_column_by_id(item, "source").to_s.downcase
          when "phone"
            get_column_by_id(item, "phone").to_s.downcase
          when "email"
            get_column_by_id(item, "email").to_s.downcase
          when "date"
            begin
              date = get_column_by_id(item, "date")
              Date.parse(date) rescue Date.new(1900, 1, 1)
            rescue
              Date.new(1900, 1, 1)  # Default date for sorting
            end
          else
            item["name"].to_s.downcase
          end
        end

        all_items = direction == -1 ? all_items.reverse : all_items
      end

      # Group items by group title
      @leads_by_group = all_items.group_by { |lead| lead.dig("group", "title") || "Other" }

      # Sort groups
      @sorted_groups = @leads_by_group.keys.sort_by { |group| group == "Other" ? "ZZZ" : group }

      # Page size (default to 10 if not specified)
      @page_size = (params[:per_page] || 10).to_i
      @page = (params[:page] || 1).to_i

    rescue => e
      Rails.logger.error("Error fetching leads from Monday: #{e.message}")
      flash.now[:alert] = "Error loading leads. Please try again later."
      @leads_data = {}
      @leads_by_group = {}
      @sorted_groups = []
    end
  end

  def show
    item_id = params[:id]

    query = <<~GRAPHQL
      query {
        items(ids: [#{item_id}]) {
          id
          name
          board {
            id
            name
          }
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
    GRAPHQL

    begin
      response = @monday.query(query)
      data = response.to_h
      @lead = data.dig("data", "items", 0)

      unless @lead
        flash[:alert] = "Lead not found"
        redirect_to leads_path
      end
    rescue => e
      Rails.logger.error("Error fetching lead from Monday: #{e.message}")
      flash[:alert] = "Error loading lead. Please try again later."
      redirect_to leads_path
    end
  end

  def columns
    query = <<~GRAPHQL
      query {
        boards(ids: 8778422410) {
          name
          items_page(limit: 10) {
            items {
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
      }
    GRAPHQL

    begin
      response = @monday.query(query)
      @leads = response.to_h
    rescue => e
      Rails.logger.error("Error fetching leads from Monday: #{e.message}")
      flash.now[:alert] = "Error loading leads. Please try again later."
      @leads = {}
    end
  end

  private

  def set_monday_client
    @monday = MondayClient.new
  end
end
