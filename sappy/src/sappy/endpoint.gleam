import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/option.{Some}
import gleam/result
import sappy.{type Parameters, EndPoint}

pub type EndPoint(input, output) =
  sappy.EndPoint(input, output)

pub fn new(host host, path endpoint) -> EndPoint(Nil, Nil) {
  EndPoint(
    scheme: http.Https,
    method: http.Get,
    host:,
    endpoint:,
    encode_input: fn(_) { #(dict.new(), "") },
    decode_input: fn(_) { Ok(Nil) },
    encode_output: Some(fn(_) { "" }),
    decode_output: fn(_) { Ok(Nil) },
  )
}

pub fn with_scheme(
  endpoint: EndPoint(input, output),
  scheme: http.Scheme,
) -> EndPoint(input, output) {
  EndPoint(..endpoint, scheme:)
}

pub fn with_method(
  endpoint: EndPoint(input, output),
  method: http.Method,
) -> EndPoint(input, output) {
  EndPoint(..endpoint, method:)
}

pub fn with_parameters(
  current: EndPoint(Nil, output),
) -> EndPoint(Parameters, output) {
  EndPoint(
    ..current,
    encode_input: fn(params) { #(params, "") },
    decode_input: fn(input) {
      let #(params, _body) = input
      Ok(params)
    },
  )
}

pub fn with_parameters_as_input(
  current: EndPoint(Nil, output),
  encode_parameters: fn(input) -> Parameters,
  decode_parameters: fn(Parameters) -> Result(input, Nil),
) -> EndPoint(input, output) {
  EndPoint(
    ..current,
    encode_input: fn(input) { #(encode_parameters(input), "") },
    decode_input: fn(input) {
      let #(params, _body) = input
      decode_parameters(params)
    },
  )
}

pub fn with_json_body(
  current: EndPoint(Nil, output),
  to_json encode_json: fn(input) -> json.Json,
  decoder decoder: decode.Decoder(input),
) -> EndPoint(input, output) {
  EndPoint(
    ..current,
    encode_input: fn(input) {
      #(dict.new(), input |> encode_json() |> json.to_string())
    },
    decode_input: fn(input) {
      let #(_params, body) = input
      json.parse(body, decoder) |> result.replace_error(Nil)
    },
  )
}

pub fn with_body(
  current: EndPoint(Nil, output),
  encode_body: fn(input) -> String,
  decode_body: fn(String) -> Result(input, Nil),
) -> EndPoint(input, output) {
  EndPoint(
    ..current,
    encode_input: fn(input) { #(dict.new(), encode_body(input)) },
    decode_input: fn(input) {
      let #(_params, body) = input
      decode_body(body)
    },
  )
}

pub fn with_body_and_parameters(
  current: EndPoint(Nil, output),
  encode_input: fn(input) -> #(Parameters, String),
  decode_input: fn(Parameters, String) -> Result(input, Nil),
) -> EndPoint(input, output) {
  EndPoint(..current, encode_input:, decode_input: fn(params) {
    let #(params, body) = params
    decode_input(params, body)
  })
}

pub fn returning(
  current: EndPoint(input, Nil),
  encode_output: fn(output) -> String,
  decode_output: fn(String) -> Result(output, Nil),
) -> EndPoint(input, output) {
  EndPoint(..current, encode_output: Some(encode_output), decode_output:)
}

pub fn returning_json(
  current: EndPoint(input, Nil),
  to_json encode_json: fn(output) -> json.Json,
  decoder decoder: decode.Decoder(output),
) -> EndPoint(input, output) {
  EndPoint(
    ..current,
    encode_output: Some(fn(output) {
      output |> encode_json() |> json.to_string()
    }),
    decode_output: fn(encoded_output) {
      json.parse(encoded_output, decoder) |> result.replace_error(Nil)
    },
  )
}
