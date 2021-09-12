# ActiveModel::Embedding
An ActiveModel extension to model your [semi-structured data](https://en.wikipedia.org/wiki/Semi-structured_data#:~:text=Semi%2Dstructured%20data%20is%20a,and%20fields%20within%20the%20data.) using [embedded associations](https://docs.mongodb.com/manual/core/data-model-design/#embedded-data-models).

## Usage
```ruby
# app/models/document.rb
class Document < ApplicationRecord
  include ActiveModel::Embedding

  embeds_many :headings
end

# app/models/heading.rb
class Heading
  include ActiveModel::Document

  attribute :content, :string

  embeds_many :subheadings
end

# app/models/subheading.rb
class Subheading
  attribute :content, :string
end
```
```erb
# app/views/documents/_form.html.erb
<%= @form_with @document do |f| %>
  <%= f.fields_for :headings do |heading_fields| %>
    <%= heading_fields.label :content %>
    <%= heading_fields.fields_for :subheadings do |subheading_fields| %>
      <%= subheading_fields.label :content %>
    <% end %>
  <% end %>
<% end %>
```

# How it works
## `ActiveModel::Type::Document`
A polymorphic cast type (registered as `:document`). Maps JSON documents/objects to ActiveModel
objects. Provides support for defining collections. Designed to work with classes that includes
`ActiveModel::Document`.

## `ActiveModel::Embedding`
API for defining embedded associations. Uses the Attributes API with the `:document` type.

## `ActiveModel::Document`
A module which includes everything needed to work with the `:document` type. Provides an `id`
attribute and implements methods like `#persisted?` and `#save` to emulate persistence.

## `ActiveModel::Collecting`
A mixin which provides capabailities similar to ActiveRecord collection proxies. Provides
support for nested attributes.

## `ActiveModel::Collection`
Default collection class. Includes `ActiveModel::Collecting`.

# Use case: Dealing with bibliographic data
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
    { "245": { "ind1": "1", "ind2": "0", "subfields": [{ "a": "Hamlet /" }, { "c": "William Shakespeare." } ] } },
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

All those characteristics can be grouped into what we call: **semi-structured data**.
> Semi-structured data is a form of structured data that does not obey the tabular structure of data models associated with relational databases or other forms of data tables, but nonetheless contains tags or other markers to separate semantic elements and enforce hierarchies of records and fields within the data. Therefore, it is also known as self-describing structure. - Wikipedia

A perfect example of that is HTML documents. An HTML document contains many tags, which can
nested with one and other. It wouldn't make sense to model HTML documents with tables and
columns. Imagine having to access nested tags through joins, considering the fact that we could
potentially have hundreds of them on a single HTML document.

So how can we model MARC data ?
```ruby
class MARC::Record < ApplicationRecord
  include ActiveModel::Embedding

  embeds_many :fields

  def each
    return self.to_enum unless block_given?
    fields.each { |field| yield field }
  end
end

class MARC::Record::Field
  include ActiveModel::Document

  attribute :tag, :string
  attribute :indicator1, :integer
  attribute :indicator2, :integer
  attribute :value, :string
  
  embeds_many :subfields

  def control_field?
    tag ~= /00\d/
  end
end

class MARC::Record::Field::Subfield
  attribute :code, :string
  attribute :value, :string
end
```
```erb
# app/views/marc/records/_form.html.erb
<%= @form_with @record do |record_form| %>
  <% @record.each do |field| %>
    <%= record_form.fields_for :fields, field do |field_fields| %>
      <%= field_fields.label :tag %>
      <% if field.control_field? %>
        <%= field_fields.text_field :value %>
      <% else %>
        <%= field_fields.number_field :indicator1 %>
        <%= field_fields.number_field :indicator2 %>
        <%= field_fields.fields_for :subfields do |subfield_fields| %>
          <%= subfield_fields.label :code %>
          <%= subfield_fields.text_field :value %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
```

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'activemodel-embedding', git: "https://github.com/mansakondo/activemodel-embedding"
```

And then execute:
```bash
$ bundle
```
## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).
