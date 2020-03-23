{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TypeApplications  #-}


module Main where

import           Protolude

import           Text.Printf (printf)


main :: IO ()
main = putStrLn @ [Char] . printf template $ (42 :: Int)
    where
    template =
        "Answer to the Ultimate Question of Life,\n\
        \    the Universe, and Everything: %d"
