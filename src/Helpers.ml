
open Bs_ppx_let.Promise

let copy (obj: < .. > Js.t) (mods: < .. > Js.t): < .. > Js.t =
  let freshObject = Js.Obj.empty () in
  let _ = Js.Obj.assign freshObject obj in
  let _ = Js.Obj.assign freshObject mods in
  freshObject

let foreach (p: 'a Js.Promise.t) (f: 'a -> unit) : unit =
  ignore @@ let%map value = p in
  f value

let performedString performed str =
  if performed
  then "Performed >> " ^ str ^ " << Performed"
  else str

let extractLocation str: string = Js.String.split " " str |. Array.get 1

let mkLocation: string Js.Undefined.t -> string = fun s -> Js.undefinedToOption s |> Js.Option.map (fun [@bs] a -> "Location: " ^ a) |> Js.Option.getWithDefault ""
