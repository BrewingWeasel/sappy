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
    ..parameter,
    decode: fn(a) { a |> parameter.decode() |> result.try(decode) },
    encode: fn(b) { b |> encode() |> parameter.encode() },
  )
}

pub fn map_optional(
  parameter: Parameter(Option(a)),
  encode: fn(b) -> a,
  decode: fn(a) -> Result(b, Nil),
) -> Parameter(Option(b)) {
  Parameter(
    ..parameter,
    decode: fn(a) {
      use decoded_orginal <- result.try(parameter.decode(a))
      case option.map(decoded_orginal, decode) {
        option.Some(Ok(v)) -> Ok(option.Some(v))
        option.Some(Error(e)) -> Error(e)
        option.None -> Ok(option.None)
      }
    },
    encode: fn(b) { b |> option.map(encode) |> parameter.encode() },
  )
}
