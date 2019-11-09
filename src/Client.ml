open Fetch
open Bs_ppx_let.Promise

external parseIntoMyData : string -> Shared.dayReservation array = "parse" [@@bs.scope "JSON"][@@bs.val]

let reservations (): Shared.dayReservation array Js.Promise.t = 
  let%bind response = fetch "/api/reservations" in
  let%map body = Response.text response in
  let reservations = parseIntoMyData body in
  reservations

let makeReverseReservation: (Shared.dayReservation -> Shared.dayReservation array Js.Promise.t) = fun reservation ->
  let reversedReservation = Helpers.copy reservation [%bs.obj { reserved = not reservation##reserved }] in
  let bodyString = Js.Json.stringifyAny reversedReservation |> Js.Option.getExn |> BodyInit.make in
  let headers = HeadersInit.makeWithArray [| "Content-Type", "application/json" |] in 
  let requestInit = RequestInit.make ~body:bodyString ~method_:Post ~headers () in
  let request = Request.makeWithInit "/api/reservations" requestInit in
  let%bind _response = fetchWithRequest request in
  reservations ()
