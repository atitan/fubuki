class UsageError < StandardError; end
class UnsupportedProtocolError < StandardError; end
class UndefinedProtocolError < StandardError; end

class CommunicationError < StandardError; end
class PICCTimeoutError < CommunicationError; end
class PCDTimeoutError < CommunicationError; end
class IncorrectCRCError < CommunicationError; end
class CollisionError < CommunicationError; end
