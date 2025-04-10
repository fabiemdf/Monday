# app/controllers/documents_controller.rb
class DocumentsController < ApplicationController
  before_action :set_monday_client

  def index
    query = <<~GRAPHQL
      query {
        boards(ids: 8769212922) {
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
      @documents_data = response.to_h

      # Get all items
      all_items = @documents_data.dig("data", "boards", 0, "items_page", "items") || []

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
            get_column_by_id(item, "doc_type").to_s.downcase
          when "date"
            begin
              date = get_column_by_id(item, "date")
              Date.parse(date) rescue Date.new(1900, 1, 1)
            rescue
              Date.new(1900, 1, 1)  # Default date for sorting
            end
          when "status"
            get_column_by_id(item, "status").to_s.downcase
          when "size"
            begin
              size = get_column_by_id(item, "size")
              size.to_f
            rescue
              0
            end
          else
            item["name"].to_s.downcase
          end
        end

        all_items = direction == -1 ? all_items.reverse : all_items
      end

      # Group items by group title
      @documents_by_group = all_items.group_by { |document| document.dig("group", "title") || "Other" }

      # Sort groups
      @sorted_groups = @documents_by_group.keys.sort_by { |group| group == "Other" ? "ZZZ" : group }

      # Page size (default to 10 if not specified)
      @page_size = (params[:per_page] || 10).to_i
      @page = (params[:page] || 1).to_i

    rescue => e
      Rails.logger.error("Error fetching documents from Monday: #{e.message}")
      flash.now[:alert] = "Error loading documents. Please try again later."
      @documents_data = {}
      @documents_by_group = {}
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
      @document = data.dig("data", "items", 0)

      unless @document
        flash[:alert] = "Document not found"
        redirect_to documents_path
      end
    rescue => e
      Rails.logger.error("Error fetching document from Monday: #{e.message}")
      flash[:alert] = "Error loading document. Please try again later."
      redirect_to documents_path
    end
  end

  def columns
    query = <<~GRAPHQL
      query {
        boards(ids: 8769212922) {
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
      @documents = response.to_h
    rescue => e
      Rails.logger.error("Error fetching documents from Monday: #{e.message}")
      flash.now[:alert] = "Error loading documents. Please try again later."
      @documents = {}
    end
  end

  private

  def set_monday_client
    @monday = MondayClient.new
  end
end
