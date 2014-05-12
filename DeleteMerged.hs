#!/usr/bin/env runhaskell

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
	nonMasterLines <- return $ filter (\x -> not $ isMaster x) (T.lines merged)
	nonMasterBranches <- return $ fmap (\x -> T.strip x) nonMasterLines
	sequence_ $ fmap deleteBranch nonMasterBranches

main :: IO ()
main = shelly $ do
	whereIAm <- run "git" ["status"]
	if T.isSuffixOf "master" (head $ T.lines whereIAm :: T.Text)
	then deleteMerged
	else echo "You must be on the master branch!"
	
