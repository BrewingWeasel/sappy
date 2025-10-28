import birdie
import gleam/string
import gleeunit
import sappy
import shared_test_api

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn get_person_test() {
  sappy.client_create_request(
    shared_test_api.get_person(),
    "Alice",
    fn(req, _body) { req },
  )
  |> string.inspect()
  |> birdie.snap(title: "get_person request")
}
