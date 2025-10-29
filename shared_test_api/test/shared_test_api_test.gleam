import birdie
import gleam/option.{Some}
import gleam/string
import gleeunit
import sappy
import shared_test_api

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn get_person_test() {
  let input = "Alice"

  let assert Ok(request) =
    sappy.client_create_request(
      shared_test_api.get_person(),
      input,
      fn(req, _body) { req },
    )

  request
  |> string.inspect()
  |> birdie.snap(title: "get_person request")

  let assert Ok(#(decode_request, Some(encode_response))) =
    sappy.server_handle_request(shared_test_api.get_person(), request)

  assert decode_request(request.body) == Ok(input)

  encode_response(shared_test_api.Person("ALICE", age: 30, is_student: False))
  |> string.inspect()
  |> birdie.snap(title: "get_person response")
}
