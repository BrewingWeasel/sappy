import gleam/function
import gleam/option.{type Option}
import gleam/result

pub type Parameter(a) {
  Parameter(
    name: String,
    decode: fn(Option(String)) -> Result(a, Nil),
    encode: fn(a) -> Option(String),
  )
}

pub fn required(name name: String) -> Parameter(String) {
  Parameter(
    name:,
    decode: fn(value) {
      case value {
        option.Some(v) -> Ok(v)
        option.None -> Error(Nil)
      }
    },
    encode: option.Some,
  )
}

pub fn optional(name name: String) -> Parameter(Option(String)) {
  Parameter(name:, decode: fn(value) { Ok(value) }, encode: function.identity)
}

pub fn map(
  parameter: Parameter(a),
  encode: fn(b) -> a,
  decode: fn(a) -> Result(b, Nil),
) -> Parameter(b) {
  Parameter(
    name: parameter.name,
    decode: fn(a) { a |> parameter.decode() |> result.try(decode) },
    encode: fn(b) { b |> encode() |> parameter.encode() },
  )
}
