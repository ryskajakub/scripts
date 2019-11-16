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

let name, password = 
  let default = Config.config##default in
  default##name, default##password

let doReservation date (mode: mode): bool Js.Promise.t = 

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
    let%bind browser = Puppeteer.launch ~options:(Puppeteer.makeLaunchOptions ~headless:true ()) () in
    let%bind page = Browser.newPage browser in
    let%bind _ = Page.setUserAgent page "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3205.0 Safari/537.36" in
    let%bind _ = FrameBase.goto page "https://parking.avast.com" () in
    let%bind signInClick = FrameBase.waitForXPath page "//a[contains(@class, 'signInButton')]" () in
    let%bind _ = ElementHandle.click signInClick () in
    let%bind usernameInput = FrameBase.waitForXPath page "//input[contains(@id, 'identifierId')]" () in
    let%bind _ = ElementHandle.type_ usernameInput name () in
    let%bind usernameNext = FrameBase.waitForXPath page "//div[contains(@id, 'identifierNext')]" () in
    let%bind _ = ElementHandle.click usernameNext () in
    let%bind passwordInput = FrameBase.waitForXPath page "//input[contains(@name, 'password')]" () in
    let%bind _ = waitPromise 10000 in
    let%bind _ = ElementHandle.type_ passwordInput password () in
    let%bind _ = waitPromise 10000 in
    let%bind passwordNext = FrameBase.waitForXPath page ~xpath:"//div[contains(@id, 'passwordNext')]" () in
    let%bind _ = waitPromise 10000 in
    let%bind _ = ElementHandle.click passwordNext () in
    let dtb = dayOfWeek in
    let buttonXPath = "//button[contains(@class, '" ^ firstButtonClass ^ "') and contains(., '" ^ dtb ^ "')]" in
    let%bind _ = Page.screenshot page ~options:(Screenshot.makeOptions ~path:"./screenshot.png" ()) () in
    let%bind reserveButton = FrameBase.waitForXPath page ~xpath:buttonXPath () in
    let%bind _ = ElementHandle.click reserveButton () in
    let%bind result = match mode with
      | MakeReservation ->
        let reservedButtonXPathText = "//button[contains(@class, '" ^ secondButtonClass ^ "')]/strong[contains(@class, 'inButtonText')]" in
        let%bind reservedButton = FrameBase.waitForXPath page ~xpath:reservedButtonXPathText () in
        let%bind textContent = ElementHandle.getProperty reservedButton ~propertyName:"textContent" in
        let%map jsonValue = ElementHandle.jsonValue textContent in
        let reservation = asString jsonValue in
        Some reservation, true 
      | CancelReservation ->
        let reservedButtonXPath = "//button[contains(@class, '" ^ secondButtonClass ^ "') and contains(., '" ^ dtb ^ "')]" in
        let%map _ = FrameBase.waitForXPath page ~xpath:reservedButtonXPath () in
        None, true
    in
    let%map _ = Browser.close browser in
    result
  in 

  let promise = 
    let%bind (reservation, result) = maybeReservation () in
    let doc = mkDoc reservation in
    let%map _ = Database.upsertReservation doc in
    Js.log2 "Performing..." doc ;
    result
  in
  
  promise |> Js.Promise.catch (fun e -> Js.log e ; Js.Promise.resolve false)

let () = ignore @@ doReservation (Js.Date.make ()) MakeReservation
