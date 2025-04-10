# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  before_action :set_monday_client

  def index
    query = <<~GRAPHQL
      query {
        boards(ids: 8792441338) {
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
      @contacts_data = response.to_h

      # Get all items
      all_items = @contacts_data.dig("data", "boards", 0, "items_page", "items") || []

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
          when "type"
            get_column_by_id(item, "status").to_s.downcase # Replace with your actual column ID for type
          when "phone"
            get_column_by_id(item, "phone").to_s.downcase # Replace with your actual column ID for phone
          when "email"
            get_column_by_id(item, "email").to_s.downcase # Replace with your actual column ID for email
          when "company"
            get_column_by_id(item, "company").to_s.downcase # Replace with your actual column ID for company
          else
            item["name"].to_s.downcase
          end
        end

        all_items = direction == -1 ? all_items.reverse : all_items
      end

      # Group items by group title
      @contacts_by_group = all_items.group_by { |contact| contact.dig("group", "title") || "Other" }

      # Sort groups
      @sorted_groups = @contacts_by_group.keys.sort_by { |group| group == "Other" ? "ZZZ" : group }

      # Page size (default to 10 if not specified)
      @page_size = (params[:per_page] || 10).to_i
      @page = (params[:page] || 1).to_i

    rescue => e
      Rails.logger.error("Error fetching contacts from Monday: #{e.message}")
      flash.now[:alert] = "Error loading contacts. Please try again later."
      @contacts_data = {}
      @contacts_by_group = {}
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
      @contact = data.dig("data", "items", 0)

      unless @contact
        flash[:alert] = "Contact not found"
        redirect_to contacts_path
      end
    rescue => e
      Rails.logger.error("Error fetching contact from Monday: #{e.message}")
      flash[:alert] = "Error loading contact. Please try again later."
      redirect_to contacts_path
    end
  end

  def column_debug
    # Similar to the claims controller's column debug
    query = <<~GRAPHQL
      query {
        boards(ids: 8792441338) {
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
      @contacts = response.to_h
    rescue => e
      Rails.logger.error("Error fetching contacts from Monday: #{e.message}")
      flash.now[:alert] = "Error loading contacts. Please try again later."
      @contacts = {}
    end
  end

  private

  def set_monday_client
    @monday = MondayClient.new
  end
end
