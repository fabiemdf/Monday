class MondayController < ApplicationController
  include MondayAPI

  def index
    Rails.logger.debug "Checking Monday.com API token..."
    Rails.logger.debug "MONDAY_API_TOKEN present: #{ENV['MONDAY_API_TOKEN'].present?}"

    @boards = MondayAPI::BoardService.fetch_boards
    Rails.logger.debug "Fetched boards: #{@boards.inspect}"

    respond_to do |format|
      format.html # Renders index.html.erb by default
      format.json { render json: @boards }
    end
  end
end
