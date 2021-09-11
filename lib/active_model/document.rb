# frozen_string_literal: true

module ActiveModel
  module Document
    def self.included(klass)
      klass.class_eval do
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Serializers::JSON
        include ActiveModel::Embedding

        attribute :id, :integer
      end
    end

    def save
      return false unless valid?

      self.id = object_id unless persisted?

      true
    end

    def persisted?
      id.present?
    end

    def ==(other)
      return false unless other.is_a? self.class
      attributes == other.attributes
    end
  end
end
