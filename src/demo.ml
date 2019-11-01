open! BsPuppeteer

module Let_syntax = struct
  let map a ~f = Js.Promise.then_ (fun aa -> Js.Promise.resolve @@ f aa) a
  let bind a ~f = Js.Promise.then_ (fun aa -> f aa) a
end

let waitPromise(ms: int): int Js.Promise.t = 
  Js.Promise.make @@ fun ~resolve ~reject:_ ->
    ignore @@ Js.Global.setTimeout (fun () -> resolve ms [@bs]) ms

open Js.Date

let day (int: int): string = match int with 
  | 1 -> "Monday"
  | 2 -> "Tuesday"
  | 3 -> "Wednesday"
  | 4 -> "Thursday"
  | 5 -> "Friday"
  | 6 -> "Saturday"
  | 0 -> "Sunday"
  | _ -> failwith "shouldn't happen"

let dayToBook () = 
  let dayNow = getDay @@ fromFloat @@ now () in
  let dayAfter2Days = (int_of_float dayNow + 2) mod 7 in 
  day dayAfter2Days 

let name, password = 
  let args = Array.get Node.Process.process##argv in
  let name = args 2 in 
  let password = args 3 in
  name, password

let _ = 
  let%bind browser = Puppeteer.launch ~options:(Puppeteer.makeLaunchOptions ~headless:false ()) () in
  let%bind page = Browser.newPage browser in
  let%bind _ = FrameBase.goto page "https://parking.avast.com" () in
  let%bind signInClick = FrameBase.waitForXPath page "//a[contains(@class, 'signInButton')]" () in
  let%bind _ = ElementHandle.click signInClick () in
  let%bind usernameInput = FrameBase.waitForXPath page "//input[contains(@id, 'identifierId')]" () in
  let%bind _ = ElementHandle.type_ usernameInput name () in
  let%bind usernameNext = FrameBase.waitForXPath page "//div[contains(@id, 'identifierNext')]" () in
  let%bind _ = ElementHandle.click usernameNext () in
  let%bind passwordIdnput = FrameBase.waitForXPath page "//input[contains(@name, 'password')]" () in
  let%bind _ = waitPromise 10000 in
  let%bind _ = ElementHandle.type_ passwordIdnput password () in
  let%bind passwordNext = FrameBase.waitForXPath page "//div[contains(@id, 'passwordNext')]" () in
  let%bind _ = ElementHandle.click passwordNext () in
  let dtb = dayToBook () in
  let buttonXPath = "//button[contains(@class, 'btn-success') and contains(., '" ^ dtb ^ "')]" in
  (* let%bind reserveButton = FrameBase.waitForXPath page ~xpath:buttonXPath () in *)
  (* ElementHandle.click reserveButton () *)
  Js.Promise.resolve ()
