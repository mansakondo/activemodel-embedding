# ActiveModel::Embedding [![Gem Version](https://badge.fury.io/rb/activemodel-embedding.svg)](https://badge.fury.io/rb/activemodel-embedding)
An ActiveModel extension to model your [semi-structured data](#semi-structured-data) using
[embedded associations](#embedded-associations).

- [Features](#features)
- [Introduction](#introduction)
- [Usage](#usage)
- [:warning: Warning](#warning-warning)
- [Use Case: Dealing with bibliographic data](#use-case%3A-dealing-with-bibliographic-data)
- [Concepts](#concepts)
- [Components](#components)
- [Installation](#installation)
- [License](#license)

## Features
- ActiveRecord-like associations (powered by the [Attributes API](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute))
- Nested attributes support out-of-the-box
- [Custom collections](#custom-collections)
- [Custom types](#custom-types)
- Autosaving
- Dirty tracking

## Introduction
Relational databases are very powerful. Their power comes from their ability to...
- Preserve data integrity with a predefined schema.
- Make complex relationships through joins.

But sometimes, we can stumble accross data that don't fit in the [relational
model](https://www.digitalocean.com/community/tutorials/what-is-the-relational-model). We call
this kind of data: [semi-structured data](#semi-structured-data). When this happens, the
things that makes relational databases powerful are the things that gets in our way, and
complicate our model instead of simplifying it.

That's why [document databases](https://en.wikipedia.org/wiki/Document-oriented_database)
exist, to model and store semi-structured data. However, if we choose to use a document
database, we'll loose all the power of using a relational database.

Luckily for us, relational databases like Postgres and MySQL now has good JSON support. So most
of us won't need to use a document database like MongoDB, as it would be overkill. Most of the
time, we only need to
[denormalize](https://www.geeksforgeeks.org/denormalization-in-databases/) some parts of our
model. So it makes more sense to use simple JSON columns for those, instead of going all-in,
and dump your beloved relational database for MongoDB.

Currently in Rails, we have several features that we can use to interact with JSON:
- [JSON serialization](https://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html)
- [JSON column](https://guides.rubyonrails.org/active_record_postgresql.html#json-and-jsonb)
- [Attributes API](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute)

By combining these features, we have full control over how our JSON data is stored and
retrieved from the database.

And that's what this extension does, in order to provide a convinient way to model
semi-structured data in a Rails application.

## Usage
Let's say that we need to store books in our database. We might want to "embed" data such as
parts, chapters and sections without creating additional tables. By doing so, we can retrieve
all the embedded data of a book in a single read operation, instead of performing expensive
multi-table joins.

We can then model our data this way:
```ruby
class Book < ApplicationRecord
  include ActiveModel::Embedding::Associations

  embeds_many :parts
end

class Book::Part
  include ActiveModel::Embedding::Document

  attribute :title, :string

  embeds_many :chapters
end

class Book::Part::Chapter
  include ActiveModel::Embedding::Document

  attribute :title, :string

  embeds_many :sections
end

class Book::Part::Chapter::Section
  include ActiveModel::Embedding::Document

  attribute :title, :string
  attribute :content, :string
end
```

And display it like this (with nested attributes support out-of-the-box):
```erb
# app/views/books/_form.html.erb
<%= form_with model: @book do |book_form| %>
  <%= book_form.fields_for :parts do |part_fields| %>

    <%= part_fields.label :title %>
    <%= part_fields.text_field :title %>

    <%= part_fields.fields_for :chapters do |chapter_fields| %>
      <%= chapter_fields.label :title %>
      <%= chapter_fields.text_field :title %>

      <%= chapter_fields.fields_for :sections do |section_fields| %>
        <%= section_fields.label :title %>
        <%= section_fields.text_field :title %>
        <%= section_fields.text_area :content %>
      <% end %>
    <% end %>
  <% end %>

  <%= book_form.submit %>
<% end %>
```
### Custom collections
```ruby
class SomeCollection
  include ActiveModel::Embedding::Collecting
end

class Thing
end

class SomeModel
  include ActiveModel::Embedding::Document

  embeds_many :things, collection: "SomeCollection"
end

some_model = SomeModel.new things: Array.new(3) { Thing.new }
some_model.things.class
# => SomeCollection
```
### Custom types
```ruby
# config/initializers/types.rb
class SomeType < ActiveModel::Type::Value
  def cast(value)
    value.cast_type = self.class
    super
  end
end

ActiveModel::Type.register(:some_type, SomeType)

class SomeOtherType < ActiveModel::Type::Value
  attr_reader :context

  def initialize(context:)
    @context = context
  end

  def cast(value)
    value.cast_type = self.class
    value.context = context
    super
  end
end
```
```ruby
class Thing
  attr_accessor :cast_type
  attr_accessor :context
end

class SomeModel
  include ActiveModel::Embedding::Document

  embeds_many :things, cast_type: :some_type
  embeds_many :other_things, cast_type: SomeOtherType.new(context: self)
end

@some_model.things.first.cast_type
# => SomeType
@some_model.other_things.first.cast_type
# => SomeOtherType
@some_model.other_things.first.context
# => SomeModel
```

### Associations
#### embeds_many
Maps a JSON array to a [collection](#collection).

Options:
- `:class_name`: Specify the class of the [documents](#document) in the collection. Inferred by default.
- `:collection`: Specify a custom collection class which includes
    [`ActiveModel::Collecting`](#activemodel%3A%3Acollecting) (`ActiveModel::Collection` by
    default).
- `:cast_type`: Specify a custom type that should be used to cast the documents in the
collection. (the `:class_name` is ignored if this option is present.)
#### embed_one
Maps a JSON object to a [document](#document).

Options:
- `:class_name`: Same as above.
- `:cast_type`: Same as above.

## :warning: Warning
[Embedded associations](#embedded-associations) should only be used if you're sure that the data you want to embed is
**encapsulated**. Which means, that embedded associations should only be accessed through the
parent, and not from the outside. Thus, this should only be used if performing joins isn't a
viable option.

Read the section below (and [this
article](http://www.sarahmei.com/blog/2013/11/11/why-you-should-never-use-mongodb/)) for more
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
    { "tag": "001", "value": "ocm30152659" },
    { "tag": "003", "value": "OCoLC" },
    { "tag": "005", "value": "19971028235910.0" },
    { "tag": "008", "value": "940909t19941994ilua 000 0 eng " },
    { "tag": "010", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "92060871" }] },
    { "tag": "020", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "0844257443" }] },
    { "tag": "040", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "DLC" }, { "code": "c", "value": "DLC" }, { "code": "d", "value": "BKL" }, { "code": "d", "value": "UtOrBLW" } ] },
    { "tag": "049", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "BKLA" }] },
    { "tag": "099", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "822.33" }, { "code": "a", "value": "S52" }, { "code": "a", "value": "S7" } ] },
    { "tag": "100", "indicator1": "1", "indicator2": " ", "subfields": [{ "code": "a", "value": "Shakespeare, William," }, { "code": "d", "value": "1564-1616." } ] },
    { "tag": "245", "indicator1": "1", "indicator2": "0", "subfields": [{ "code": "a", "value": "Hamlet" }, { "code": "c", "value": "William Shakespeare." } ] },
    { "tag": "264", "indicator1": " ", "indicator2": "1", "subfields": [{ "code": "a", "value": "Lincolnwood, Ill. :" }, { "code": "b", "value": "NTC Pub. Group," }, { "code": "c", "value": "[1994]" } ] },
    { "tag": "264", "indicator1": " ", "indicator2": "4", "subfields": [{ "code": "c", "value": "©1994." }] },
    { "tag": "300", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "xiii, 295 pages :" }, { "code": "b", "value": "illustrations ;" }, { "code": "c", "value": "23 cm." } ] },
    { "tag": "336", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "text" }, { "code": "b", "value": "txt" }, { "code": "2", "value": "rdacontent." } ] },
    { "tag": "337", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "unmediated" }, { "code": "b", "value": "n" }, { "code": "2", "value": "rdamedia." } ] },
    { "tag": "338", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "volume" }, { "code": "b", "value": "nc" }, { "code": "2", "value": "rdacarrier." } ] },
    { "tag": "490", "indicator1": "1", "indicator2": " ", "subfields": [{ "code": "a", "value": "NTC Shakespeare series." }] },
    { "tag": "830", "indicator1": " ", "indicator2": "0", "subfields": [{ "code": "a", "value": "NTC Shakespeare series." }] },
    { "tag": "907", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": ".b108930609" }] },
    { "tag": "948", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "LTI 2018-07-09" }] },
    { "tag": "948", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "MARS" }] }
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

```ruby
# config/initializers/inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym "MARC"
end
```

```bash
> rails g model marc/record leader:string fields:json
> rails db:migrate
```

We can then create a MARC record like this:
```ruby
MARC::Record.create leader: "00815nam 2200289 a 4500", fields: [
  { "tag": "001", "value": "ocm30152659" },
  { "tag": "003", "value": "OCoLC" },
  { "tag": "005", "value": "19971028235910.0" },
  { "tag": "008", "value": "940909t19941994ilua 000 0 eng " },
  { "tag": "010", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "92060871" }] },
  { "tag": "020", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "0844257443" }] },
  { "tag": "040", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "DLC" }, { "code": "c", "value": "DLC" }, { "code": "d", "value": "BKL" }, { "code": "d", "value": "UtOrBLW" } ] },
  { "tag": "049", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "BKLA" }] },
  { "tag": "099", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "822.33" }, { "code": "a", "value": "S52" }, { "code": "a", "value": "S7" } ] },
  { "tag": "100", "indicator1": "1", "indicator2": " ", "subfields": [{ "code": "a", "value": "Shakespeare, William," }, { "code": "d", "value": "1564-1616." } ] },
  { "tag": "245", "indicator1": "1", "indicator2": "0", "subfields": [{ "code": "a", "value": "Hamlet" }, { "code": "c", "value": "William Shakespeare." } ] },
  { "tag": "264", "indicator1": " ", "indicator2": "1", "subfields": [{ "code": "a", "value": "Lincolnwood, Ill. :" }, { "code": "b", "value": "NTC Pub. Group," }, { "code": "c", "value": "[1994]" } ] },
  { "tag": "264", "indicator1": " ", "indicator2": "4", "subfields": [{ "code": "c", "value": "©1994." }] },
  { "tag": "300", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "xiii, 295 pages :" }, { "code": "b", "value": "illustrations ;" }, { "code": "c", "value": "23 cm." } ] },
  { "tag": "336", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "text" }, { "code": "b", "value": "txt" }, { "code": "2", "value": "rdacontent." } ] },
  { "tag": "337", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "unmediated" }, { "code": "b", "value": "n" }, { "code": "2", "value": "rdamedia." } ] },
  { "tag": "338", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "volume" }, { "code": "b", "value": "nc" }, { "code": "2", "value": "rdacarrier." } ] },
  { "tag": "490", "indicator1": "1", "indicator2": " ", "subfields": [{ "code": "a", "value": "NTC Shakespeare series." }] },
  { "tag": "830", "indicator1": " ", "indicator2": "0", "subfields": [{ "code": "a", "value": "NTC Shakespeare series." }] },
  { "tag": "907", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": ".b108930609" }] },
  { "tag": "948", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "LTI 2018-07-09" }] },
  { "tag": "948", "indicator1": " ", "indicator2": " ", "subfields": [{ "code": "a", "value": "MARS" }] }
]
```

And access it this way:
```ruby
> record = MARC::Record.first
> field = record.fields.find { |field| field["tag"] == "245" }
> subfield = field["subfields"].first
> subfield["value"]
=> "Hamlet"
```
It works, but...
- It's not very convinient to access nested data this way.
- We cannot easily attach logic to our JSON data without polluting our model.

What if we could interact with our JSON data the same way we do with ActiveRecord associations
? Enters ActiveModel and the
[AttributesAPI](https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html#method-i-attribute)
!

First, we have to define a custom type which...
- Maps JSON objects to ActiveModel-compliant objects.
- Handles collections.

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
ActiveRecord::Type.register(:document, DocumentType)
```

Now we can use it in our models:
```ruby
class MARC::Record < ApplicationRecord
  attribute :fields, :document,
    class_name: "MARC::Record::Field",
    collection: true

  # Hash-like reader method
  def [](tag)
    occurences = fields.select { |field| field.tag == tag }
    occurences.first unless occurences.count > 1
  end
end
```
```ruby
class MARC::Record::Field
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON

  attribute :tag, :string
  attribute :indicator1, :string
  attribute :indicator2, :string
  attribute :subfields, :document,
    class_name: "MARC::Record::Field::Subfield",
    collection: true

  attribute :value, :string

  # Some domain logic
  def value=(value)
    @value = value if control_field?
  end

  def control_field?
    /00\d/ === tag
  end

  # Yet another Hash-like reader method
  def [](code)
    occurences = subfields.find { |subfield| subfield.code == code }
    occurences.first unless occurences.count > 1
  end

  # Used to track changes
  def ==(other)
    attributes == other.attributes
  end
end
```
```ruby
class MARC::Record::Field::Subfield
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON

  attribute :code, :string
  attribute :value, :string

  # Used to track changes
  def ==(other)
    attributes == other.attributes
  end
end
```
```ruby
> record = MARC::Record.first
> record.fields.first.class
=> MARC::Record::Field

> record.fields.first.control_field?
=> true

> record.fields.first.subfields.first.class
=> MARC::Record::Field::Subfield

> record["245"]["a"].value
=> "Hamlet"

> record.changed?
=> false

> record["245"]["a"].value = "Romeo and Juliet"
> record["245"]["a"].value
=> "Romeo and Juliet"

> record.changed?
=> true
```

Et voilà ! Home-made associations !

If we want to go further, we can...
- Create our custom collection class to provide functionalities like ActiveRecord
    collection proxies.
- Add support for nested attributes.
- Emulate persistence to update specific objects.
- Provide a way to resolve constants, so that we can use the relative name of a constant
    instead of it's full name. For example, `"MARC::Record::Field"` could be referred as
    `"Field"` in our example.

And that's what this extension does. (Nothing fancy, in fact the code is quite simple. So don't
be afraid to dive into it if you want to know how it was implemented !)

Here's the updated version with the extension:
```ruby
class MARC::Record < ApplicationRecord
  include ActiveModel::Embedding::Associations

  embeds_many :fields

  # ...
end
```
```ruby
class MARC::Record::Field
  include ActiveModel::Embedding::Document

  # ...

  embeds_many :subfields

  # ...
end
```
```ruby
class MARC::Record::Field::Subfield
  include ActiveModel::Embedding::Document

  # ...
end
```

We can then use our embedded associations in the views as nested attributes:
```erb
# app/views/marc/records/_form.html.erb
<%= form_with model: @record do |record_form| %>
  <% @record.fields.each do |field| %>
    <%= record_form.fields_for :fields, field do |field_fields| %>

      <%= field_fields.label :tag %>
      <%= field_fields.text_field :tag %>

      <% if field.control_field? %>
        <%= field_fields.text_field :value %>
      <% else %>
        <%= field_fields.text_field :indicator1 %>
        <%= field_fields.text_field :indicator2 %>

        <%= field_fields.fields_for :subfields do |subfield_fields| %>
          <%= subfield_fields.label :code %>
          <%= subfield_fields.text_field :code %>
          <%= subfield_fields.text_field :value %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>

  <%= record_form.submit %>
<% end %>
```


## Concepts
### Document
A JSON object mapped to a PORO which includes `ActiveModel::Embedding::Document`. Usually part of a
[collection](#collection).

### Collection
A JSON array mapped to an `ActiveModel::Embedding::Collection` (or any class that includes
`ActiveModel::Embedding::Collecting`). Stores collections of
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


## Components
### `ActiveModel::Type::Document`
A polymorphic cast type (registered as `:document`). Maps JSON objects to POROs that includes
`ActiveModel::Embedding::Document`. Provides support for defining [collections](#collection).

### `ActiveModel::Embedding::Associations`
API for defining [embedded associations](#embedded-associations). Uses the Attributes API with
the `:document` type.

### `ActiveModel::Embedding::Document`
A module which includes everything needed to work with the `:document` type
(`ActiveModel::Model`, `ActiveModel::Attributes`, `ActiveModel::Serializers::JSON`,
`ActiveModel::Embedding::Associations`). Provides an `id` attribute and implements methods like `#persisted?`
and `#save` to emulate persistence.

### `ActiveModel::Embedding::Collecting`
A module which provides capabailities similar to ActiveRecord collection proxies. Provides
support for nested attributes.

### `ActiveModel::Embedding::Collection`
Default collection class. Includes `ActiveModel::Embedding::Collecting`.

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'activemodel-embedding'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install activemodel-embedding
```

## License
The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Alternatives
Here's are some alternatives I came accross after I've started working on this gem:
- [attr_json](https://github.com/jrochkind/attr_json)
- [store_model](https://github.com/DmitryTsepelev/store_model)

Each one uses a different approach to solve the same problem.
