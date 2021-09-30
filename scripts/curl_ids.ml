#!/usr/bin/env ocaml

#use "topfind"
#thread
#require "shexp.process"
#require "base"

module PList = List
open Shexp_process
open Infix
open Unix

let read_lines () : string list =
  let try_read () =
    try Some (read_line ()) with End_of_file -> None in
  let rec loop acc = match try_read () with
    | Some s -> loop (s :: acc)
    | None -> PList.rev acc in
  loop []


let () = 
        let lines = read_lines () in
        let try_image id t = 
                let url = "https://knihobot-images.s3.eu-central-1.amazonaws.com/upload/images/" ^ t ^ "/" ^ (String.trim id) ^ ".jpg" in 
                eval ( run "echo" [ url] ) ;
                eval ( run "curl" [ "--silent" ; "--fail" ; "--output" ; "/dev/null" ; url] )
        in
        PList.iter (fun i -> try_image i "large" ; try_image i "thumb") lines

