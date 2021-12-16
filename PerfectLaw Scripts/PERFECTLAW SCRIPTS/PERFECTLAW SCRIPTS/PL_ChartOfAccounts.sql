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