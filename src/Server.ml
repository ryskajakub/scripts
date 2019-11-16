open Bs_ppx_let.Promise

let doReservation jsDate mode = ParkingAvast.doReservation jsDate mode

let app = Express.App.make()

external toObject: Js.Json.t -> 'a Js.t = "%identity"
external toObjectUnsafe: 'a -> 'b Js.t = "%identity"

let reservationsFromNow days: Shared.dayReservation array = 
  let now = Js.Date.make () in
  let time = Js.Date.getTime now in
  let dayOfMonth = Js.Date.getDate now in
  Belt.Array.range 0 (days - 1) |> Array.map (fun i -> 
    let f = float_of_int i in
    let freshDate = Js.Date.fromFloat time in
    let _ = Js.Date.setDate freshDate (f +. dayOfMonth) in
    [%bs.obj { 
      _id = Days.printDate freshDate ;
      reserved = true ;
      performed = false ;
      location = Js.Undefined.empty ;
    }]
  )

let reservationsFromDb (): Shared.dayReservation array Js.Promise.t = Database.getReservations ()

let mergeWithFromDb (): Shared.dayReservation array Js.Promise.t =
  let%map fromDbArray = reservationsFromDb () in
  let recordsFromNow = reservationsFromNow 60 in
  let fromDb = Array.to_list fromDbArray in
  recordsFromNow |> Array.map @@ fun generatedRecord ->
    fromDb |. Belt.List.getBy (fun dbRecord -> dbRecord##_id = generatedRecord##_id) |>
      function
      | Some dbRecord -> Helpers.copy generatedRecord dbRecord
      | None -> generatedRecord
  
let shouldDoCronReservation (date: Js.Date.t): bool Js.Promise.t =
  let dateAsString = Days.printDate date in
  let%map reservationsArray = Database.getReservations () in
  let reservations = Array.to_list reservationsArray in
  Js.log2 "str: " dateAsString ;
  reservations |. Belt.List.getBy (fun dbRecord -> dbRecord##_id = dateAsString) |>
    function 
    | Some dbReservation -> dbReservation##reserved
    | None -> true


let handle mkNow _next req res: Express.complete Js.Promise.t =
  let requestPerformPossible dateString = 
    let dateAtStartOfDay = Days.fromString dateString in
    let now = mkNow () in
    let _ = Js.Date.setDate now (Js.Date.getDate now +. 2.0) in 
    Js.Date.getTime now >= Js.Date.getTime dateAtStartOfDay
  in
  match Express.Request.path req with 
    | "/reservations" -> 
      begin match Express.Request.httpMethod req with
        | Express.Request.Get ->
          let%bind reservations = mergeWithFromDb () in
          let%map response =
            reservations |> 
            Js.Json.stringifyAny |> 
            Js.Option.getExn |> 
            (fun string -> Express.Response.sendString string res) |>
            Js.Promise.resolve in
          response
        | Express.Request.Post ->
          let bodyJson = Express.Request.bodyJSON req in
          Js.log2 "request: " bodyJson ;
          let requestReservation: Shared.dayReservation = bodyJson |> Js.Option.getExn |> toObject in
          let%bind reservations = Database.getReservations () in

          let tryPerformRequest requestReservation =
            if requestPerformPossible requestReservation##_id
            then doReservation (requestReservation##_id |> Days.fromString) (ParkingAvast.modeFromBoolean requestReservation##reserved)
            else 
              let%map _ = Database.upsertReservation requestReservation in true
          in

          let%map _ = reservations |> Array.to_list |. Belt.List.getBy (fun dbRecord -> dbRecord##_id = requestReservation##_id) |>
            function 
            | Some dbReservation -> begin match dbReservation##performed , dbReservation##reserved == requestReservation##reserved with
              | true, true -> Js.Promise.resolve true
              | _ -> tryPerformRequest requestReservation
              end
            | None -> tryPerformRequest requestReservation
          in
          Express.Response.sendStatus Express.Response.StatusCode.Ok res
        | _ -> failwith "only post and get"
      end
    | "/cron" ->
      begin match Express.Request.httpMethod req with
        | Express.Request.Post ->
          let now = mkNow () in
          let after2Days = Days.plusDays now 2 in
          let%bind sdr = shouldDoCronReservation after2Days in
          let%map _reservationResult = 
            if sdr then
              doReservation after2Days MakeReservation
            else Js.Promise.resolve false
          in
          Express.Response.sendStatus Express.Response.StatusCode.Ok res
        | _other ->
          failwith "can't handle this"
      end
    | _ -> failwith "can't handle this"

let () =
  let mkNow () = Days.plusDays (Js.Date.make ()) 0 in
  let middleWare = Express.PromiseMiddleware.from @@ handle mkNow in
  let json = Express.Middleware.json () in
  Express.App.useOnPathWithMany app ~path:"/" [|json; middleWare |]

let port = 6101

let on_listen e =
  match e with
    | _ -> Js.log @@ "listening at localhost: " ^ string_of_int port

let _ = Express.App.listen app ~onListen:on_listen ~port ()
