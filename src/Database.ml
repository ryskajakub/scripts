
open Bs_ppx_let.Promise

module PromiseHandler: MongoDB.CallbackHandler with type 'a t = 'a Js.Promise.t = struct
  type 'a t = 'a Js.Promise.t
  let callbackConverter (callback: 'a MongoDB.callback) = Js.Promise.make @@ fun ~resolve ~reject:_ ->
    callback (fun error value -> resolve value [@bs])
end

module PromiseMongo = MongoDB.Make(PromiseHandler)
open PromiseMongo

let getReservations (): Shared.dayReservation array Js.Promise.t =
  let%bind connection = connect "mongodb://localhost:27017/garage" in
  let reservationsCollection = Db.collection "reservations" connection in
  let query = Js.Obj.empty () in
  let%map result = Collection.find query reservationsCollection |> Cursor.toArray in
  let typed: Shared.dayReservation array = result in
  typed

let upsertReservation (doc: Shared.dayReservation): unit Js.Promise.t = 
  let%bind connection = connect "mongodb://localhost:27017/garage" in
  let reservationsCollection = Db.collection "reservations" connection in
  let deleteDoc = DatabaseArgs.mkQuery (doc##_id) in
  Js.log2 "Deleting... " deleteDoc ;
  let%bind _deleteOne = Collection.deleteOne deleteDoc reservationsCollection in
  Js.log2 "Inserting... " doc ;
  let%map _insertOne = Collection.insertOne doc reservationsCollection in
  ()
