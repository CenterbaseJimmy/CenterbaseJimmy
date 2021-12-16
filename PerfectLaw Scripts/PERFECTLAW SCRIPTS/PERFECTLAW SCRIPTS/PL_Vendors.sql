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