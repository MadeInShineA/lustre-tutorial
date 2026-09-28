import gleam/int
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

import gleam/dynamic/decode
import gleam/list
import lustre/effect.{type Effect}
import rsvp

pub type Model {
  Model(total: Int, cats: List(Cat))
}

pub type Cat {
  Cat(id: String, url: String)
}

pub fn init(_args) -> #(Model, Effect(Message)) {
  let model = Model(total: 0, cats: [])

  #(model, effect.none())
}

pub type Message {
  UserClickedAddCat
  UserClickedRemoveCat
  ApiReturnedCats(Result(List(Cat), rsvp.Error(String)))
}

pub fn update(model: Model, message: Message) -> #(Model, Effect(Message)) {
  case message {
    UserClickedAddCat -> #(Model(..model, total: model.total + 1), get_cat())

    UserClickedRemoveCat -> #(
      Model(
        total: int.max(0, model.total - 1),
        cats: list.take(model.cats, list.length(model.cats) - 1),
      ),
      effect.none(),
    )

    ApiReturnedCats(Ok(cats)) -> #(
      Model(..model, cats: list.append(model.cats, cats)),
      effect.none(),
    )

    ApiReturnedCats(Error(_)) -> #(model, effect.none())
  }
}

fn get_cat() -> Effect(Message) {
  let decoder = {
    use id <- decode.field("id", decode.string)
    use url <- decode.field("url", decode.string)

    decode.success(Cat(id:, url:))
  }

  let url = "https://api.thecatapi.com/v1/images/search"
  let handler = rsvp.expect_json(decode.list(decoder), ApiReturnedCats)

  rsvp.get(url, handler)
}

pub fn view(model: Model) -> Element(Message) {
  html.div([], [
    html.div([], [
      html.button([event.on_click(UserClickedAddCat)], [html.text("Add cat")]),
      html.p([], [html.text(int.to_string(model.total))]),
      html.button([event.on_click(UserClickedRemoveCat)], [
        html.text("Remove cat"),
      ]),
    ]),
    html.div([], {
      list.map(model.cats, fn(cat) {
        html.img([
          attribute.src(cat.url),
          attribute.width(400),
          attribute.height(400),
        ])
      })
    }),
  ])
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
