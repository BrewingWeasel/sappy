import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri
import sappy/endpoint/parameter

pub type Parameters =
  dict.Dict(String, String)

pub type Error {
  MissingParameter(String)
  JsonDecodeError(json.DecodeError)
  Custom(String)
  IncorrectMethod(got: http.Method, expected: http.Method)
}

pub fn error_to_string(error: Error) -> String {
  case error {
    MissingParameter(name) -> "Missing parameter: " <> name
    JsonDecodeError(_decode_error) -> "JSON decode error"
    Custom(message) -> "Error: " <> message
    IncorrectMethod(got, expected) ->
      "Incorrect method: got "
      <> http.method_to_string(got)
      <> ", expected "
      <> http.method_to_string(expected)
  }
}

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

pub fn with_parameter(
  current: EndPoint(Nil, output),
  parameter: parameter.Parameter(a),
) -> EndPoint(a, output) {
  EndPoint(
    ..current,
    encode_input: fn(param) {
      let params = case parameter.encode(param) {
        Some(value) -> dict.insert(dict.new(), parameter.name, value)
        None -> dict.new()
      }
      #(params, "")
    },
    decode_input: fn(input) {
      let #(params, _body) = input
      let param = dict.get(params, parameter.name)
      use param <- result.try(
        parameter.decode(option.from_result(param))
        |> result.replace_error(MissingParameter(parameter.name)),
      )
      Ok(param)
    },
  )
}

pub fn with_parameters2(
  current: EndPoint(Nil, output),
  parameter1: parameter.Parameter(a),
  parameter2: parameter.Parameter(b),
) -> EndPoint(#(a, b), output) {
  EndPoint(
    ..current,
    encode_input: fn(param) {
      let #(param1, param2) = param
      let params =
        [
          #(parameter1.encode(param1), parameter1.name),
          #(parameter2.encode(param2), parameter2.name),
        ]
        |> list.fold(dict.new(), fn(acc, item) {
          case item {
            #(Some(value), name) -> dict.insert(acc, name, value)
            #(None, _name) -> acc
          }
        })
      #(params, "")
    },
    decode_input: fn(input) {
      let #(params, _body) = input
      let param1 = dict.get(params, parameter1.name)
      use param1 <- result.try(
        parameter1.decode(option.from_result(param1))
        |> result.replace_error(MissingParameter(parameter1.name)),
      )

      let param2 = dict.get(params, parameter2.name)
      use param2 <- result.try(
        parameter2.decode(option.from_result(param2))
        |> result.replace_error(MissingParameter(parameter2.name)),
      )

      Ok(#(param1, param2))
    },
  )
}

pub fn with_parameters3(
  current: EndPoint(Nil, output),
  parameter1: parameter.Parameter(a),
  parameter2: parameter.Parameter(b),
  parameter3: parameter.Parameter(c),
) -> EndPoint(#(a, b, c), output) {
  EndPoint(
    ..current,
    encode_input: fn(param) {
      let #(param1, param2, param3) = param
      let params =
        [
          #(parameter1.encode(param1), parameter1.name),
          #(parameter2.encode(param2), parameter2.name),
          #(parameter3.encode(param3), parameter3.name),
        ]
        |> list.fold(dict.new(), fn(acc, item) {
          case item {
            #(Some(value), name) -> dict.insert(acc, name, value)
            #(None, _name) -> acc
          }
        })
      #(params, "")
    },
    decode_input: fn(input) {
      let #(params, _body) = input
      let param1 = dict.get(params, parameter1.name)
      use param1 <- result.try(
        parameter1.decode(option.from_result(param1))
        |> result.replace_error(MissingParameter(parameter1.name)),
      )

      let param2 = dict.get(params, parameter2.name)
      use param2 <- result.try(
        parameter2.decode(option.from_result(param2))
        |> result.replace_error(MissingParameter(parameter2.name)),
      )

      let param3 = dict.get(params, parameter3.name)
      use param3 <- result.try(
        parameter3.decode(option.from_result(param3))
        |> result.replace_error(MissingParameter(parameter3.name)),
      )

      Ok(#(param1, param2, param3))
    },
  )
}

pub fn with_parameters4(
  current: EndPoint(Nil, output),
  parameter1: parameter.Parameter(a),
  parameter2: parameter.Parameter(b),
  parameter3: parameter.Parameter(c),
  parameter4: parameter.Parameter(d),
) -> EndPoint(#(a, b, c, d), output) {
  EndPoint(
    ..current,
    encode_input: fn(param) {
      let #(param1, param2, param3, param4) = param
      let params =
        [
          #(parameter1.encode(param1), parameter1.name),
          #(parameter2.encode(param2), parameter2.name),
          #(parameter3.encode(param3), parameter3.name),
          #(parameter4.encode(param4), parameter4.name),
        ]
        |> list.fold(dict.new(), fn(acc, item) {
          case item {
            #(Some(value), name) -> dict.insert(acc, name, value)
            #(None, _name) -> acc
          }
        })
      #(params, "")
    },
    decode_input: fn(input) {
      let #(params, _body) = input
      let param1 = dict.get(params, parameter1.name)
      use param1 <- result.try(
        parameter1.decode(option.from_result(param1))
        |> result.replace_error(MissingParameter(parameter1.name)),
      )

      let param2 = dict.get(params, parameter2.name)
      use param2 <- result.try(
        parameter2.decode(option.from_result(param2))
        |> result.replace_error(MissingParameter(parameter2.name)),
      )

      let param3 = dict.get(params, parameter3.name)
      use param3 <- result.try(
        parameter3.decode(option.from_result(param3))
        |> result.replace_error(MissingParameter(parameter3.name)),
      )

      let param4 = dict.get(params, parameter4.name)
      use param4 <- result.try(
        parameter4.decode(option.from_result(param4))
        |> result.replace_error(MissingParameter(parameter3.name)),
      )

      Ok(#(param1, param2, param3, param4))
    },
  )
}

pub fn with_parameters5(
  current: EndPoint(Nil, output),
  parameter1: parameter.Parameter(a),
  parameter2: parameter.Parameter(b),
  parameter3: parameter.Parameter(c),
  parameter4: parameter.Parameter(d),
  parameter5: parameter.Parameter(e),
) -> EndPoint(#(a, b, c, d, e), output) {
  EndPoint(
    ..current,
    encode_input: fn(param) {
      let #(param1, param2, param3, param4, param5) = param
      let params =
        [
          #(parameter1.encode(param1), parameter1.name),
          #(parameter2.encode(param2), parameter2.name),
          #(parameter3.encode(param3), parameter3.name),
          #(parameter4.encode(param4), parameter4.name),
          #(parameter5.encode(param5), parameter5.name),
        ]
        |> list.fold(dict.new(), fn(acc, item) {
          case item {
            #(Some(value), name) -> dict.insert(acc, name, value)
            #(None, _name) -> acc
          }
        })
      #(params, "")
    },
    decode_input: fn(input) {
      let #(params, _body) = input
      let param1 = dict.get(params, parameter1.name)
      use param1 <- result.try(
        parameter1.decode(option.from_result(param1))
        |> result.replace_error(MissingParameter(parameter1.name)),
      )

      let param2 = dict.get(params, parameter2.name)
      use param2 <- result.try(
        parameter2.decode(option.from_result(param2))
        |> result.replace_error(MissingParameter(parameter2.name)),
      )

      let param3 = dict.get(params, parameter3.name)
      use param3 <- result.try(
        parameter3.decode(option.from_result(param3))
        |> result.replace_error(MissingParameter(parameter3.name)),
      )

      let param4 = dict.get(params, parameter4.name)
      use param4 <- result.try(
        parameter4.decode(option.from_result(param4))
        |> result.replace_error(MissingParameter(parameter4.name)),
      )

      let param5 = dict.get(params, parameter5.name)
      use param5 <- result.try(
        parameter5.decode(option.from_result(param5))
        |> result.replace_error(MissingParameter(parameter5.name)),
      )

      Ok(#(param1, param2, param3, param4, param5))
    },
  )
}

pub fn with_parameters6(
  current: EndPoint(Nil, output),
  parameter1: parameter.Parameter(a),
  parameter2: parameter.Parameter(b),
  parameter3: parameter.Parameter(c),
  parameter4: parameter.Parameter(d),
  parameter5: parameter.Parameter(e),
  parameter6: parameter.Parameter(f),
) -> EndPoint(#(a, b, c, d, e, f), output) {
  EndPoint(
    ..current,
    encode_input: fn(param) {
      let #(param1, param2, param3, param4, param5, param6) = param
      let params =
        [
          #(parameter1.encode(param1), parameter1.name),
          #(parameter2.encode(param2), parameter2.name),
          #(parameter3.encode(param3), parameter3.name),
          #(parameter4.encode(param4), parameter4.name),
          #(parameter5.encode(param5), parameter5.name),
          #(parameter6.encode(param6), parameter6.name),
        ]
        |> list.fold(dict.new(), fn(acc, item) {
          case item {
            #(Some(value), name) -> dict.insert(acc, name, value)
            #(None, _name) -> acc
          }
        })
      #(params, "")
    },
    decode_input: fn(input) {
      let #(params, _body) = input
      let param1 = dict.get(params, parameter1.name)
      use param1 <- result.try(
        parameter1.decode(option.from_result(param1))
        |> result.replace_error(MissingParameter(parameter1.name)),
      )

      let param2 = dict.get(params, parameter2.name)
      use param2 <- result.try(
        parameter2.decode(option.from_result(param2))
        |> result.replace_error(MissingParameter(parameter2.name)),
      )

      let param3 = dict.get(params, parameter3.name)
      use param3 <- result.try(
        parameter3.decode(option.from_result(param3))
        |> result.replace_error(MissingParameter(parameter3.name)),
      )

      let param4 = dict.get(params, parameter4.name)
      use param4 <- result.try(
        parameter4.decode(option.from_result(param4))
        |> result.replace_error(MissingParameter(parameter4.name)),
      )

      let param5 = dict.get(params, parameter5.name)
      use param5 <- result.try(
        parameter5.decode(option.from_result(param5))
        |> result.replace_error(MissingParameter(parameter5.name)),
      )

      let param6 = dict.get(params, parameter6.name)
      use param6 <- result.try(
        parameter6.decode(option.from_result(param6))
        |> result.replace_error(MissingParameter(parameter6.name)),
      )

      Ok(#(param1, param2, param3, param4, param5, param6))
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
      json.parse(body, decoder) |> result.map_error(JsonDecodeError)
    },
  )
}

pub fn with_body(
  current: EndPoint(Nil, output),
  encode_body: fn(input) -> String,
  decode_body: fn(String) -> Result(input, Error),
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

pub fn and_with_json_body(
  current: EndPoint(original_input, output),
  to_json encode_json: fn(input) -> json.Json,
  decoder decoder: decode.Decoder(input),
) -> EndPoint(#(original_input, input), output) {
  EndPoint(
    ..current,
    encode_input: fn(input) {
      let #(original_input, new_input) = input
      let #(params, _original_body) = current.encode_input(original_input)
      #(params, new_input |> encode_json() |> json.to_string())
    },
    decode_input: fn(input) {
      use decoded_original <- result.try(current.decode_input(input))
      let #(_params, body) = input

      use decoded_new <- result.try(
        json.parse(body, decoder) |> result.map_error(JsonDecodeError),
      )

      Ok(#(decoded_original, decoded_new))
    },
  )
}

pub fn and_with_body(
  current: EndPoint(original_input, output),
  encode_body: fn(input) -> String,
  decode_body: fn(String) -> Result(input, Error),
) -> EndPoint(#(original_input, input), output) {
  EndPoint(
    ..current,
    encode_input: fn(input) {
      let #(original_input, new_input) = input
      let #(params, _original_body) = current.encode_input(original_input)
      #(params, encode_body(new_input))
    },
    decode_input: fn(input) {
      use decoded_original <- result.try(current.decode_input(input))
      let #(_params, body) = input

      use decoded_new <- result.try(decode_body(body))

      Ok(#(decoded_original, decoded_new))
    },
  )
}

pub fn map_input(
  current: EndPoint(original_input, output),
  encode: fn(new_input) -> original_input,
  decode: fn(original_input) -> Result(new_input, Error),
) -> EndPoint(new_input, output) {
  EndPoint(
    ..current,
    encode_input: fn(new_input) { current.encode_input(encode(new_input)) },
    decode_input: fn(input) {
      use decoded_original <- result.try(current.decode_input(input))
      decode(decoded_original)
    },
  )
}

pub fn returning(
  current: EndPoint(input, Nil),
  encode_output: fn(output) -> String,
  decode_output: fn(String) -> Result(output, Error),
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
      json.parse(encoded_output, decoder) |> result.map_error(JsonDecodeError)
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
  Nil,
) {
  use parsed_attributes <- result.try(
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
    ),
  )
  let uri = request.to_uri(request)
  let query_attributes =
    uri.query
    |> option.to_result(Nil)
    |> result.try(uri.parse_query)
    |> result.unwrap([])
    |> dict.from_list()

  let attributes =
    dict.combine(query_attributes, parsed_attributes, with: fn(v1, _v2) { v1 })

  Ok(#(
    fn(body) {
      use <- bool.guard(
        request.method != endpoint.method,
        Error(IncorrectMethod(got: request.method, expected: endpoint.method)),
      )
      endpoint.decode_input(#(attributes, body))
    },
    endpoint.encode_output,
  ))
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
        "$" <> parameter -> {
          case dict.get(params, parameter) {
            Ok(value) ->
              list.Continue(
                Ok(#(dict.delete(params, parameter), [value, ..path_segments])),
              )
            Error(Nil) -> list.Stop(Error(MissingParameter(parameter)))
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
