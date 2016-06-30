module SilverpopListMoves
  class ResqueJob

    @queue = :silverpop_list_moves

    def self.perform(silverpop_list_move_id)
      return unless Analog::ThirdPartyApi::Silverpop.allow_silverpop_request?
      silverpop_list_move = SilverpopListMove.find(silverpop_list_move_id)
      silverpop_list_move.move_consumer_to_different_silverpop_list
    end

  end
end
