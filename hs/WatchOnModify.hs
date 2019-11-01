#!/usr/bin/env runhaskell

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
import Shelly
import qualified Data.Text as T
import Data.Monoid
default (T.Text)

changeKeyboardOnChange :: ShIO ()
changeKeyboardOnChange = do
  run_ "inotifywait" ["-e", "modify", "/home/coub/git/scripts/touch"]
  run_ "/home/coub/bin/xmodapply" []
  changeKeyboardOnChange

main :: IO ()
main = shelly changeKeyboardOnChange

