CREATE OR ALTER VIEW [PL].UnbilledExpenses
AS

SELECT D.*
, M.mrow_id [MatterID]
, units [QUANTITY]
, orig_units [ACTUAL QUANTITY]
, dol_value [BILLABLE VALUE]
, orig_value [ACTUAL VALUE]
, descrip [DESCRIPTION]
FROM disburse D
JOIN matter M
	ON D.clt_code=M.clt_code
	AND D.mat_code=M.mat_code
WHERE D.on_bill=0

GO
