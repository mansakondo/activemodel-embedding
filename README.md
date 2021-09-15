# ActiveModel::Embedding
An ActiveModel extension to model your [semi-structured data](#semi-structured-data) using
[embedded associations](#embedded-associations).

- [Introduction](#introduction)
- [Usage](#usage)
- [Warning](#warning)
- [Use Case: Dealing with bibliographic data](#use-case%3A-dealing-with-bibliographic-data)
- [Concepts](#concepts)
- [Components](#components)
- [Installation](#installation)
- [License](#license)

## Introduction
Relational databases are very powerful. Their power comes from their ability to...
- Preserve data integrity with a predefined schema
- Make complex relationships through joins

However, sometimes we can stumble accross data that don't fit in the relational model. We call
this kind of data: [**semi-structured data**](#semi-structured-data). When
this happens, the things that makes relational databases powerful are the things that gets in our way,
and complicate our model instead of simplifying it.

That's why [document databases](https://en.wikipedia.org/wiki/Document-oriented_database)
exist, to model and store semi-structured data. However, if we choose to use a document
database, we'll loose all the power of using a relational database.

But since relational databases like Postgres and MySQL now has good JSON support, most of us
won't need to use a document database like MongoDB, as it would be overkill. Most of the time,
we only need to [denormalize](https://www.geeksforgeeks.org/denormalization-in-databases/) some
parts of our model. So it makes more sense to use simple JSON columns for those, instead of
going all-in, and dump your beloved relational database for MongoDB.

Currently in Rails, we have several features that we can use to interact with JSON:
- [JSON serialization](https://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html)
- [JSON column](https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb).
- [Attributes API](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute)

By combining these features, we have full control over how our JSON data is stored and
converted.

That's what this extension does, in order to provide a way to model semi-structured data in
Rails applications (in a more "structured" way). This is done by...
- Mapping JSON objects to ActiveModel-compliant objects
- Mappping JSON arrays to custom Ruby collections
- Adding support for nested attributes
- Emulating persistence to facilitate updates

## Usage
Let's say that we need to store books in our database. We might want to "embed" data such as
parts, chapters and sections without creating additional tables. By doing so, we can retrieve
all the embedded data of a book in a single read operation, instead of performing expensive
multi-table joins.

We can then model our data this way:
```ruby
class Book < ApplicationRecord
  include ActiveModel::Embedding

  embeds_many :parts
end

class Book::Part
  include ActiveModel::Document

  attribute :title, :string

  embeds_many :chapters
end

class Book::Part::Chapter
  include ActiveModel::Document

  attribute :title, :string

  embeds_many :sections
end

class Book::Part::Chapter::Section
  attribute :title, :string
  attribute :content, :string
end
```

And display it like this (with nested attributes support out-of-the-box):
```erb
# app/views/books/_form.html.erb
<%= @form_with @book do |book_form| %>
  <%= book_form.fields_for :parts do |part_fields| %>

    <%= part_fields.label :title %>
    <%= part_fields.text_area :content %>

    <%= part_fields.fields_for :chapters do |chapter_fields| %>
      <%= chapter_fields.label :title %>
      <%= chapter_fields.text_area :content %>

      <%= chapter_fields.fields_for :chapters do |chapter_fields| %>
        <%= section_fields.label :title %>
        <%= section_fields.text_area :content %>
      <% end %>
    <% end %>

  <% end %>
<% end %>
```

### Associations
#### embeds_many
Maps a JSON array to a [collection](#collection).

Options:
- `:class_name`: Specify the class of the [documents](#document) in the collection. Inferred by default.
- `:collection`: Specify a custom collection class which includes
    [`ActiveModel::Collecting`](#activemodel%3A%3Acollecting)
- (`ActiveModel::Collection` by default)
- `:cast_type`: Specify a custom type that should be used to cast the documents in the
collection. the `:class_name` is ignored if this option is present.
#### embed_one
Maps a JSON object to a [document](#document).

Options:
- `:class_name`: Same as above
- `:cast_type`: Same as above

## Warning
[Embedded associations](#embedded-associations) should only be used if you're sure that the data you want to embed is
**encapsulated**. Which means, that the data is only meant to be accessed through the parent, and not from
the outside. Thus, you should only use them if performing joins isn't a viable option. See [Why You Should Never Use
MongoDB](http://www.sarahmei.com/blog/2013/11/11/why-you-should-never-use-mongodb/) for more
insights on the use cases of this feature.

## Use case: Dealing with bibliographic data
Let's say that we are building an app to help libraries build and manage an online catalog.
When we're browsing through a catalog, we often see item information formatted like this:
```
Author:        Shakespeare, William, 1564-1616.
Title:         Hamlet / William Shakespeare.
Description:   xiii, 295 pages : illustrations ; 23 cm.
Series:        NTC Shakespeare series.
Local Call No: 822.33 S52 S7
ISBN:          0844257443
Series Entry:  NTC Shakespeare series.
Control No.:   ocm30152659
```

But in the library world, data is produced and exchanged is this form:
```
LDR 00815nam  2200289 a 4500
001 ocm30152659
003 OCoLC
005 19971028235910.0
008 940909t19941994ilua          000 0 eng
010   $a92060871
020   $a0844257443
040   $aDLC$cDLC$dBKL$dUtOrBLW
049   $aBKLA
099   $a822.33$aS52$aS7
100 1 $aShakespeare, William,$d1564-1616.
245 10$aHamlet /$cWilliam Shakespeare.
264  1$aLincolnwood, Ill. :$bNTC Pub. Group,$c[1994]
264  4$cÂ©1994.
300   $axiii, 295 pages :$billustrations ;$c23 cm.
336   $atext$btxt$2rdacontent.
337   $aunmediated$bn$2rdamedia.
338   $avolume$bnc$2rdacarrier.
490 1 $aNTC Shakespeare series.
830  0$aNTC Shakespeare series.
907   $a.b108930609
948   $aLTI 2018-07-09
948   $aMARS
```
This is what we call a *MARC record*. That's how libraries describes the ressources they own.

As you can see, that's really verbose! That's because in the library world, ressources are
described very precisely, in order to be "machine-readable" (MARC stands for "MAchine-Readable
Cataloging").

For convinience, developpers usually represent MARC data in JSON:
```json
{
  "leader": "00815nam 2200289 a 4500",
  "fields": [
    { "001": "ocm30152659" },
    { "003": "OCoLC" },
    { "005": "19971028235910.0" },
    { "008": "940909t19941994ilua 000 0 eng " },
    { "010": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "92060871" }] } },
    { "020": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "0844257443" }] } },
    { "040": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "DLC" }, { "c": "DLC" }, { "d": "BKL" }, { "d": "UtOrBLW" } ] } },
    { "049": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "BKLA" }] } },
    { "099": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "822.33" }, { "a": "S52" }, { "a": "S7" } ] } },
    { "100": { "ind1": "1", "ind2": " ", "subfields": [{ "a": "Shakespeare, William," }, { "d": "1564-1616." } ] } },
    { "245": { "ind1": "1", "ind2": "0", "subfields": [{ "a": "Hamlet" }, { "c": "William Shakespeare." } ] } },
    { "264": { "ind1": " ", "ind2": "1", "subfields": [{ "a": "Lincolnwood, Ill. :" }, { "b": "NTC Pub. Group," }, { "c": "[1994]" } ] } },
    { "264": { "ind1": " ", "ind2": "4", "subfields": [{ "c": "©1994." }] } },
    { "300": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "xiii, 295 pages :" }, { "b": "illustrations ;" }, { "c": "23 cm." } ] } },
    { "336": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "text" }, { "b": "txt" }, { "2": "rdacontent." } ] } },
    { "337": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "unmediated" }, { "b": "n" }, { "2": "rdamedia." } ] } },
    { "338": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "volume" }, { "b": "nc" }, { "2": "rdacarrier." } ] } },
    { "490": { "ind1": "1", "ind2": " ", "subfields": [{ "a": "NTC Shakespeare series." }] } },
    { "830": { "ind1": " ", "ind2": "0", "subfields": [{ "a": "NTC Shakespeare series." }] } },
    { "907": { "ind1": " ", "ind2": " ", "subfields": [{ "a": ".b108930609" }] } },
    { "948": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "LTI 2018-07-09" }] } },
    { "948": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "MARS" }] } }
  ]
}
```

By looking at this JSON representation, we can see that the data is...
- **Nested**: A MARC record contains many fields, and most of them contains multiple subfields.
- **Dynamic**: Some fields are repeatable ("264" and "948"), and subfields too. The first
    fields don't have subfields nor indicators (they're called *control fields*).
- **Encapsulated**: The meaning of subfields depends on the field they're in (take a look at
    the "a" subfield for example).

All those characteristics can be grouped into what we call: [**semi-structured
data**](#semi-structured-data).
> Semi-structured data is a form of structured data that does not obey the tabular structure of data models associated with relational databases or other forms of data tables, but nonetheless contains tags or other markers to separate semantic elements and enforce hierarchies of records and fields within the data. Therefore, it is also known as self-describing structure. - Wikipedia

A perfect example of that is HTML documents. An HTML document contains different types of tags,
which can nested with one and other. It wouldn't make sense to model HTML documents with tables
and columns. Imagine having to access nested tags through joins, considering the fact that we
could potentially have hundreds of them on a single HTML document. That's why we usually store
this kind of data in a text field.

In our case, we're using JSON to represent MARC data. Luckily for us, we can store JSON
data directly in relational databases like Postgres or MySQL:
```bash
> rails g model marc/record leader:string fields:json
> rails db:migrate
```

We can then create a MARC record like this:
```ruby
MARC::Record.create leader: "00815nam 2200289 a 4500", fields: [
  { "001": "ocm30152659" },
  { "003": "OCoLC" },
  { "005": "19971028235910.0" },
  { "008": "940909t19941994ilua 000 0 eng " },
  { "010": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "92060871" }] } },
  { "020": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "0844257443" }] } },
  { "040": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "DLC" }, { "c": "DLC" }, { "d": "BKL" }, { "d": "UtOrBLW" } ] } },
  { "049": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "BKLA" }] } },
  { "099": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "822.33" }, { "a": "S52" }, { "a": "S7" } ] } },
  { "100": { "ind1": "1", "ind2": " ", "subfields": [{ "a": "Shakespeare, William," }, { "d": "1564-1616." } ] } },
  { "245": { "ind1": "1", "ind2": "0", "subfields": [{ "a": "Hamlet" }, { "c": "William Shakespeare." } ] } },
  { "264": { "ind1": " ", "ind2": "1", "subfields": [{ "a": "Lincolnwood, Ill. :" }, { "b": "NTC Pub. Group," }, { "c": "[1994]" } ] } },
  { "264": { "ind1": " ", "ind2": "4", "subfields": [{ "c": "©1994." }] } },
  { "300": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "xiii, 295 pages :" }, { "b": "illustrations ;" }, { "c": "23 cm." } ] } },
  { "336": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "text" }, { "b": "txt" }, { "2": "rdacontent." } ] } },
  { "337": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "unmediated" }, { "b": "n" }, { "2": "rdamedia." } ] } },
  { "338": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "volume" }, { "b": "nc" }, { "2": "rdacarrier." } ] } },
  { "490": { "ind1": "1", "ind2": " ", "subfields": [{ "a": "NTC Shakespeare series." }] } },
  { "830": { "ind1": " ", "ind2": "0", "subfields": [{ "a": "NTC Shakespeare series." }] } },
  { "907": { "ind1": " ", "ind2": " ", "subfields": [{ "a": ".b108930609" }] } },
  { "948": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "LTI 2018-07-09" }] } },
  { "948": { "ind1": " ", "ind2": " ", "subfields": [{ "a": "MARS" }] } }
]
```

And access it this way:
```ruby
> record = MARC::Record.first
> record.fields["245"]["subfields"].first
=> "Hamlet"
```
It works, but we cannot attach logic to our JSON data without polluting our model. What if
we could interact with our JSON data the same way we do with ActiveRecord associations ? Enters
ActiveModel and the [AttributesAPI](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute)!

First, we have to define a custom type which...
- Maps JSON objects to ActiveModel-compliant objects
- Handles collections

To do that, we'll add the following options to our type:
- `:class_name`: The class name of an ActiveModel-compliant object.
- `:collection`: Specify if the attribute is a collection. Default to `false`.

```ruby
class DocumentType < ::ActiveModel::Type::Value
  attr_reader :document_class, :collection

  def initialize(class_name:, collection: false)
    @document_class = class_name.constantize
    @collection     = collection
  end

  def cast(value)
    if collection
      value.map { |attributes| process attributes }
    else
      process value
    end
  end

  def process(value)
    document_class.new(value)
  end

  def serialize(value)
    value.to_json
  end

  def deserialize(json)
    value = ActiveSupport::JSON.decode(json)
    cast value
  end

  # Track changes
  def changed_in_place?(old_value, new_value)
    deserialize(old_value) != new_value
  end
end
```
Let's register our type as we gonna use it multiple times:
```ruby
# config/initializers/type.rb
ActiveModel::Type.register(:document, DocumentType)
```

Now we can use it in our models:
```ruby
class MARC::Record < ApplicationRecord
  attribute :fields, :document
    class_name: "::MARC::Record::Field"
    collection: true

  # Hash-like reader method
  def [](tag)
    fields.find { |field| field.tag == tag }
  end
end
```
```ruby
class MARC::Record::Field
  include ActiveModel::Model

  attribute :tag, :string
  attribute :indicator1, :integer
  attribute :indicator2, :integer
  attribute :subfields, :document
    class_name: "::MARC::Record::Field::Subfield"
    collection: true

  attr_reader :value

  # Some domain logic
  def value=(value)
    @value = value if control_field?
  end

  def control_field?
    tag ~= /00\d/
  end

  # Yet another Hash-like reader method
  def [](code)
    subfield = subfields.find { |subfield| subfield.code == code }
    subfield.value if subfield
  end

end
```
```ruby
class MARC::Record::Field::Subfield
  attribute :code, :string
  attribute :value, :string
end
```
```ruby
> record = MARC::Record.first
> field = record.fields[10]
> field.tag
=> "245"
> subfield = field.subfields.first
> subfield.value
=> "Hamlet"
> record.fields["245"]["a"]
=> "Hamlet"
```

Et voilà ! Home-made associations !

If we want to go further, we can...
- Create our custom collection class to provide functionalities like ActiveRecord
    collection proxies.
- Add support for nested attributes.
- Emulate persistence to update specific objects.
- Provide a way to resolve constants, so that we can use the relative name of a constant
    instead of it's full name. For example, `"::MARC::Record::Field"` could be referred as
    `"Field"` in our example.

And that's what this extension does. (Nothing fancy, in fact the code is quite simple. So don't
be afraid to dive into it if you want to know how it was implemented !)

Here's how the code would look like with the extension:
```ruby
class MARC::Record < ApplicationRecord
  include ActiveModel::Embedding

  embeds_many :fields

  # ...
end
```
```ruby
class MARC::Record::Field
  include ActiveModel::Document

  # ...

  embeds_many :subfields

  # ...
end
```

We can then use our embedded associations in the views as nested attributes:
```erb
# app/views/marc/records/_form.html.erb
<%= @form_with @record do |record_form| %>
  <%= record_form.fields_for :fields do |field_fields| %>

    <%= field_fields.label :tag %>

    <% if field.control_field? %>
      <%= field_fields.text_field :value %>
    <% else %>
      <%= field_fields.number_field :indicator1
      <%= field_fields.number_field :indicator2

      <%= field_fields.fields_for :subfields do |subfield_fields| %>
        <%= subfield_fields.label :code %>
        <%= subfield_fields.text_field :value %>
      <% end %>
    <% end %>

  <% end %>
<% end %>
```

## Concepts
### Document
A JSON object mapped to a PORO which includes `ActiveModel::Document`. Usually part of a
[collection](#collection).

### Collection
A JSON array mapped to an `ActiveModel::Collection` (or any class that includes
`ActiveModel::Collecting`). Stores collections of
[documents](#document).

### Embedded associations
Models structural hierarchies in [semi-structured data](#semi-structured-data), by "embedding"
the content of children directly in the parent, instead of using references like foreign keys. See
[Embedded Data
Models](https://docs.mongodb.com/manual/core/data-model-design/#embedded-data-models) from
MongoDB's docs.

### Semi-structured data
Data that don't fit in the [relational model](https://www.digitalocean.com/community/tutorials/what-is-the-relational-model).
> Semi-structured data is a form of structured data that does not obey the tabular structure of data models associated with relational databases or other forms of data tables, but nonetheless contains tags or other markers to separate semantic elements and enforce hierarchies of records and fields within the data. Therefore, it is also known as self-describing structure. - Wikipedia


### Components
### `ActiveModel::Embedding`
API for defining [embedded associations](#embedded-associations). Uses the Attributes API with
the `:document` type.

### `ActiveModel::Type::Document`
A polymorphic cast type (registered as `:document`). Maps JSON objects to POROs that includes
`ActiveModel::Document`. Provides support for defining [collections](#collection).

### `ActiveModel::Document`
A module which includes everything needed to work with the `:document` type
(`ActiveModel::Model`, `ActiveModel::Attributes`, `ActiveModel::Serializers::JSON`,
`ActiveModel::Embedding`). Provides an `id` attribute and implements methods like `#persisted?`
and `#save` to emulate persistence.

### `ActiveModel::Collecting`
A mixin which provides capabailities similar to ActiveRecord collection proxies. Provides
support for nested attributes.

### `ActiveModel::Collection`
Default collection class. Includes `ActiveModel::Collecting`.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'activemodel-embedding', github: "mansakondo/activemodel-embedding"
```

And then execute:
```bash
$ bundle
```

## License
The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
