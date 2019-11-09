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

external asString: < .. > Js.t -> string = "%identity"

let doReservation date (mode: mode) name password: bool Js.Promise.t = 

  let makeReservationButtonClass, cancelReservationButtonClass = "btn-success", "btn-info" in

  let reserved, firstButtonClass, secondButtonClass = mode |>
    function
    | MakeReservation -> true, makeReservationButtonClass, cancelReservationButtonClass
    | CancelReservation -> false, cancelReservationButtonClass, makeReservationButtonClass 
  in

  let mkDoc (reservation: string option) = [%bs.obj {
    _id = Days.printDate date ;
    reserved = reserved ;
    performed = true ;
    location = reservation |> (function Some s -> Some (Helpers.extractLocation s) | None -> None) |> Js.Undefined.fromOption
  }] in

  let maybeReservation (): (string option * bool) Js.Promise.t = 
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
    match mode with
      | MakeReservation ->
        let reservedButtonXPathText = "//button[contains(@class, 'btn-info')]/strong[contains(@class, 'inButtonText')]" in
        let%bind reserveButton = FrameBase.waitForXPath page ~xpath:reservedButtonXPathText () in
        let%bind textContent = ElementHandle.getProperty reserveButton ~propertyName:"textContent" in
        let%map jsonValue = ElementHandle.jsonValue textContent in
        let reservation = asString jsonValue in
        Some reservation, true 
      | CancelReservation ->
        let reservedButtonXPath = "//button[contains(@class, '" ^ secondButtonClass ^ "') and contains(., '" ^ dtb ^ "')]" in
        let%map _ = FrameBase.waitForXPath page ~xpath:reservedButtonXPath () in
        None, true
  in 

  let promise = 
    let%bind (reservation, result) = maybeReservation () in
    let doc = mkDoc reservation in
    let%map _ = Database.upsertReservation doc in
    Js.log2 "Performing..." doc ;
    result
  in
  
  promise |> Js.Promise.catch (fun e -> Js.log e ; Js.Promise.resolve false)
