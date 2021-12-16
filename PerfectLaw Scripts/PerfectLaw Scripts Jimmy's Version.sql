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

/*================================================
VIEW - Contacts
=================================================*/
/* ===================================================================================
FOR NEXT IMPORTER - Next import need to look at this contact more to see if logically changes below make sense
=================================================================================== */
CREATE OR ALTER VIEW [PL].[CB_Contacts]
AS 
SELECT 
	C.crow_id AS [ClientId]
	, RTRIM([name]) AS [Client Name]
	, RTRIM(C.clt_code) AS [Client Number]
	--, A.phone 
	--, A.[EMAIL]
	--Filter out address information because creating duplicates
	/*, A.attention AS [Bill To Contact]
	, A.address1 AS [Address 1]
	, A.address2 AS [Address 2]
	, A.address3 AS [Address 3]
	--, CASE WHEN A.Address3 = '' or A.address3 IS NULL THEN Trim(Concat(' ',trim(A.address3a),' ',trim(A.address4)))
	--ELSE trim(Concat(trim(A.address3),' ',trim(A.address3a),' ',trim(A.address4))) End AS [Address 3]
	, A.city
	, A.[state]
	, A.zip*/
	, C.notes
 	, CASE WHEN C.inactive = 1 THEN 'Inactive' ELSE 'Active' END AS [Active Status]
	, c.corig_atty [CLient Originating Attorney]
FROM dbo.client C
/*LEFT OUTER JOIN [address] A
ON A.clt_code = C.clt_code
AND LEN(TRIM(A.addr_code)) < 7*/

GO

/*================================================
VIEW - Matters
=================================================*/
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
	, m.[start_date] AS [Date Opened]
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
	, m.pbs_fmt [PBS FORMAT CODE]
	, f.name [PBS FORMAT NAME]
	, m.bill_fmt [BILL FORMAT CODE]
	, f2.name [BILL FORMAT NAME]
	, m.elec_bill [ELECBILL CODE]
	, f3.name [ELECTRONIC BILL FORMAT NAME]
	, CASE WHEN skip_state=1 THEN 'TRUE' ELSE 'FALSE' END [SKIP STATEMENTS]
	, CASE WHEN email_bill=1 THEN 'TRUE' ELSE 'FALSE' END [CLIENT ACCEPTS BILL VIA EMAIL]
	, init_fc [Fee Credits]
	--, M.MATMINTRST [Matter Minimum Trust] --Did not exist in RudmanWinchell Exports
	, a.email
	, M.billable
	, M.clt_code
	, M.mat_code
	, M.addr_code
FROM dbo.matter M
INNER JOIN client C
	ON C.clt_code = M.clt_code
LEFT OUTER JOIN [address] A
	ON A.clt_code = M.clt_code AND A.addr_code = M.addr_code
LEFT JOIN class CL
	ON M.class=CL.cls_code
LEFT JOIN office O
	ON M.off_code=O.off_code
LEFT OUTER JOIN dbo.format F
	ON m.pbs_fmt = f.fmt_code
LEFT OUTER JOIN dbo.format F2
    ON m.bill_fmt = f2.fmt_code
LEFT OUTER JOIN dbo.format F3
    ON m.elec_bill = f3.fmt_code

GO

/*================================================
VIEW - Matter Custom Fields
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_MattersCustomFields]
AS

SELECT M.mrow_id [MatterID]
	, field1 [Field 1 Date Field]
	, field2 [Field 2 Date Field]
	, field3 [Field 3 Number Field]
	, field4 [Field 4 Number Field]
	, field5 [Field 5]
	, field6 [Field 6]
	, field7 [Field 7]
	, field8 [Field 8]
	, field9 [Field 9]
	, field10 [Field 10]
	, field11 [Field 11]
	, miscell1 [Miscellaneous 1]
	, miscell2 [Miscellaneous 2]
	, miscell3 [Miscellaneous 3]
	, Para1 [IDK 1]
	, Para2 [IDK 2]
FROM dbo.matter M

GO

/*================================================
VIEW - Related Parties
=================================================*/
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

/*================================================
VIEW - Related Parties Matter
=================================================*/
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

/*================================================
VIEW - Expense Codes
=================================================*/
CREATE OR ALTER VIEW [PL].ExpenseCodes AS

SELECT *
, CASE WHEN exp_type=1 THEN 'Hard Cost' WHEN exp_type=2 THEN 'Soft Cost' ELSE NULL END [EXPENSE TYPE]
, CASE WHEN exp_code LIKE '%E[0-9][0-9][0-9]%' THEN exp_code END [LEDES CODE]
FROM expense

GO

/*================================================
VIEW - Activity Codes
=================================================*/
CREATE OR ALTER VIEW [PL].ActivityCodes AS

SELECT *
, CASE WHEN act_code LIKE '%A[0-9][0-9][0-9]%' THEN act_code END [LEDES CODE]
FROM activity

GO

/*================================================
VIEW - Task Codes
=================================================*/
/*==============================
This firm was 100+ so had alot of weird codes not sure if this applies to all
==============================*/
CREATE OR ALTER VIEW [PL].TaskCodes AS

SELECT *
, CASE WHEN task_code LIKE '%L[0-9][0-9][0-9]%' OR task_Code LIKE '%A[0-9][0-9][0-9]%'
OR task_Code LIKE '%B[0-9][0-9][0-9]%' OR task_Code LIKE '%C[0-9][0-9][0-9]%'
OR task_Code LIKE '%LI[0-9][0-9][0-9]%' OR task_Code LIKE '%P[0-9][0-9][0-9]%'
THEN task_code
END [LEDES CODE]
FROM Taskdetl

GO

/*================================================
VIEW - Unbilled Time
=================================================*/
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
, CONCAT('T-', trim(Event_Code)) [ENTRY ID]
FROM time T
JOIN matter M
	ON T.clt_code=M.clt_code
	AND T.mat_code=M.mat_code
LEFT JOIN activity A 
	ON T.act_code=A.act_code
--WHERE T.on_bill=0

GO

/*================================================
VIEW - Unbilled Expenses
=================================================*/
CREATE OR ALTER VIEW [PL].UnbilledExpenses
AS

SELECT D.*
, M.mrow_id [MatterID]
, units [QUANTITY]
, orig_units [ACTUAL QUANTITY]
, dol_value [BILLABLE VALUE]
, orig_value [ACTUAL VALUE]
, descrip [DESCRIPTION]
, CONCAT('E-', trim(Event_Code)) [ENTRY ID]
FROM disburse D
JOIN matter M
	ON D.clt_code=M.clt_code
	AND D.mat_code=M.mat_code
WHERE D.on_bill=0

GO

/*================================================
VIEW - Trust Transactions
=================================================*/
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
	, t.acct_code [Account Code]
FROM dbo.trust T
INNER JOIN dbo.matter M
ON M.clt_code = T.clt_code
AND M.mat_code = T.mat_code
INNER JOIN dbo.client C
ON C.clt_code = T.clt_code


GO

/*================================================
VIEW - Bills
=================================================*/
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

/*================================================
VIEW - Billed Times
=================================================*/
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
, CONCAT('T-', trim(Event_Code)) [ENTRY ID]
FROM archivet T
JOIN matter M
	ON T.clt_code=M.clt_code
	AND T.mat_code=M.mat_code
LEFT JOIN activity A 
	ON T.act_code=A.act_code
JOIN PL.CB_Bills b
ON t.bill_code = b.BillId
WHERE T.bill_code IS NOT NULL

GO

/*================================================
VIEW - Billed Expenses
=================================================*/
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
, CONCAT('E-', trim(Event_Code)) [ENTRY ID]
FROM archived D
JOIN matter M
	ON D.clt_code=M.clt_code
	AND D.mat_code=M.mat_code
JOIN PL.CB_Bills b
ON b.billid= d.bill_code
WHERE D.bill_code IS NOT NULL

GO

/*================================================
VIEW - All the billing entries that have been billed
=================================================*/
CREATE OR ALTER VIEW [PL].[AllBilledEntries]
AS

SELECT 
	[ENTRY ID]
	, date
	, 2 AS [ClassId], 'Expense' AS [ClassName]
	, CONVERT(varchar(200), NULL) AS [UserName]

	, CONVERT(BIT, 'FALSE') AS [IsNonBillable]
	, convert(DECIMAL(18,8), T.[ACTUAL QUANTITY]) AS [ACTUAL QUANTITY], convert(DECIMAL(18,8), T.[ACTUAL RATE]) AS [ACTUAL RATE], T.[ACTUAL VALUE]
	, convert(DECIMAL(18,8), t.[BILLABLE QUANTITY]) AS [BILLABLE QUANTITY], convert(DECIMAL(18,8), t.[BILLABLE RATE]) AS [BILLABLE RATE], t.[BILLABLE VALUE]

	, MatterID, bill_code

	, [descrip]
FROM PL.BilledExpenses t
UNION ALL 

SELECT 
	[ENTRY ID]
	, date
	, 1 AS [ClassId], 'Time' AS [ClassName]
	, atty_code AS [UserName]
	
	, t.[Is Non Billable]
	, convert(DECIMAL(18,8), T.[ACTUAL HOURS]), convert(DECIMAL(18,8), T.[ACTUAL RATE]), T.[ACTUAL VALUE]
	, convert(DECIMAL(18,8), t.[BILLABLE HOURS]), convert(DECIMAL(18,8), t.[BILLABLE RATE]), t.[BILLABLE VALUE]
	
	, MatterID, bill_code
	
	, [descrip]
FROM PL.BilledTime t

GO

/*================================================
VIEW - Rates
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_Rate Tables]
AS 

/*========================================
Old code can use if we finally can do full history for rate tables with effective date, it cause alot of duplicates 
==========================================

SELECT DISTINCT F.[name] AS [RateTableName]
  , R.atty_code AS [UserName]
  , R.rate AS [Rate]
  , NULL [EffectiveDate]
  --, eff_date
FROM feerate R
INNER JOIN feeagree F
ON F.fee_code = R.fee_code
INNER JOIN atty A
ON A.atty_code = R.atty_code
where f.inactive <> 1

GO
*/

/*This should filter out for most recent*/
SELECT DISTINCT 
  F.[name] AS [RateTableName]
  , R.atty_code AS [UserName]
  , R.rate AS [Rate]
  , NULL [EffectiveDate]
FROM feerate r
INNER JOIN feeagree F
ON F.fee_code = R.fee_code
INNER JOIN atty A
ON A.atty_code = R.atty_code
WHERE eff_date = (SELECT MAX(eff_date) FROM feerate fr where r.fee_code = fr.fee_code AND r.atty_code = fr.atty_code) 


GO

/*================================================
VIEW - Set Rates
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_Matter Rate Tables]
AS 

SELECT M.mrow_id AS [ImportId]
  , F.[name] AS [RateTableName]
FROM matter M
INNER JOIN feeagree F
ON F.fee_code = M.std_rate

GO	

/*================================================
VIEW - Set Rate Exceptions
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_Matter Rate Table Exceptions]
AS 

/*========================================
Old code can use if we finally can do full history for rate tables with effective date, it cause alot of duplicates 
==========================================

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
  , eff_date
FROM matter M
INNER JOIN feerate R
ON R.fee_code = M.over_rate2
INNER JOIN atty A
ON A.atty_code = R.atty_code
order by ImportId

GO
*/

SELECT M.mrow_id AS [ImportId]
  , R.atty_code AS [UserName]
  , R.rate AS [Rate]
  , NULL [EffectiveDate]
FROM matter M
INNER JOIN feerate R
ON R.fee_code = M.over_rate
INNER JOIN atty A
ON A.atty_code = R.atty_code
WHERE eff_date = (SELECT MAX(eff_date) FROM feerate fr where m.over_rate = fr.fee_code AND A.atty_code = fr.atty_code) 

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
WHERE eff_date = (SELECT MAX(eff_date) FROM feerate fr where m.over_rate2 = fr.fee_code AND A.atty_code = fr.atty_code) 

GO

/*================================================
VIEW - Vendors
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_Vendors]
AS 
SELECT 
	V.vnd_code AS [VendorId]
	, [name] AS [Name]
	, address1
	, address2
	, address3
	--,trim(CONCAT(address3,' ',address4)) NEWADDRESS3
	, SUBSTRING(address4,0, CHARINDEX(',',address4)) City
	--,right(address4, charindex(',', len(address4)) - 1) Zip
	,left(SUBSTRING(address4,CHARINDEX(',',address4)+1,LEN(address4)),3) State
	,SUBSTRING(address4,CHARINDEX(',',address4)+4,LEN(address4)) Zip
	, tax_id AS [EIN]
	, form_1099
	, V.TERMS
	, V.PMT_DUEDAY
	, A.notes [Vendor Notes]
FROM dbo.vendor V
INNER JOIN vendaddr A
ON A.vnd_code = V.vnd_code
INNER JOIN vendloc L
ON L.vnd_code = V.vnd_code

GO

/*================================================
VIEW - Vendor Bills
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_VendorBills]
AS 
SELECT 
	I.inv_code AS [Vendor Bill Id]
	, I.vnd_code AS [Vendor Id]
	, I.inv_total AS [Total]
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
	, I.inv_total AS [Total]
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

/*================================================
VIEW - Chart of Accounts
=================================================*/
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
	,CASE
	WHEN [type] = 'E' AND [sub_type] = 1 THEN 'Other Expense'
	WHEN [type] = 'S' AND [sub_type] = 1 THEN 'Other Income'
	WHEN [type] = 'L' AND [sub_type] = 2 THEN 'Long Term Liability'
	ELSE '' END AS [Sub Type Name]
	, [status] AS [Status]
FROM dbo.account

GO

/*================================================
VIEW - Chart Of Accounts Import
=================================================*/
CREATE OR ALTER VIEW [PL].[CB_ChartOfAccountsImport]
AS 

SELECT 
Name [AccountName]
, [Account Code] [AlternateCBAccountNumber]
, [Account Number] [CBAccountNumber]
, NULL [ParentAccountName]
, [Type] [AccountType]
, [Sub Type Name] [AccountSubType]
, NULL [FinancialInstitution]
, NULL [RoutingNumber]
, NULL [BankAccountNumber]
, NULL [NextCheckNumber]
, NULL [Description]
, NULL [OpeningBalance]
, [status] AS [Status]
FROM PL.CB_ChartOfAccounts COA

GO

/*================================================
VIEW - Credits
=================================================*/
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


/*================================================
VIEW - Credit Distributions
=================================================*/
CREATE OR ALTER   VIEW [PL].[CB_CreditDistributions]
AS 

SELECT 'D-' + TRIM(T.CreditId) + '-' + TRIM(T.BillId) AS [DistributionId]
	, T.CreditId, T.BillId
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, W.date, t.DistributionTotal
FROM (
	SELECT 
		W.wof_code AS [CreditId]
		, D.bill_code AS [BillId]
		, SUM(D.wroff_amt) AS [DistributionTotal]
	FROM dbo.writeoff W
	INNER JOIN wofdetl D
		ON D.wof_code = W.wof_code
	WHERE D.bill_code IS NOT NULL
	GROUP BY W.wof_code, D.bill_code
	HAVING SUM(D.wroff_amt) <> 0
) T
INNER JOIN dbo.writeoff W
	ON w.wof_code = T.CreditId
INNER JOIN dbo.matter M
	ON M.clt_code = W.clt_code
	AND M.mat_code = W.mat_code
INNER JOIN dbo.client C
	ON C.clt_code = W.clt_code

GO


/*================================================
VIEW - Payments
=================================================*/
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

/*================================================
VIEW - Payment Distributions
=================================================*/
CREATE OR ALTER   VIEW [PL].[CB_PaymentDistributions]
AS 

SELECT 'D-' + TRIM(T.PaymentId) + '-' + TRIM(T.BillId) AS [DistributionId]
	, T.PaymentId, T.BillId
	, M.mrow_id AS [MatterId]
	, C.crow_id AS [ClientId]
	, R.date, t.DistributionTotal
FROM (
	SELECT 
		R.rec_code AS [PaymentId]
		, D.bill_code AS [BillId]
		, SUM(D.rec_amt) AS [DistributionTotal]
	FROM dbo.rec R
	INNER JOIN recdetl D
		ON D.rec_code = R.rec_code
	WHERE D.bill_code IS NOT NULL
	GROUP BY R.rec_code, D.bill_code
	HAVING SUM(D.rec_amt) <> 0
) T
INNER JOIN dbo.rec R
	ON R.rec_code = T.PaymentId
INNER JOIN dbo.matter M
	ON M.clt_code = R.clt_code
	AND M.mat_code = R.mat_code
INNER JOIN dbo.client C
	ON C.clt_code = R.clt_code

GO