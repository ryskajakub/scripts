#!/usr/bin/env runhaskell

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
import Shelly
import qualified Data.Text as T
import Data.Monoid
default (T.Text)

main :: IO ()
main = do
  shelly $ do
    run "git" ["reset", "--soft", "HEAD^"]
    run "git" ["commit", "-a", "-C", "HEAD"]
  return ()
