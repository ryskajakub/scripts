open BsPuppeteer
open Bs_ppx_let.Promise
open Js.Date

let waitPromise(ms: int): int Js.Promise.t = 
  Js.Promise.make @@ fun ~resolve ~reject:_ ->
    ignore @@ Js.Global.setTimeout (fun () -> resolve ms [@bs]) ms

let dayToBook (date: Js.Date.t): string = 
  let dayNow = getDay date in
  let dayOfWeek = int_of_float dayNow mod 7 in 
  Days.printDay dayOfWeek 

type mode = 
  | CancelReservation
  | MakeReservation

let modeFromBoolean = function
  | true -> MakeReservation
  | false -> CancelReservation

let doReservation date (mode: mode) name password: bool Js.Promise.t = 

  let makeReservationButtonClass, cancelReservationButtonClass = "btn-success", "btn-info" in

  let reserved, firstButtonClass, secondButtonClass = mode |>
    function
    | MakeReservation -> true, makeReservationButtonClass, cancelReservationButtonClass
    | CancelReservation -> false, cancelReservationButtonClass, makeReservationButtonClass 
  in

  let doc = [%bs.obj {
    _id = Days.printDate date ;
    reserved = reserved ;
    performed = true ;
  }] in

  let maybeReservation (): bool Js.Promise.t = 
    let dayOfWeek = dayToBook date in
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
    let dtb = dayOfWeek in
    let buttonXPath = "//button[contains(@class, '" ^ firstButtonClass ^ "') and contains(., '" ^ dtb ^ "')]" in
    let%bind reserveButton = FrameBase.waitForXPath page ~xpath:buttonXPath () in
    let%bind _ = ElementHandle.click reserveButton () in
    let reservedButtonXPath = "//button[contains(@class, '" ^ secondButtonClass ^ "') and contains(., '" ^ dtb ^ "')]" in
    let%map _ = FrameBase.waitForXPath page ~xpath:reservedButtonXPath () in
    Js.log2 "reservation successful for date: " date;
    true 
  in 

  let promise = 
    (* let%bind result = maybeReservation () in *)
    let result = true in
    Js.log2 "Performing..." doc ;
    let%map _ = Database.upsertReservation doc in
    result
  in
  
  promise |> Js.Promise.catch (fun e -> Js.log e ; Js.Promise.resolve false)
