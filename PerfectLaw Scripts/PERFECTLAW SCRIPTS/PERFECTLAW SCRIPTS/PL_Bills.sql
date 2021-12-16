CREATE OR ALTER VIEW [PL].[CB_Bills]
AS 

SELECT 
	B.bill_code AS [BillId]
	, B.bill_num AS [BillNumber]
	, B.date AS [IssueDate]
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, ISNULL(Fees.billed,0) AS [FeesTotal]
	, ISNULL(Expenses.billed,0) AS [ExpenseTotal]
	, ISNULL(Fees.billed,0) + ISNULL(Expenses.billed,0) AS [InvoiceTotal]
	,  ISNULL(Fees.due,0) + ISNULL(Expenses.due,0) AS [InvoiceBalance]	
	, WUD.WUDfees * -1[Discount]
FROM dbo.bill B
INNER JOIN dbo.matter M
ON M.clt_code = B.clt_code
AND M.mat_code = B.mat_code
INNER JOIN dbo.client C
ON C.clt_code = B.clt_code
LEFT OUTER JOIN (
	SELECT bill_code, SUM(bill_amt) billed, SUM(due_amt) due
	FROM dbo.billdetl D
	WHERE [type] = 'F'
	GROUP BY bill_code
) Fees
ON Fees.bill_code = B.bill_code
LEFT OUTER JOIN (
	SELECT bill_code, SUM(bill_amt) billed, SUM(due_amt) due
	FROM dbo.billdetl D
	WHERE [type] = 'E'
	GROUP BY bill_code
) Expenses
ON Expenses.bill_code = B.bill_code
LEFT JOIN (
	SELECT ID_CODE, WUD, WUDfees, WUDexps
	FROM BillsNRecs 
) WUD
ON WUD.id_code=B.bill_code

GO
