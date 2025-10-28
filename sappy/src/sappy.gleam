import gleam/dict
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/uri

pub type Parameters =
  dict.Dict(String, String)

pub type Error =
  Nil

@internal
pub type EndPoint(input, output) {
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

pub fn client_handle_response(
  endpoint: EndPoint(input, output),
  response: response.Response(String),
) -> Result(output, Error) {
  endpoint.decode_output(response.body)
}
