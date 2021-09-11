# frozen_string_literal: true

module ActiveModel
  module Collecting
    include ActiveModel::ForbiddenAttributesProtection

    attr_reader :documents, :document_class
    alias_method :to_a, :documents

    def initialize(documents)
      @documents      = documents
      @document_class = documents.first.class
    end

    def attributes=(documents_attributes)
      documents_attributes = sanitize_for_mass_assignment(documents_attributes)

      case documents_attributes
      when Hash
        documents_attributes.each do |index, document_attributes|
          id = fetch_id(document_attributes)

          if id
            document = find id
          else
            index    = index.to_i
            document = documents[index]
          end

          document.attributes = document_attributes
        end
      when Array
        documents_attributes.each do |document_attributes|
          id = fetch_id(document_attributes)

          if id
            document = find id
          else
            document = build
          end

          document.attributes = document_attributes
        end
      else
        raise_attributes_error
      end
    end

    def find(id)
      documents.find { |document| document.id == id }
    end

    def build(attributes = {})
      case attributes
      when Hash
        document = document_class.new(attributes)

        append document

        document
      when Array
        attributes.map do |document_attributes|
          build(document_attributes)
        end
      else
        raise_attributes_error
      end
    end

    def push(*new_documents)
      new_documents = new_documents.flatten

      valid_documents = new_documents.all? { |document| document.is_a? document_class }

      unless valid_documents
        raise ArgumentError, "Expect arguments to be of class #{document_class}"
      end

      @documents.push(*new_documents)
    end

    alias_method :<<, :push
    alias_method :append, :push

    def save
      documents.all? do |document|
        document.save
      end
    end

    def each
      return self.to_enum unless block_given?
      documents.each { |document| yield document }
    end

    def as_json
      documents.as_json
    end

    def to_json
      as_json.to_json
    end

    private

    def fetch_id(attributes)
      attributes["id"] || attributes[:id]
    end

    def raise_attributes_error
      raise ArgumentError, "Expect attributes to be a Hash or Array, but got a #{attributes.class}"
    end
  end
end
