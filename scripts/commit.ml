#!/usr/bin/env ocaml

#use "topfind"
#thread
#require "shexp.process"
#require "base"

module PList = List
open Shexp_process
open Infix
open Unix

let () = 

  let branch_name = eval ( run "git" ["rev-parse"; "--abbrev-ref"; "HEAD"] |- read_all ) in

  eval ( run "git" [ "commit"; "-m"; branch_name ] )

