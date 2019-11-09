open Bs_ppx_let.Option

let dates: Js.Date.t array = 
  let now () = Js.Date.make () in
  Array.make 30 () |> Array.mapi @@
    fun index () -> let n = now () in ignore @@ Js.Date.setDate n (float_of_int index) ; n

let printDay (int: int): string = match int with 
  | 1 -> "Monday"
  | 2 -> "Tuesday"
  | 3 -> "Wednesday"
  | 4 -> "Thursday"
  | 5 -> "Friday"
  | 6 -> "Saturday"
  | 0 -> "Sunday"
  | _ -> failwith "shouldn't happen"

let printMonth (int: int): string = match int with
  | 1 -> "January"
  | 2 -> "February"
  | 3 -> "March"
  | 4 -> "April"
  | 5 -> "May"
  | 6 -> "June"
  | 7 -> "July"
  | 8 -> "August"
  | 9 -> "September"
  | 10 -> "October"
  | 11 -> "November"
  | 12 -> "December"
  | _ -> failwith "shouldn't happen"

let format date = 
  let dayOfWeek = int_of_float @@ Js.Date.getDay date in
  let dayOfMonth = Js.Float.toString @@ Js.Date.getDate date in
  let month = int_of_float @@ 1.0 +. Js.Date.getMonth date in
  (printDay dayOfWeek) ^ ", " ^ (printMonth month) ^ " " ^ dayOfMonth

let printDate date =
  let padZeros string = if String.length string == 1 then "0" ^ string else string in
  let dayOfMonth = Js.Float.toString @@ Js.Date.getDate date in
  let month = Js.Float.toString @@ 1.0 +. Js.Date.getMonth date in
  let year = Js.Float.toString @@ Js.Date.getFullYear date in
  year ^ "-" ^ padZeros month ^ "-" ^ padZeros dayOfMonth

let readDate (date: string): (int * int * int) option =
  let regex = [%bs.re "/(\\d+)-(\\d+)-(\\d+)/"] in
  let%bind result = Js.Re.exec_ regex date in
  let captures = Array.map Js.Nullable.toOption @@ Js.Re.captures result in
  let%bind yearOpt = Array.get captures 1 in
  let%bind monthOpt = Array.get captures 2 in
  let%map dayOpt = Array.get captures 3 in
  let year = yearOpt |> Js.Float.fromString |> int_of_float in
  let month = monthOpt |> Js.Float.fromString |> int_of_float in
  let day = dayOpt |> Js.Float.fromString |> int_of_float in
  year, month, day

let ymdAsDate (year, month, date): Js.Date.t =
  Js.Date.makeWithYMD ~year:(float_of_int year) ~month:(float_of_int (month - 1)) ~date:(float_of_int date) ()

let fromString: string -> Js.Date.t = fun str -> str |> readDate |> Js.Option.getExn |> ymdAsDate

let plusDays (date: Js.Date.t) (days: int): Js.Date.t = 
  let freshDate = Js.Date.fromFloat @@ Js.Date.getTime date in
  let _ = Js.Date.setDate freshDate (Js.Date.getDate freshDate +. float_of_int days) in
  freshDate
