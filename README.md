# sappy

[![Package Version](https://img.shields.io/hexpm/v/sappy)](https://hex.pm/packages/sappy)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sappy/)

```sh
gleam add sappy
```

Define an API endpoint once:
```gleam
// src/shared/api.gleam
import sappy/endpoint
import sappy/endpoint/parameter

pub fn greet() -> endpoint.EndPoint(
  #(String, option.Option(Int)),
  dict.Dict(String, String),
) {
  base_endpoint("/api/greet/$name")
  |> endpoint.with_method(http.Get)
  |> endpoint.with_parameters2(
    parameter.required("name"),
    parameter.optional("excitement_level")
      |> parameter.map_optional(int.to_string, int.parse),
  )
  |> endpoint.returning_json(
    json.dict(_, function.identity, json.string),
    decode.dict(decode.string, decode.string),
  )
}
```

Then send requests to it from the client:
```gleam
const very_excited = option.Some(4)

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GetGreet -> {
      #(
        model, 
        sappy_rsvp.send(api.greet(), #("Bob", very_excited), ServerReturnedGreeting),
      )
    }
    ServerReturnedGreeting(Ok(greetings)) {
        assert dict.get(greetings, "en") == "Hello Bob!!!!"
        // ...
    }
    // ...
  }
}
```

And handle those requests on the server:
```gleam
fn handle_request(request: wisp.Request) -> wisp.Response {
  use <- sappy_wisp.handle_request(
    api.greet(),
    request,
    handle_greet,
  )
  // ...
}

fn handle_greet(
  input: #(String, option.Option(Int)),
  respond_with: fn(dict.Dict(String, String)) -> wisp.Response,
) -> wisp.Response {
  let #(name, excitement_level) = input
  let ending = string.repeat("!", option.unwrap(excitement_level, 1))
  respond_with(
    dict.from_list([
      #("en", "Hello " <> name <> ending),
      #("es", "Hola " <> name <> ending),
    ]),
  )
}
```

Further documentation can be found at <https://hexdocs.pm/sappy>.

See also: 
- The `example` directory
- [sappy_rsvp](https://hexdocs.pm/sappy_rsvp/): Create requests to an endpoint with Lustre and Rsvp
- [sappy_wisp](https://hexdocs.pm/sappy_wisp/): Handle requests at an endpoint with Wisp
