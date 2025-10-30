import birdie
import gleam/dict
import gleam/option.{Some}
import gleam/string
import gleeunit
import sappy
import shared_test_api

pub fn main() -> Nil {
  gleeunit.main()
}

fn test_request(endpoint, input, title) {
  let assert Ok(request) =
    sappy.client_create_request(endpoint, input, fn(req, _body) { req })

  request
  |> string.inspect()
  |> birdie.snap(title:)

  let assert Ok(#(decode_request, Some(encode_response))) =
    sappy.server_handle_request(endpoint, request)

  assert decode_request(request.body) == Ok(input)

  encode_response
}

pub fn basic_request_test() {
  let encode_response =
    test_request(shared_test_api.get_person(), "Alice", "get_person request")

  encode_response(shared_test_api.Person("ALICE", age: 30, is_student: False))
  |> string.inspect()
  |> birdie.snap(title: "get_person response")
}

pub fn optional_parameter_test() {
  let _encode_response =
    test_request(shared_test_api.greet(), #("Alice", option.Some(2)), "greet request option.Some(2)")

  let encode_response =
    test_request(shared_test_api.greet(), #("Alice", option.None), "greet request option.None")

  encode_response(dict.from_list([#("greeting", "Hello, Alice!")]))
  |> string.inspect()
  |> birdie.snap(title: "greet request response")
}
