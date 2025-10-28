import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string
import gleam/uri

pub type Parameters =
  dict.Dict(String, String)

pub type Error =
  Nil

pub opaque type EndPoint(input, output) {
  EndPoint(
    scheme: http.Scheme,
    method: http.Method,
    endpoint: String,
    host: String,
    encode_input: fn(input) -> #(Parameters, String),
    decode_input: fn(#(Parameters, String)) -> Result(input, Error),
    encode_output: Option(fn(output) -> String),
    decode_output: fn(String) -> Result(output, Error),
  )
}

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

// Endpoint data

@internal
pub fn server_handle_request(
  endpoint: EndPoint(input, output),
  request: request.Request(body),
) -> Result(
  #(fn(String) -> Result(input, Error), Option(fn(output) -> String)),
  Error,
) {
  let parsed_attributes =
    endpoint.endpoint
    |> uri.path_segments()
    |> list.strict_zip(request.path_segments(request))
    |> result.try(
      list.fold_until(_, Ok(dict.new()), fn(attributes, items) {
        let #(endpoint, actual_request) = items

        case endpoint, attributes {
          "$" <> attribute, Ok(attributes) -> {
            list.Continue(
              Ok(dict.insert(attributes, attribute, actual_request)),
            )
          }
          v, Ok(attributes) if actual_request == v ->
            list.Continue(Ok(attributes))
          _, _ -> list.Stop(Error(Nil))
        }
      }),
    )

  case request.method == endpoint.method, parsed_attributes {
    True, Ok(path_attributes) ->
      Ok(#(
        fn(body) { endpoint.decode_input(#(path_attributes, body)) },
        endpoint.encode_output,
      ))
    _, _ -> Error(Nil)
  }
}

@internal
pub fn client_create_request(
  endpoint: EndPoint(input, output),
  input: input,
  request_mapper: fn(request.Request(String), String) -> request.Request(body),
) -> Result(request.Request(body), Error) {
  let #(params, body) = endpoint.encode_input(input)

  use #(leftover_params, segments) <- result.try(
    uri.path_segments(endpoint.endpoint)
    |> list.fold_until(Ok(#(params, [])), fn(acc, current_parameter) {
      let assert Ok(#(params, path_segments)) = acc

      case current_parameter {
        "$" <> attribute -> {
          case dict.get(params, attribute) {
            Ok(value) ->
              list.Continue(
                Ok(#(dict.delete(params, attribute), [value, ..path_segments])),
              )
            Error(Nil) -> list.Stop(Error(Nil))
          }
        }
        segment -> list.Continue(Ok(#(params, [segment, ..path_segments])))
      }
    }),
  )

  request.new()
  |> request.set_host(endpoint.host)
  |> request.set_scheme(endpoint.scheme)
  |> request.set_method(endpoint.method)
  |> request.set_path(segments |> list.reverse() |> string.join("/"))
  |> request.set_query(leftover_params |> dict.to_list())
  |> request.set_body(body)
  |> request_mapper(body)
  |> Ok()
}

@internal
pub fn client_handle_response(
  endpoint: EndPoint(input, output),
  response: response.Response(String),
) -> Result(output, Error) {
  endpoint.decode_output(response.body)
}
