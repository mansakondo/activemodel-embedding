# frozen_string_literal: true

module ActiveModel
  class Collection
    include Enumerable
    include Collecting
  end
end
