#!/usr/bin/env stack
-- stack --resolver lts-3.13 --install-ghc runghc --package shelly
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}
{-# OPTIONS_GHC -fno-warn-type-defaults #-}
import Shelly
import qualified Data.Text as T
import Data.Monoid
default (T.Text)

isMaster :: T.Text -> Bool
isMaster line = T.isInfixOf (T.pack "master") line

isCurrent :: T.Text -> Bool
isCurrent line = T.isPrefixOf (T.pack "*") line

deleteBranch :: T.Text -> Sh ()
deleteBranch branch = run_ "git" ["branch", "-d", branch]

deleteMerged :: Sh ()
deleteMerged = do
  merged <- run "git" ["branch", "--merged"]
  sequence_ $ let
    nonMasterLines = filter (not . isMaster) (T.lines merged)
    nonMasterBranches = fmap (T.strip) nonMasterLines
    in fmap deleteBranch nonMasterBranches

main :: IO ()
main = shelly $ do
  whereIAm <- run "git" ["status"]
  if T.isSuffixOf "master" (head $ T.lines whereIAm :: T.Text)
  then deleteMerged
  else echo "You must be on the master branch!"
