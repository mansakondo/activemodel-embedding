class MARC::Record < ApplicationRecord
  include ActiveModel::Embedding::Associations

  embeds_many :fields

  validates_associated :fields

  # Hash-like reader method
  def [](tag)
    occurences = fields.select { |field| field.tag == tag }
    occurences.first unless occurences.count > 1
  end
end
