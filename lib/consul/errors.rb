module Consul
  class Error < StandardError; end
  class Powerless < Error; end
  class UncheckedPower < Error; end
  class UnmappedAction < Error; end
  class UnreachablePower < Error; end
end
