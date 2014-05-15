#!/usr/bin/env runhaskell

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
import Shelly
import qualified Data.Text as T
import Data.Monoid
default (T.Text)

main :: IO ()
main = shelly $ do
	writefile "/home/coub/git/scripts/touch" "A"

