CREATE OR ALTER VIEW [PL].UnbilledTime
AS

SELECT T.*
, M.mrow_id [MatterID]
, CASE WHEN T.billable=0 THEN 'TRUE' ELSE 'FALSE' END [Is Non Billable]
, CASE WHEN T.hours<>0 THEN DOL_VALUE/HOURS ELSE 0 END AS [BILLABLE RATE]
, CASE WHEN T.orig_hours<>0 THEN ORIG_VALUE/orig_hours ELSE 0 END [ACTUAL RATE]
, HOURS [BILLABLE HOURS]
, orig_hours [ACTUAL HOURS]
, dol_value [BILLABLE VALUE]
, orig_value [ACTUAL VALUE]
, CASE WHEN LEN(TRIM(T.ACT_CODE))>0 THEN CONCAT(RTRIM(A.DESCRIP), ' ', T.descrip) ELSE T.descrip END [FULL DESCRIPTION]
FROM time T
JOIN matter M
	ON T.clt_code=M.clt_code
	AND T.mat_code=M.mat_code
LEFT JOIN activity A 
	ON T.act_code=A.act_code
WHERE T.on_bill=0

GO

