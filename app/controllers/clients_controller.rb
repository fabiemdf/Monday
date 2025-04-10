# app/controllers/clients_controller.rb
class ClientsController < ApplicationController
  def index
    @clients = MondayAPI::ClientService.fetch_clients
  end

  def show
    @client = MondayAPI::ClientService.fetch_client(params[:id])
    if @client.nil?
      flash[:error] = "Client not found"
      redirect_to clients_path
    end
  end

  def new
    @client = {}
  end

  def create
    # TODO: Implement client creation in Monday.com
    flash[:notice] = "Client creation will be implemented soon"
    redirect_to clients_path
  end

  def edit
    @client = MondayAPI::ClientService.fetch_client(params[:id])
    if @client.nil?
      flash[:error] = "Client not found"
      redirect_to clients_path
    end
  end

  def update
    # TODO: Implement client update in Monday.com
    flash[:notice] = "Client update will be implemented soon"
    redirect_to clients_path
  end

  def destroy
    # TODO: Implement client deletion in Monday.com
    flash[:notice] = "Client deletion will be implemented soon"
    redirect_to clients_path
  end
end
