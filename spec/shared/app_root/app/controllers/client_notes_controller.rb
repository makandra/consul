class ClientNotesController < ApplicationController

  power :clients, :as => :client_scope

  power :client_notes, :context => :client, :as => :note_scope

  private

  def client
    @client ||= client_scope.find(params[:client_id])
  end

end
