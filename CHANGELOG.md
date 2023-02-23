# Change Log

## [0.0.3] 2023-02-23

## Fixed

- Fixed issue where there was 500 error when we are eagerloding relations with multiple optional matches and some privious match was haveing authorization and next one was skipping authorization for those same nodes. This would result in a collection of related nodes where some nodes were null and corresponding next optional match nodes on path had values.
