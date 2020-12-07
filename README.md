# Bens Json Serializer For Wheels - Swaps renderWith()'s use of serializeJson() with Ben Nadel's JsonSerializer

Author: [Brandon Shea]

CFWheel use's serializeJSON when rendering content as JSON. The results vary based on
the Coldfusion engine in use. In order to have more control of the resulting data,
this plugin overrides core.renderWith() to use Ben Nadel's JsonSerializer instead
of serializeJson().

## Methods

- initBenSerializer() - Initialize JsonSerializer.
- initBenSerializerDefault() - Initialize JsonSerializer with default mappings for typical wheels fields, foreign keys defined in database, and dates defined as such in the database.
- benSerializeJSON( data ) - Serialize data with app initialized or new JsonSerializer. If there is no serializer defined in params or application.wheels scope, a default one will be initialized for the serialization attempt.
- (Overriden) renderWith( ... ) - Overriden CFWheels core function to swap out use
  of serializeJson with JsonSerializer.

---

# JsonSerializer.cfc - Data Serialization Utility for ColdFusion

Copied & Modified for CFWheels by [Brandon Shea] <br/>
Originaly by [Ben Nadel][1] <br/>
Original source at [Github][2] <br/>

ColdFusion is a case insensitive language. However, it often has to communicate
with languages, like JavaScript, that are not case sensitive. During the data
serialization workflow, this mismatch of casing can cause a lot of headaches,
especially when ColdFusion is your API-back-end to a rich-client JavaScript
front-end application.

JsonSerializer.cfc is a ColdFusion component that helps ease this transition by
performing the serialization to JavaScript Object Notation (JSON) using a set
of developer-defined rules for case-management and data-conversion-management.
Essentially, you can tell the serializer what case to use, no matter what case
the data currently has.

## Methods

- asAny( key ) - Simply defines the key-casing, without any data conversion.
- asBoolean( key ) - Attempts to force the value to be a true boolean.
- asDate( key ) - Converts the date to an ISO 8601 time string.
- asFloat( key ) - Attempts to force the value to be a true float.
- asInteger( key ) - Attempts to force the value to be a true integer.
- asString( key ) - Forces the value to be a string (including numeric values).
- exclude( key ) - Will exclude the key from the serialization process.
- (NEW) asType( type, key ) - wrapper for the above functions, passing in a 'type' to determine which is called.

## All-or-Nothing

The keys are defined using an all-or-nothing approach. By that, I mean that the
serializer doesn't care where it encounters a key - if it matches, it will be
given the explicitly defined casing. So, if you want to use "id" in one place
and "ID" in another place within the same data-structure, you're out of luck.
Both keys will match "id" and will be given the same case.

## API Philosophy

This is primarily intended to be used to return data from a server-side API. As
part of that use-case, some of my philosophy is baked into it. Namely, an API
usually returns a top-level struct / hash-map that defines the API result. This
is why the serialization process is driven by the name of keys.

[1]: http://www.bennadel.com
[2]: https://github.com/bennadel/JsonSerializer.cfc

---
