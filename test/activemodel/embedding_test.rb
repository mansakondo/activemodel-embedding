require "test_helper"

class ActiveModel::EmbeddingTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert ActiveModel::Embedding::VERSION
  end

  setup do
    @field = ::Field.new tag: "200"
  end

  test "should handle mass assignment correctly" do
    subfields_attributes = [{code: "a", value: "Getting Real"}, {code: "3", value: "..."}]

    @field.subfields = subfields_attributes
    assert_equal @field.subfields.document_class, ::Subfield

    params    = ::ActionController::Parameters.new(subfields_attributes: { "0" => { value: "Rework" }})
    permitted = params.permit(subfields_attributes: [:id, :value])

    @field.subfields_attributes = permitted[:subfields_attributes]
    assert_equal @field.subfields.first.value, "Rework"

    @field.subfields.save
    assert @field.subfields.all?(&:id)

    id           = @field.subfields.first.id
    random_index = Random.new_seed
    params       = ::ActionController::Parameters.new(subfields_attributes: { "#{random_index}" => { id: id, value: "ShapeUp" }})
    permitted    = params.permit(subfields_attributes: [:id, :value])

    @field.subfields_attributes = permitted[:subfields_attributes]
    assert_equal @field.subfields.first.value, "ShapeUp"

    params = ::ActionController::Parameters.new(subfields_attributes: { "#{random_index}" => { id: id, value: "..." }})

    assert_raises { @field.subfields_attributes = params }
  end
end
