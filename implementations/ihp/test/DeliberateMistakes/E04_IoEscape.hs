module E04_IoEscape where

-- E04: Pure function attempting to escape IO
badEscape :: IO a -> a
badEscape x = x
