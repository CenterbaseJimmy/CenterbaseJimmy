CREATE OR ALTER VIEW [PL].BilledExpenses
AS

SELECT D.*
, M.mrow_id [MatterID]
, CASE WHEN UNITS = 0 THEN 1 ELSE units END [BILLABLE QUANTITY]
, CASE WHEN UNITS = 0 THEN dol_value ELSE dol_value / UNITS END [BILLABLE RATE]
, CASE WHEN orig_units = 0 THEN 1 ELSE orig_units END [ACTUAL QUANTITY]
, CASE WHEN orig_units = 0 THEN orig_value ELSE orig_value / orig_units END [ACTUAL RATE]
, dol_value [BILLABLE VALUE]
, orig_value [ACTUAL VALUE]
, descrip [DESCRIPTION]
FROM archived D
JOIN matter M
	ON D.clt_code=M.clt_code
	AND D.mat_code=M.mat_code
WHERE D.bill_code IS NOT NULL

GO