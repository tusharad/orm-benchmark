{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE OverloadedStrings #-}

module E03_MissingGroupBy where

import Squeal.PostgreSQL
import Schema

-- E03: Using countStar in an ungrouped selection alongside unaggregated column
badAgg :: Query_ DB () ()
badAgg = select_ (#f ! #departure_airport `as` #dep :* countStar `as` #cnt)
  (from (table ((#postgres_air ! #flight) `as` #f)))
