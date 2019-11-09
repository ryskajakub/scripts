
open BsReactstrap;

[@react.component]
let make = () => {

  let (state, dispatch) = React.useReducer( 
    (_state, action) => {
      action
    },
    [||]
  );

  let onClick = (date: Shared.dayReservation, _clickData) => 
    Helpers.foreach((Client.makeReverseReservation(date)), dispatch) ;

  React.useEffect0(() => {
    Helpers.foreach (Client.reservations (), dispatch) ;
    None;
  });

  <Container>
    <Row>
      <Col lg="12">
        <h1>(ReasonReact.string("Make/cancel Reservation"))</h1>
      </Col>
    </Row>
    (
      state |> Array.map((d: Shared.dayReservation) => {
        let color = if (d##reserved) "info" else "success";
        <Row key={d##_id}>
          <Col className="offset-lg-3" lg="6">
            <p>
              <Button onClick={onClick(d)} block=true color={color} size="lg"> 
                (d##_id |> Days.readDate |> Js.Option.getExn |> Days.ymdAsDate |> Days.format |> Helpers.performedString(d##performed) |> ReasonReact.string) 
               </Button>
            </p>
          </Col>
        </Row>
      }) |> ReasonReact.array
    )
  </Container>;
};
