import sappy
import gleam/result
import lustre/effect
import rsvp

pub type Error {
  RsvpError(rsvp.Error)
  SappyError(sappy.DecodeError)
}

pub fn send(
  endpoint: sappy.EndPoint(input, output),
  input: input,
  wrap: fn(Result(output, Error)) -> msg,
) -> effect.Effect(msg) {
  let response = {
    use request <- result.try(
      echo sappy.client_create_request(endpoint, input, fn(req, _body) { req }),
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
