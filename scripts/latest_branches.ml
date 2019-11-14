#!/usr/bin/env ocaml

#use "topfind"
#thread
#require "shexp.process"
#require "curses"
#require "base"

module PList = List
open Shexp_process
open Infix
open Curses
open Unix

let () = 

  let window = initscr () in

  let charNow = ref 0 in
  let charPrev = ref 0 in
  let charPrevPrev = ref 0 in

  let go_start_line () =
    let y, _ = getyx window in
    ignore @@ move y 0
  in

  ignore @@ noecho () ;

  let latest_branches = eval ( run "git" ["branch" ; "--sort=-committerdate"] |- read_all ) in

  let list: (string list) = Base.String.split_lines latest_branches in
  let current_condition = fun e -> String.get e 0 = '*' in
  let lines = PList.filter ( fun e -> not @@ current_condition e ) list in
  let current = PList.filter current_condition list |> PList.hd in

  let up_down_move ?(start_line: unit option) =
    let y, x = getyx window in
    let new_x = match start_line with | Some () -> 0 | None -> x in
    function
    | `Up -> 
      if (y >= 1)
        then ignore @@ move (y-1) new_x
        else ()
    | `Down -> 
      if (PList.length list - 1 > y)
        then ignore @@ move (y+1) new_x
        else ()
  in

  ignore @@ addstr current ; ignore @@ up_down_move ~start_line:() `Down ;
  PList.iter (fun line -> ignore @@ addstr line ; ignore @@ up_down_move ~start_line:() `Down ) lines ;
  ignore @@ move 0 0 ;

  ignore @@ addstr "*" ;
  go_start_line () ;

  let move_asterisk direction = 
    ignore @@ addstr " " ;
    go_start_line () ;
    up_down_move direction ;
    ignore @@ addstr "*" ;
    go_start_line () 
  in

  while 
    charPrevPrev := !charPrev ;
    charPrev := !charNow ;
    charNow := getch () ;
    !charNow <> 10
  do 

    match !charPrevPrev, !charPrev, !charNow with
      | 27, 91, 65 -> 
        move_asterisk `Up
      | 27, 91, 66 -> 
        move_asterisk `Down
      | _ -> () 

  done ;

  let cursor_y, _ = getyx window in

  if cursor_y == 0
    then ()
    else begin  
      let selected_branch = PList.nth lines (cursor_y - 1) |> String.trim in
      eval (run "git" [ "checkout" ; selected_branch ]) ;
    end 
  ;

  endwin ()
