CREATE OR ALTER VIEW [PL].[CB_Rates]
AS 

SELECT F.[name] AS [RateTableName]
  , R.atty_code AS [UserName]
  , R.rate AS [Rate]
  , NULL [EffectiveDate]
FROM feerate R
INNER JOIN feeagree F
ON F.fee_code = R.fee_code
INNER JOIN atty A
ON A.atty_code = R.atty_code

GO

CREATE OR ALTER VIEW [PL].[CB_SetRates]
AS 

SELECT M.mrow_id AS [ImportId]
  , F.[name] AS [RateTableName]
FROM matter M
INNER JOIN feeagree F
ON F.fee_code = M.std_rate

GO	

CREATE OR ALTER VIEW [PL].[CB_SetRateExceptions]
AS 

SELECT M.mrow_id AS [ImportId]
  , R.atty_code AS [UserName]
  , R.rate AS [Rate]
  , NULL [EffectiveDate]
FROM matter M
INNER JOIN feerate R
ON R.fee_code = M.over_rate
INNER JOIN atty A
ON A.atty_code = R.atty_code

UNION ALL

SELECT M.mrow_id AS [ImportId]
  , R.atty_code AS [UserName]
  , R.rate AS [Rate]
  , NULL [EffectiveDate]
FROM matter M
INNER JOIN feerate R
ON R.fee_code = M.over_rate2
INNER JOIN atty A
ON A.atty_code = R.atty_code

GO