module Sawyer
  class Resource
    def to_json(*args) to_h.to_json(args) ; end
  end
end
