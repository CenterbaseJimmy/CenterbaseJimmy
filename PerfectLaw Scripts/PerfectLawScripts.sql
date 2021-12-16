-- Make sure the new schema exists
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA S WHERE S.SCHEMA_NAME = 'PL'))
	EXEC sp_executesql N'CREATE SCHEMA [PL]';

GO

-- Builds an appropriately formatted name using the specified name parts (first, middle, last)
CREATE OR ALTER FUNCTION [dbo].[fn_AddStrings]
	(@string1 nvarchar(255)
	,@string2 nvarchar(255)
    , @separator nvarchar(10) = ' '
	)
RETURNS nvarchar(255)
AS
BEGIN 
	IF (LEN(@string1) > 0)
	BEGIN
		IF (LEN(@string2) > 0)
            RETURN @string1 + @separator + @string2
		ELSE
			RETURN @string1
	END
    ELSE IF (LEN(@string2) > 0)
    BEGIN
        RETURN @string2
    END

    RETURN ''
END
GO

CREATE OR ALTER FUNCTION [dbo].[fn_AddMultipleStrings]
	(@string1 nvarchar(255)
	,@string2 nvarchar(255)
    , @separator nvarchar(10) = ' '
    , @string3 nvarchar(255) = NULL
    , @string4 nvarchar(255) = NULL
    , @string5 nvarchar(255) = NULL
    , @string6 nvarchar(255) = NULL
    , @string7 nvarchar(255) = NULL
    , @string8 nvarchar(255) = NULL
    , @string9 nvarchar(255) = NULL)
RETURNS nvarchar(MAX)
AS
BEGIN

DECLARE @result nvarchar(MAX)

SET @result = dbo.fn_AddStrings( @string1, @string2, @separator);
SET @result = dbo.fn_AddStrings( @result, @string3, @separator);
SET @result = dbo.fn_AddStrings( @result, @string4, @separator);
SET @result = dbo.fn_AddStrings( @result, @string5, @separator);
SET @result = dbo.fn_AddStrings( @result, @string6, @separator);
SET @result = dbo.fn_AddStrings( @result, @string7, @separator);
SET @result = dbo.fn_AddStrings( @result, @string8, @separator);
SET @result = dbo.fn_AddStrings( @result, @string9, @separator);

RETURN @result  

END
GO

-- Builds an appropriately formatted name using the specified name parts (first, middle, last)
CREATE OR ALTER FUNCTION [dbo].[fn_BuildName]
	(@title nvarchar(255)
    ,@firstName nvarchar(255)
	,@middleName nvarchar(255)
	,@lastName nvarchar(255)
    ,@suffix nvarchar(255))
RETURNS nvarchar(255)
AS
BEGIN 
    DECLARE @ret nvarchar(255)

    SET @title = TRIM(@title)
    SET @firstName = TRIM(@firstName)
    SET @middleName = TRIM(@middleName)
    SET @lastName = TRIM(@lastName)
    SET @suffix = TRIM(@suffix)

    RETURN DBO.fn_AddMultipleStrings(
        @title, @firstName, ' '
        , @middleName
        , @lastName
        , @suffix, DEFAULT, DEFAULT, DEFAULT, DEFAULT);
END
GO


CREATE OR ALTER VIEW [PL].[CB_Matters]
AS 

SELECT
	M.mrow_id [MatterID]
	, C.crow_id [ClientID]
	, CONCAT(RTRIM(C.[name]),' - ', RTRIM(M.[name]),' - ',RTRIM(M.clt_code),'-',FORMAT(TRY_CONVERT(INT,mat_code),'D3')) AS [Matter Name]
	, RTRIM(M.[name]) AS [Short Description]
	, A.address1 AS [Address 1]
	, A.address2 AS [Address 2]
	, A.address3 AS [Address 3]
	, A.city
	, A.[state]
	, A.zip
	, [start_date] AS [Date Opened]
	, [closed] AS [Date Closed]
	, bill_atty AS [Responsible Attorney]
	, init_atty AS [Originating Attorney]
	, std_rate AS [Rate Table]
	, over_rate AS [Rate Exceptions]
	, over_rate2 AS [Rate Exceptions 2]
	, CONCAT(RTRIM(M.clt_code),'-',FORMAT(TRY_CONVERT(int,mat_code),'D3')) [Matter Number]
	, FORMAT(TRY_CONVERT(int,mat_code),'D3') AS [Matter Sequence Number]
	, RTRIM(M.clt_code) AS [Client Number]
	, RTRIM(C.[name]) AS [Client Name]
	--, email_bill AS [Email Bills?]
	, CASE 
		WHEN M.class = 'FF' THEN 'Flat Fee' 
		ELSE 'Hourly'
		END AS [Fee Arrangement]
	, M.Notes AS [Notes]
	, CL.name [Practice Area]
	, O.descrip [Office]
	, CASE WHEN email_bill=1 THEN 'TRUE' ELSE 'FALSE' END [CLIENT ACCEPTS BILL VIA EMAIL]
	, init_fc [Fee Credits]
	, M.MATMINTRST [Matter Minimum Trust]
	, a.email
	, M.billable
	, M.clt_code
	, M.mat_code
FROM dbo.matter M
INNER JOIN client C
	ON C.clt_code = M.clt_code
LEFT OUTER JOIN [address] A
	ON A.addr_code = M.addr_code
LEFT JOIN class CL
	ON M.class=CL.cls_code
LEFT JOIN office O
	ON M.off_code=O.off_code

GO

CREATE OR ALTER VIEW [PL].[CB_Contacts]
AS 
SELECT 
	C.crow_id AS [ClientId]
	, RTRIM([name]) AS [Client Name]
	, RTRIM(C.clt_code) AS [Client Number]
	, A.phone 
	, A.[EMAIL]
	, A.address1 AS [Address 1]
	, A.address2 AS [Address 2]
	, A.address3 AS [Address 3]
	, A.city
	, A.[state]
	, A.zip
	, C.notes
 	, CASE WHEN C.inactive = 1 THEN 'Inactive' ELSE 'Active' END AS [Active Status]
FROM dbo.client C
LEFT OUTER JOIN [address] A
ON A.clt_code = C.clt_code
AND LEN(TRIM(A.addr_code)) < 7

GO

CREATE OR ALTER VIEW [PL].[CB_RelatedParties]
AS 
SELECT 
	event_code AS [PartyId]
	, RTRIM(party_code) AS [Party Name]
	, specialty AS [Specialty]
	, homeph AS [Home Phone]
	, mobileph AS [Mobile Phone]
	, workph AS [Work Phone]
	, faxph AS [Fax]
	, email_addr AS [Email]
	, street_add AS [Address 1]
	, street_ad1 AS [Address 2]
	, street_ad3 AS [Address 3]
	, city
	, [state]
	, zip
	, notes
	, beeperph
	, employer
	, mail_list
	, gender
	, dbo.fn_BuildName(mrmrs, first, middle, name, NULL) [Full Name]
FROM dbo.party P
WHERE LEN(TRIM(P.event_code)) = 7

GO

CREATE OR ALTER VIEW [PL].[CB_RelatedParties_Matter]
AS 
SELECT 
	event_code AS [PartyId]
	, RTRIM(party_code) AS [Party Name]
	, M.clt_code AS [Client Number]
	, M.mat_code AS [Matter Sequence Number]
	, M.mrow_id AS [MatterId]
	, CONCAT(RTRIM(C.[name]),' - ', RTRIM(M.[name]),' - ',RTRIM(M.clt_code),'-',FORMAT(TRY_CONVERT(INT,M.mat_code),'D3')) AS [Matter Name]
FROM dbo.party P
INNER JOIN relparty R
ON R.related = P.event_code
INNER JOIN matter M
ON M.clt_code = R.clt_code
AND M.mat_code = R.mat_code
INNER JOIN client C
ON C.clt_code = M.clt_code
WHERE LEN(TRIM(P.event_code)) = 7

GO

CREATE OR ALTER VIEW [PL].ExpenseCodes AS

SELECT *
, CASE WHEN exp_type=1 THEN 'Hard Cost' WHEN exp_type=2 THEN 'Soft Cost' ELSE NULL END [EXPENSE TYPE]
, CASE WHEN exp_code LIKE '%E[0-9][0-9][0-9]%' THEN exp_code END [LEDES CODE]
FROM expense

GO
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
--WHERE T.on_bill=0

GO

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

CREATE OR ALTER VIEW [PL].BilledTime
AS

SELECT T.*
, M.mrow_id [MatterID]
, CASE WHEN T.billable=0 THEN 'TRUE' ELSE 'FALSE' END [Is Non Billable]
, CASE WHEN T.hours<>0 THEN DOL_VALUE/HOURS ELSE 0 END AS [BILLABLE RATE2]
, CASE WHEN T.hours=0 AND T.BILLABLE=1 THEN DOL_VALUE WHEN HOURS<>0 THEN DOL_VALUE/HOURS ELSE 0 END AS [BILLABLE RATE]
, CASE WHEN T.orig_hours<>0 THEN ORIG_VALUE/orig_hours ELSE 0 END [ACTUAL RATE]
, CASE WHEN HOURS=0 AND T.billable=1 THEN 1 ELSE hours END [BILLABLE HOURS]
, orig_hours [ACTUAL HOURS]
, dol_value [BILLABLE VALUE]
, orig_value [ACTUAL VALUE]
, CASE WHEN LEN(TRIM(T.ACT_CODE))>0 THEN CONCAT(RTRIM(A.DESCRIP), ' ', T.descrip) ELSE T.descrip END [FULL DESCRIPTION]
FROM archivet T
JOIN matter M
	ON T.clt_code=M.clt_code
	AND T.mat_code=M.mat_code
LEFT JOIN activity A 
	ON T.act_code=A.act_code
WHERE T.bill_code IS NOT NULL

GO

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

CREATE OR ALTER VIEW [PL].[CB_Vendors]
AS 
SELECT 
	V.vnd_code AS [VendorId]
	, [name] AS [Name]
	, address1
	, address2
	, address3
	, address4
	, tax_id AS [EIN]
	, form_1099
	, V.TERMS
	, V.PMT_DUEDAY
FROM dbo.vendor V
INNER JOIN vendaddr A
ON A.vnd_code = V.vnd_code
INNER JOIN vendloc L
ON L.vnd_code = V.vnd_code

GO

CREATE OR ALTER VIEW [PL].[CB_VendorBills]
AS 
SELECT 
	I.inv_code AS [Vendor Bill Id]
	, I.vnd_code AS [Vendor Id]
	, I.inv_total AS [Balance]
	, I.inv_date AS [Date]
	, I.inv_num AS [Bill Number]
	, D.descrip AS [Description]
	, I.acct_code AS [Account Id]
	, I.oper_code AS [Operating Code]
	, 'Posted' AS [Status]
FROM dbo.inv I
INNER JOIN dbo.invdetl D
ON D.inv_code = I.inv_code

UNION ALL

SELECT 
	I.inv_code AS [Vendor Bill Id]
	, I.vnd_code AS [Vendor Id]
	, I.inv_total AS [Balance]
	, I.inv_date AS [Date]
	, I.inv_num AS [Bill Number]
	, D.descrip AS [Description]
	, I.acct_code AS [Account Id]
	, I.oper_code AS [Operating Code]
	, 'Unposted' AS [Status]
FROM dbo.uinv I
INNER JOIN dbo.uinvdetl D
ON D.inv_code = I.inv_code

GO

CREATE OR ALTER VIEW [PL].[CB_ChartOfAccounts]
AS 

SELECT 
	acct_code AS [Account Code]
	, sub_code AS [Sub Code]
	, CONCAT(RTRIM(acct_code), '-', RTRIM(sub_code)) AS [Account Number]
	, [name] AS [Name]
	, CASE	
		WHEN [type] = 'A' THEN 'Assets'
		WHEN [type] = 'L' THEN 'Liabilities'
		WHEN [type] = 'C' THEN 'Capital'
		WHEN [type] = 'S' THEN 'Income'
		WHEN [type] = 'E' THEN 'Expense'
		ELSE 'Unknown' END AS [Type]
	, sub_type AS [Sub Type]
	, [status] AS [Status]
FROM dbo.account

GO


CREATE OR ALTER VIEW [PL].[CB_ChartOfAccountsImport]
AS 

SELECT 
Name [AccountName]
, [Account Number] [CBAccountNumber]
, NULL [ParentAccountName]
, [Type] [AccountType]
, NULL [AccountSubType]
, NULL [FinancialInstitution]
, NULL [RoutingNumber]
, NULL [BankAccountNumber]
, NULL [NextCheckNumber]
, NULL [Description]
, NULL [OpeningBalance]
FROM PL.CB_ChartOfAccounts COA

GO


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


CREATE OR ALTER VIEW [PL].[CB_Credits]
AS 
SELECT 
	W.wof_code AS [CreditId]
	, W.[date] AS [Date]
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, ISNULL(dist.amt, 0) AS [Amount]
	, W.descrip AS [Description]
FROM dbo.writeoff W
INNER JOIN dbo.matter M
ON M.clt_code = W.clt_code
AND M.mat_code = W.mat_code
INNER JOIN dbo.client C
ON C.clt_code = W.clt_code
LEFT OUTER JOIN (
	SELECT wof_code, SUM(wroff_amt) amt
	FROM dbo.wofdetl D
	GROUP BY wof_code
) dist
ON dist.wof_code = W.wof_code

GO

CREATE OR ALTER VIEW [PL].[CB_CreditDistributions]
AS 
SELECT 
	W.wof_code AS [CreditId]
	, W.[date] AS [Date]
	, D.bill_code AS [BillId]
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, D.wroff_amt AS [Amount]
	, CASE WHEN D.[type] = 'F' THEN 'Fee'
			WHEN D.[type] = 'E' THEN 'Expense'
			ELSE 'Unknown'
		END AS [Type]
FROM dbo.writeoff W
INNER JOIN dbo.matter M
ON M.clt_code = W.clt_code
AND M.mat_code = W.mat_code
INNER JOIN dbo.client C
ON C.clt_code = W.clt_code
INNER JOIN wofdetl D
ON D.wof_code = W.wof_code

GO



CREATE OR ALTER VIEW [PL].[CB_Payments]
AS 
SELECT 
	R.rec_code AS [PaymentId]
	, R.[date] AS [Date]
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, ISNULL(dist.amt, 0) AS [Amount]
	, R.ref_num AS [ReferenceNumber]
	, R.descrip AS [Description]
FROM dbo.rec R
INNER JOIN dbo.matter M
ON M.clt_code = R.clt_code
AND M.mat_code = R.mat_code
INNER JOIN dbo.client C
ON C.clt_code = R.clt_code
LEFT OUTER JOIN (
	SELECT rec_code, SUM(rec_amt) amt
	FROM dbo.recdetl D
	WHERE D.bill_code IS NOT NULL
	GROUP BY rec_code
) dist
ON dist.rec_code = R.rec_code

GO

CREATE OR ALTER VIEW [PL].[CB_PaymentDistributions]
AS 
SELECT 
	R.rec_code AS [PaymentId]
	, R.[date] AS [Date]
	, D.bill_code AS [BillId]
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, D.rec_amt AS [Amount]
	, CASE WHEN D.[type] = 'F' THEN 'Fee'
			WHEN D.[type] = 'E' THEN 'Expense'
			ELSE 'Unknown'
		END AS [Type]
	, ROW_NUMBER() OVER ( ORDER BY R.REC_CODE, DATE) [ROWNUMBER]
FROM dbo.rec R
INNER JOIN dbo.matter M
ON M.clt_code = R.clt_code
AND M.mat_code = R.mat_code
INNER JOIN dbo.client C
ON C.clt_code = R.clt_code
INNER JOIN recdetl D
ON D.rec_code = R.rec_code
WHERE D.bill_code IS NOT NULL

GO