# TXT message received by the TXT gateway (CellTrust in production, TxtGatewayMessagesController here in test),
# sent from our system. Used to assert that our system is sending outbound TXT messages correctly.
class TxtGatewayMessage < GatewayMessage
end