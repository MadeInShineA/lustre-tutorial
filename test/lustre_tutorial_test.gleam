import gleeunit
import gleeunit/should
import lustre_tutorial.{
  ApiReturnedCats, Cat, Model, UserClickedAddCat, UserClickedRemoveCat, init,
  update,
}
import rsvp.{NetworkError}

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn init_returns_initial_model_test() {
  let #(model, _) = init(Nil)
  model.total |> should.equal(0)
  model.cats |> should.equal([])
}

pub fn update_add_cat_increments_total_test() {
  let model = Model(total: 0, cats: [])
  let #(new_model, _) = update(model, UserClickedAddCat)
  new_model.total |> should.equal(1)
}

pub fn update_add_cat_multiple_times_test() {
  let model = Model(total: 0, cats: [])
  let #(model1, _) = update(model, UserClickedAddCat)
  let #(model2, _) = update(model1, UserClickedAddCat)
  let #(model3, _) = update(model2, UserClickedAddCat)
  model3.total |> should.equal(3)
}

pub fn update_remove_cat_decrements_total_test() {
  let model = Model(total: 3, cats: [])
  let #(new_model, _) = update(model, UserClickedRemoveCat)
  new_model.total |> should.equal(2)
}

pub fn update_remove_cat_does_not_go_below_zero_test() {
  let model = Model(total: 0, cats: [])
  let #(new_model, _) = update(model, UserClickedRemoveCat)
  new_model.total |> should.equal(0)
}

pub fn update_remove_cat_at_one_goes_to_zero_test() {
  let model = Model(total: 1, cats: [])
  let #(new_model, _) = update(model, UserClickedRemoveCat)
  new_model.total |> should.equal(0)
}

pub fn update_api_returns_cats_appends_to_list_test() {
  let model = Model(total: 0, cats: [])
  let cats = [Cat(id: "1", url: "http://example.com/cat1.jpg")]
  let #(new_model, _) = update(model, ApiReturnedCats(Ok(cats)))
  new_model.cats |> should.equal(cats)
}

pub fn update_api_returns_cats_appends_to_existing_test() {
  let existing_cat = Cat(id: "1", url: "http://example.com/cat1.jpg")
  let model = Model(total: 0, cats: [existing_cat])
  let new_cat = Cat(id: "2", url: "http://example.com/cat2.jpg")
  let #(new_model, _) = update(model, ApiReturnedCats(Ok([new_cat])))
  new_model.cats |> should.equal([existing_cat, new_cat])
}

pub fn update_api_returns_error_does_not_change_model_test() {
  let model =
    Model(total: 5, cats: [Cat(id: "1", url: "http://example.com/cat1.jpg")])
  let #(new_model, _) = update(model, ApiReturnedCats(Error(NetworkError)))
  new_model.total |> should.equal(5)
  new_model.cats |> should.equal(model.cats)
}

pub fn update_remove_cat_removes_from_list_test() {
  let cats = [
    Cat(id: "1", url: "http://example.com/cat1.jpg"),
    Cat(id: "2", url: "http://example.com/cat2.jpg"),
    Cat(id: "3", url: "http://example.com/cat3.jpg"),
  ]
  let model = Model(total: 3, cats: cats)
  let #(new_model, _) = update(model, UserClickedRemoveCat)
  new_model.cats
  |> should.equal([
    Cat(id: "1", url: "http://example.com/cat1.jpg"),
    Cat(id: "2", url: "http://example.com/cat2.jpg"),
  ])
}
