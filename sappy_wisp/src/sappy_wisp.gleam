import gleam/json
import gleam/option
import sappy
import sappy/endpoint
import wisp

pub fn handle_request(
  endpoint: endpoint.EndPoint(input, output),
  request: wisp.Request,
  handle: fn(input, fn(output) -> wisp.Response) -> wisp.Response,
  otherwise: fn() -> wisp.Response,
) -> wisp.Response {
  case sappy.server_handle_request(endpoint, request) {
    Ok(#(input_decoder, output_decoder)) -> {
      use body <- wisp.require_string_body(request)
      // TODO: require json if needed
      let input = input_decoder(body)

      case input {
        Ok(input) -> {
          let return_response = fn(output) {
            case output_decoder {
              // TODO: non-json response
              option.Some(encode_output) ->
                wisp.json_response(encode_output(output), 200)
              option.None -> wisp.ok()
            }
          }
          handle(input, return_response)
        }
        Error(e) ->
          wisp.response(400)
          |> wisp.json_body(
            json.object([
              #("reason", json.string(endpoint.error_to_string(e))),
            ])
            |> json.to_string(),
          )
      }
    }
    _ -> otherwise()
  }
}
