# frozen_string_literal: true

require "active_model/embedding/version"
require "active_model/embedding/railtie"

require "active_model/type/document"
require "active_model/document"
require "active_model/collecting"
require "active_model/collection"

module ActiveModel
  module Embedding
    def self.included(klass)
      klass.extend ClassMethods
    end

    module ClassMethods
      def embeds_many(attr_name, class_name: nil, cast_type: nil, collection: nil)
        if cast_type
          class_name = nil
        else
          class_name ||= infer_class_name_from attr_name
        end

        attribute :"#{attr_name}", :document,
          class_name: class_name,
          cast_type: cast_type,
          collection: collection || true,
          context: self.to_s

        nested_attributes_for attr_name
      end

      def embeds_one(attr_name, class_name: nil, cast_type: nil)
        if cast_type
          class_name = nil
        else
          class_name ||= infer_class_name_from attr_name
        end

        attribute :"#{attr_name}", :document,
          class_name: class_name,
          cast_type: cast_type,
          context: self.to_s

        nested_attributes_for attr_name
      end

      private

      def infer_class_name_from(attr_name)
        attr_name.to_s.singularize.camelize
      end

      def nested_attributes_for(attr_name)
        delegate :attributes=, to: :"#{attr_name}", prefix: true
      end
    end
  end
end
