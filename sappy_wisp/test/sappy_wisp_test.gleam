import gleam/httpc
import gleam/string
import gleeunit
import mist
import sappy
import sappy_wisp
import shared_test_api
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  run_server()
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn get_person_test() {
  assert send_request(shared_test_api.get_person(), "John")
    == shared_test_api.Person(name: "JOHN", age: 30, is_student: False)
}

fn handle_get_person(
  name: String,
  respond_with: fn(shared_test_api.Person) -> wisp.Response,
) -> wisp.Response {
  respond_with(shared_test_api.Person(
    name: string.uppercase(name),
    age: 30,
    is_student: False,
  ))
}

fn send_request(endpoint: sappy.EndPoint(a, b), input: a) -> b {
  let assert Ok(request) =
    sappy.client_create_request(endpoint, input, fn(req, _body) { req })

  let assert Ok(response) = httpc.send(request)
  let assert Ok(output) = sappy.client_handle_response(endpoint, response)

  output
}

fn run_server() {
  let secret_key_base = wisp.random_string(64)

  let assert Ok(_) =
    wisp_mist.handler(handle_request, secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start
  Nil
}

fn handle_request(request: wisp.Request) -> wisp.Response {
  use <- sappy_wisp.handle_request(
    shared_test_api.get_person(),
    request,
    handle_get_person,
  )

  panic as "unexpected request"
}
