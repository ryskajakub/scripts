
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
