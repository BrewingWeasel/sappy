# sappy_rsvp

[![Package Version](https://img.shields.io/hexpm/v/sappy_rsvp)](https://hex.pm/packages/sappy_rsvp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/sappy_rsvp/)

```sh
gleam add sappy_rsvp
```

Create requests API endpoints defined by [sappy](https://hexdocs.pm/sappy/) API endpoints in [lustre](https://hexdocs.pm/lustre/) using [rsvp](https://hexdocs.pm/rsvp/)


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

See also: 
    - [Sappy](https://hexdocs.pm/sappy/)
    - [Rsvp](https://hexdocs.pm/rsvp/)
    - [Lustre](https://hexdocs.pm/lustre/)
