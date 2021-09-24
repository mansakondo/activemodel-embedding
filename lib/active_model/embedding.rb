# frozen_string_literal: true

require "active_model/embedding/version"
require "active_model/embedding/railtie"

require "active_model/type/document"
require "active_record/type/document"

module ActiveModel
  module Embedding
    require "active_model/embedding/associations"
    require "active_model/embedding/document"
    require "active_model/embedding/collecting"
    require "active_model/embedding/collection"
  end
end
