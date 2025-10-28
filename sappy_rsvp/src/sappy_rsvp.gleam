import gleam/result
import lustre/effect
import rsvp
import sappy
import sappy/endpoint

pub type Error {
  RsvpError(rsvp.Error)
  SappyError(endpoint.Error)
}

pub fn send(
  endpoint: endpoint.EndPoint(input, output),
  input: input,
  wrap: fn(Result(output, Error)) -> msg,
) -> effect.Effect(msg) {
  let response = {
    use request <- result.try(
      sappy.client_create_request(endpoint, input, fn(req, _body) { req }),
    )
    Ok(rsvp.send(
      request,
      rsvp.expect_ok_response(fn(req) {
        req
        |> result.map_error(RsvpError)
        |> result.try(fn(req) {
          sappy.client_handle_response(endpoint, req)
          |> result.map_error(SappyError)
        })
        |> wrap
      }),
    ))
  }
  case response {
    Ok(a) -> a
    Error(e) ->
      effect.from(fn(dispatch) { dispatch(wrap(Error(SappyError(e)))) })
  }
}
