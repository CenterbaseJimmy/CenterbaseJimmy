CREATE OR ALTER VIEW [PL].[CB_TrustTransactions]
AS 
SELECT 
	T.event_code AS [TransactionId]
	, T.[date] AS [Date]
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, CASE WHEN dol_value > 0 THEN dol_value ELSE NULL END AS [Credit]
	, CASE WHEN dol_value < 0 THEN dol_value*-1 ELSE NULL END AS [Debit]
	, T.descrip AS [Description]
	, CASE WHEN dol_value < 0 THEN 'Disburse Funds' ELSE 'Deposit' END AS [Type]
FROM dbo.trust T
INNER JOIN dbo.matter M
ON M.clt_code = T.clt_code
AND M.mat_code = T.mat_code
INNER JOIN dbo.client C
ON C.clt_code = T.clt_code

GO