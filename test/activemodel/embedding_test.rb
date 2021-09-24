require "test_helper"

class ActiveModel::EmbeddingTest < ActiveSupport::TestCase
  test "it has a version number" do
    assert ActiveModel::Embedding::VERSION
  end

  fixtures "marc/records"

  setup do
    @record = marc_records(:hamlet)
  end

  test "should handle mass assignment correctly" do
    field = MARC::Record::Field.new tag: "200"
    subfields_attributes = [{code: "a", value: "Getting Real"}, {code: "3", value: "..."}]

    field.subfields = subfields_attributes
    assert_equal MARC::Record::Field::Subfield, field.subfields.document_class

    params    = ::ActionController::Parameters.new(subfields_attributes: { "0" => { value: "Rework" }})
    permitted = params.permit(subfields_attributes: [:id, :value])

    field.subfields_attributes = permitted[:subfields_attributes]
    assert_equal "Rework", field.subfields.first.value

    assert field.subfields.save
    assert field.subfields.all?(&:id)

    id           = field.subfields.first.id
    random_index = Random.new_seed
    params       = ::ActionController::Parameters.new(subfields_attributes: { "#{random_index}" => { id: id, value: "ShapeUp" }})
    permitted    = params.permit(subfields_attributes: [:id, :value])

    field.subfields_attributes = permitted[:subfields_attributes]
    assert_equal "ShapeUp", field.subfields.first.value

    params = ::ActionController::Parameters.new(subfields_attributes: { "#{random_index}" => { id: id, value: "..." }})

    assert_raises { field.subfields_attributes = params }
  end

  test "should work with ActiveRecord" do
    assert_equal MARC::Record::Field, @record.fields.document_class
    assert @record.fields.first.control_field?

    assert_equal MARC::Record::Field::Subfield, @record.fields.to_a.last.subfields.document_class

    assert_equal "Hamlet", @record["245"]["a"].value

    @record["245"]["a"].value = "Romeo and Juliet"
    assert_equal  "Romeo and Juliet", @record["245"]["a"].value
  end

  test "should autosave embedded documents" do
    @record["245"]["a"].value = "Romeo and Juliet"

    assert @record.save

    @record.reload

    assert_equal "Romeo and Juliet", @record["245"]["a"].value
  end

  test "should track changes" do
    refute @record.changed?

    @record["245"]["a"].value = "Romeo and Juliet"

    assert @record.changed?
  end
end
