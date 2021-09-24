class MARC::Record::Field::Subfield
  include ActiveModel::Embedding::Document

  attribute :code, :string
  attribute :value, :string
end
