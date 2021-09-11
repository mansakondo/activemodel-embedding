class Field
  include ActiveModel::Document

  attribute :tag, :string

  embeds_many :subfields
end
