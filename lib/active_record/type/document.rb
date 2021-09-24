# frozen_string_literal: true

module ActiveRecord
  module Type
    Document = ActiveModel::Type::Document

    register :document, Document, override: false
  end
end
