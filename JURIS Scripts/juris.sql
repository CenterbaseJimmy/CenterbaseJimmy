-- Make sure the new schema exists
IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.SCHEMATA S WHERE S.SCHEMA_NAME = 'JURIS'))
	EXEC sp_executesql N'CREATE SCHEMA [JURIS]';

GO

/*================================================
VIEW - List of all the types of transactions in the LedgerHistory
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[SummaryARLedgerTypes]'))
	DROP VIEW [juris].[SummaryARLedgerTypes]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- List of all the types of transactions in the LedgerHistory
CREATE VIEW [juris].[SummaryARLedgerTypes]
AS

SELECT L.LHType
	, CASE L.LHType
		WHEN '1' THEN 'Prepaid Balance Forward'
		WHEN '2' THEN 'A/R Balance Forward'
		WHEN '3' THEN 'Manual Bill'
		WHEN '4' THEN 'Regular Bill'
		WHEN '5' THEN 'Prepaid Receipt'
		WHEN '6' THEN 'Prepaid Applied'
		WHEN '7' THEN 'Cash Receipt'
		WHEN '8' THEN 'A/R Adjustment'
		WHEN '9' THEN 'Trust Applied'
		WHEN 'A' THEN 'Unposted Bill'
		WHEN 'B' THEN 'Unposted Bill, Prepaid Applied'
		WHEN 'C' THEN 'Unposted Bill, Trust Applied'
		END AS [TypeName]
	, COUNT(*) AS [RecordCount]
	, SUM(LHCashAmt) AS [LHCashAmt]
	, SUM(LHFees) AS [LHFees]
	, SUM(LHCshExp) AS [LHCshExp]
	, SUM(LHNCshExp) AS [LHNCshExp]
	, SUM(LHSurcharge) AS [LHSurcharge]
	, SUM(LHTaxes1) AS [LHTaxes1]
	, SUM(LHTaxes2) AS [LHTaxes2]
	, SUM(LHTaxes3) AS [LHTaxes3]
	, SUM(LHInterest) AS [LHInterest]
FROM dbo.LedgerHistory L
GROUP BY L.LHType

GO

/*================================================
VIEW - List of all the types of transactions in the LedgerHistory
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[LedgerHistoryDetails]'))
	DROP VIEW [juris].[LedgerHistoryDetails]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- List of all the types of transactions in the LedgerHistory
CREATE VIEW [juris].[LedgerHistoryDetails]
AS

SELECT CliSysNbr AS [ClientId], CliCode AS [ClientCode], CliNickName AS [ClientName]
	, MatSysNbr AS [MatterId], MatCode AS [MatterCode], MatNickName AS [MatterName]
	, LHSysNbr
	, LHBillNbr
	, L.LHType
	, CASE L.LHType
		WHEN '1' THEN 'Prepaid Balance Forward'
		WHEN '2' THEN 'A/R Balance Forward'
		WHEN '3' THEN 'Manual Bill'
		WHEN '4' THEN 'Regular Bill'
		WHEN '5' THEN 'Prepaid Receipt'
		WHEN '6' THEN 'Prepaid Applied'
		WHEN '7' THEN 'Cash Receipt'
		WHEN '8' THEN 'A/R Adjustment'
		WHEN '9' THEN 'Trust Applied'
		WHEN 'A' THEN 'Unposted Bill'
		WHEN 'B' THEN 'Unposted Bill, Prepaid Applied'
		WHEN 'C' THEN 'Unposted Bill, Trust Applied'
		END AS [TypeName]
	, LHDate
	, LHCashAmt	, LHFees	, LHCshExp	, LHNCshExp
	, LHComment
	--, L.cbrowindex
FROM dbo.LedgerHistory L
INNER JOIN dbo.Matter m
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr

GO

/*================================================
VIEW - AR balance by matter/client
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[SummaryARBalances]'))
	DROP VIEW [juris].[SummaryARBalances]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- AR balance by matter/client
CREATE VIEW [juris].[SummaryARBalances]
AS

SELECT ClientId, ClientCode, ClientName, MatterId, MatterCode, MatterName, SUM(t.ARAmount) AS [TotalAR], SUM(T.PrepaidAmount) AS [TotalPrepaid] 
FROM (
	SELECT CliSysNbr AS [ClientId], CliCode AS [ClientCode], CliNickName AS [ClientName]
		 , MatSysNbr AS [MatterId], MatCode AS [MatterCode], MatNickName AS [MatterName]
		 , LHDate
		 , CASE 
			WHEN LHType IN ('3','4','8','A') THEN LHFees + LHCshExp + LHNCshExp
			WHEN LHType IN ('5','7','9','C') THEN -LHCashAmt
			ELSE 0
			END AS [ARAmount]
		 , CASE 
			WHEN LHType IN ('5') THEN LHCashAmt
			WHEN LHType IN ('6','B') THEN -LHCashAmt
			ELSE 0
			END AS [PrepaidAmount]
	FROM dbo.LedgerHistory LH
	INNER JOIN dbo.Matter m
		ON MatSysNbr = LHMatter
	INNER JOIN dbo.Client C
		ON CliSysNbr = MatCliNbr
) T
GROUP BY ClientId, ClientCode, ClientName, MatterId, MatterCode, MatterName
HAVING SUM(t.ARAmount) <> 0 OR SUM(T.PrepaidAmount) <> 0

GO

/*================================================
VIEW - Total AR Balance
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[SummaryTotalAR]'))
	DROP VIEW [juris].[SummaryTotalAR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Total AR Balance
CREATE VIEW [juris].[SummaryTotalAR]
AS

select SUM(t.ARAmount) AS [TotalAR], SUM(T.PrepaidAmount) AS [TotalPrepaid], SUM(t.ARAmount) + SUM(T.PrepaidAmount) AS [TotalARwithoutPrepaid] FROM (
SELECT LHDate
	 , CASE 
		WHEN LHType IN ('3','4','8','A') THEN LHFees + LHCshExp + LHNCshExp
		WHEN LHType IN ('5','7','9','C') THEN -LHCashAmt
		ELSE 0
		END AS [ARAmount]
	 , CASE 
		WHEN LHType IN ('5') THEN LHCashAmt
		WHEN LHType IN ('6','B') THEN -LHCashAmt
		ELSE 0
		END AS [PrepaidAmount]
FROM dbo.LedgerHistory LH
) T

GO

/*================================================
VIEW - Types of trust transactions
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[SummaryTrustTypes]'))
	DROP VIEW [juris].[SummaryTrustTypes]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Types of trust transactions
CREATE VIEW [juris].[SummaryTrustTypes]
AS

SELECT TLType AS [TypeId]
	, CASE TLType
		WHEN 1 THEN 'Deposit'
		WHEN 2 THEN 'Adjustment'
		WHEN 3 THEN 'Computer Check'
		WHEN 4 THEN 'Quick Check'
		WHEN 5 THEN 'Manual Check'
		END AS [dboTypeName]
	, MIN(TLAMOUNT) AS [MinAmount], MAX(TLAMOUNT) AS [MaxAmount]
	, COUNT(*) AS [RecordCount]
FROM dbo.TrustLedger TL
GROUP BY TLType 

GO

/*================================================
VIEW - Trust balance by matter/client
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[SummaryTrustBalances]'))
	DROP VIEW [juris].[SummaryTrustBalances]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Trust balance by matter/client
CREATE VIEW [juris].[SummaryTrustBalances]
AS

SELECT CliSysNbr AS [ClientId], CliCode AS [ClientCode], CliNickName AS [ClientName]
	 , MatSysNbr AS [MatterId], MatCode AS [MatterCode], MatNickName AS [MatterName]
	 , TABalance AS [TrustBalance]
FROM dbo.TrustAccount T
INNER JOIN dbo.Matter m
	ON MatSysNbr = TAMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
WHERE TABalance <> 0

GO

/*================================================
VIEW - Total Trust Balance
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[SummaryTotalTrust]'))
	DROP VIEW [juris].[SummaryTotalTrust]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Total Trust Balance
CREATE VIEW [juris].[SummaryTotalTrust]
AS

SELECT SUM(TABalance) AS [TrustTotal]
FROM dbo.TrustAccount T

GO


/*================================================
VIEW - Billing Codes
=================================================*/


IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[BillingCodes]'))
	DROP VIEW [juris].[BillingCodes]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [juris].[BillingCodes]
AS
	select 
	ac.ActyCdCode [Code]
,	ac.ActyCdDesc [Description]
,	ac.ActyCdText [Text]
,	'A-' + ac.ActyCdCode AS [CodeUniqueID]
,	CASE WHEN AC.ACTYCDCODE LIKE '[E-e][0-9][0-9][0-9]' THEN 'Expense' ELSE 'Time' END as [Class]
,	case when ac.ActyCdCode like '[A-z][0-9][0-9][0-9]' then ac.ActyCdCode else NULL end as [LEDES Code]
, CONCAT(AC.ActyCdCode, ' - ', AC.ActyCdDesc) [BILLING CODE NAME]
	from ActivityCode ac
union all
	select 
	tc.TaskCdCode [Code]
,	tc.TaskCdDesc [Description]
,	tc.TaskCdText [Text]
,	'T-' + TaskCdCode AS [CodeUniqueId]
,	CASE WHEN TC.TASKCDCODE LIKE '[E-e][0-9][0-9][0-9]' THEN 'Expense' ELSE 'Time' END as [Class]
,	case when tc.TaskCdCode like '[A-z][0-9][0-9][0-9]' then tc.TaskCdCode else NULL end as [LEDES Code]
, CONCAT(TC.TaskCdCode, ' - ', TC.TaskCdDesc) [BILLING CODE NAME]
	from TaskCode tc
union all
	select 
	ec.ExpCdCode [Code]
,	ec.ExpCdDesc [Description]
,	ec.ExpCdText [Text]
,	'E-' + ec.ExpCdCode AS [CodeUniqueID]
,	'Expense' as [Class]
,	case when ec.ExpCdCode like '[A-z][0-9][0-9][0-9]' then ec.ExpCdCode else NULL end as [LEDES Code]
,	CONCAT(EC.ExpCdCode, ' - ', EC.ExpCdDesc) [BILLING CODE NAME]
	from ExpenseCode ec


GO


/*================================================
VIEW - Unbilled entries
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[UnbilledEntries]'))
	DROP VIEW [juris].[UnbilledEntries]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Retrieves unbilled time/expense as well as unposted time/expense
CREATE VIEW [juris].[UnbilledEntries]
AS

-- Unbilled Time
SELECT 'T-' + CONVERT(varchar(100), UTBatch) + '-' + CONVERT(varchar(100), UTRecNbr) AS [dboId]
	, UTDate AS [EntryDate]
	, TBDateEntered AS [CreationDate], TBEnteredBy AS [CreatorId], EC.EMPINITIALS AS [CreatorName]
	, 'Time' AS [Class]
	, 'T-' + UTTaskCd AS [TaskCode], 'A-' + UTActivityCd AS [BillingCode]
	, UTActualHrsWrk AS [ActualQty], UTStdRate AS [StandardPrice], UTAmtAtStdRate AS [StandardTotal], UTHoursToBill AS [BillableQty], UTRate AS [BillablePrice], UTAmount AS [BillableTotal]
	, CASE WHEN UTAmount = 0 THEN 0 WHEN UTBillableFlg = 'N' THEN 0 ELSE UTHoursToBill * UTRate END AS [ExpectedValue]
	, UTTkpr AS [UserId], ETK.EMPINITIALS AS [UserName]
	, CASE WHEN UTBillableFlg = 'N' THEN 1 
		WHEN UTAmount = 0 THEN 1
		ELSE 0 END AS [IsNonBillable]
	, UTNarrative AS [Description]
	, UTMatter AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	, TBBatchNbr AS [BatchId]
	, TBStatus AS [BatchStatusId]
	, CASE TBStatus
		WHEN 'P' THEN 'Posted'
		WHEN 'U' THEN 'Unposted'
		WHEN 'L' THEN 'Locked'
		WHEN 'R' THEN 'Ready to Post'
		WHEN 'D' THEN 'Deleted'
		END AS [BatchStatus]
	, TBComment AS [BatchDesciption]
	--, UT.cbrowindex
FROM dbo.UnbilledTime UT
LEFT OUTER JOIN dbo.Employee ETK
	ON ETK.EmpSysNbr = UTTkpr
LEFT OUTER JOIN dbo.TimeBatch TB
	ON TBBatchNbr = UTBatch
LEFT OUTER JOIN dbo.Employee EC
	ON EC.EmpSysNbr = TBEnteredBy
INNER JOIN dbo.Matter M
	ON MatSysNbr = UTMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
UNION ALL
-- Unposted time
select 'T-' + CONVERT(varchar(100), TBDBatch) + '-' + CONVERT(varchar(100), TBDRecNbr) AS [dboId]
	, TBDDate
	, TBDateEntered AS [CreationDate], TBEnteredBy AS [CreatorId], EC.EMPINITIALS AS [CreatorName]
	, 'Time' AS [Class]
	, 'T-' + TBDTaskCd AS [TaskCode], 'A-' + TBDActivityCd AS [BillingCode]
	, TBDActualHrsWrk, TBDRate AS [StandardRate], TBDAmount AS [AmountAtStdRate], TBDHoursToBill, TBDRate, TBDAmount
	, CASE WHEN TBDAmount = 0 THEN 0 WHEN TBDBillableFlg = 'N' THEN 0 ELSE TBDHoursToBill * TBDRate END AS [ExpectedValue]
	, TBDTkpr, ETK.EMPINITIALS
	, CASE WHEN TBDBillableFlg = 'N' THEN 1 
		WHEN TBDAmount = 0 THEN 1
		ELSE 0 END AS [IsNonBillable]
	, TBDNarrative
	, TBDMatter AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	, TBBatchNbr AS [BatchId]
	, TBStatus
	, CASE TBStatus
		WHEN 'P' THEN 'Posted'
		WHEN 'U' THEN 'Unposted'
		WHEN 'L' THEN 'Locked'
		WHEN 'R' THEN 'Ready to Post'
		WHEN 'D' THEN 'Deleted'
		END AS [BatchStatus]
	, TBComment
	--, TBD.cbrowindex
from dbo.TimeBatch TB
INNER JOIN dbo.TimeBatchDetail TBD
	ON TBDBatch = TBBatchNbr
LEFT OUTER JOIN dbo.Employee ETK
	ON ETK.EmpSysNbr = TBDTkpr
LEFT OUTER JOIN dbo.Employee EC
	ON EC.EmpSysNbr = TBEnteredBy
INNER JOIN dbo.Matter M
	ON MatSysNbr = TBDMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
where TBStatus IN ('R', 'U')
UNION ALL
-- Unbilled expenses
SELECT 'E-' + CONVERT(varchar(100), UEBatch) + '-' + CONVERT(varchar(100), UERecNbr) AS [dboId]
	, UEDate AS [EntryDate]
	, EBDateEntered AS [CreationDate], EBEnteredBy AS [CreatorId], EC.EMPINITIALS AS [CreatorName]
	, 'Expense' AS [Class]
	, 'T-' + UEBudgTaskCd AS [TaskCode], 'E-' + UEExpCd AS [BillingCode]
	, UEMult AS [ActualQty], UEUnits  AS [ActualPrice], UEAmount AS [ActualTotal], UEMult AS [BillableQty], UEUnits  AS [BillablePrice], UEAmount AS [BillableTotal]
	, UEUnits * UEMult AS [ExpectedValue]
	, NULL AS [UserId], NULL AS [UserName]
	, CASE WHEN UEAmount = 0 THEN 1 ELSE 0 END AS [IsNonBillable]
	, UENarrative AS [Description]
	, UEMatter AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	, EBBatchNbr AS [BatchId]
	, EBStatus
	, CASE EBStatus
		WHEN 'P' THEN 'Posted'
		WHEN 'U' THEN 'Unposted'
		WHEN 'L' THEN 'Locked'
		WHEN 'R' THEN 'Ready to Post'
		WHEN 'D' THEN 'Deleted'
		END AS [BatchStatus]
	, EBComment
	--, UE.cbrowindex
FROM dbo.UnbilledExpense UE
INNER JOIN dbo.Matter M
	ON MatSysNbr = UEMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
LEFT OUTER JOIN dbo.ExpenseBatch EB
	ON EBBatchNbr = UEBatch
LEFT OUTER JOIN dbo.Employee EC
	ON EC.EmpSysNbr = EBEnteredBy
UNION ALL
-- Unposted expenses
select 'E-' + CONVERT(varchar(100), EBDBatch) + '-' + CONVERT(varchar(100), EBDRecNbr) AS [dboId]
	, EBDDate
	, EBDateEntered AS [CreationDate], EBEnteredBy AS [CreatorId], EC.EMPINITIALS AS [CreatorName]
	, 'Expense' AS [Class]
	, 'T-' + EBDBudgTaskCd AS [TaskCode], 'E-' + EBDExpCd AS [BillingCode]
	, EBDMult AS [ActualQty], EBDUnits  AS [ActualPrice], EBDAmount AS [ActualTotal], EBDMult AS [BillableQty], EBDUnits  AS [BillablePrice], EBDAmount AS [BillableTotal]
	, EBDUnits * EBDMult AS [ExpectedValue]
	, NULL AS [UserId], NULL AS [UserName]
	, CASE WHEN EBDAmount = 0 THEN 1 ELSE 0 END AS [IsNonBillable]
	, EBDNarrative
	, EBDMatter AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	, EBBatchNbr AS [BatchId]
	, EBStatus
	, CASE EBStatus
		WHEN 'P' THEN 'Posted'
		WHEN 'U' THEN 'Unposted'
		WHEN 'L' THEN 'Locked'
		WHEN 'R' THEN 'Ready to Post'
		WHEN 'D' THEN 'Deleted'
		END AS [BatchStatus]
	, EBComment
	--, EBD.cbrowindex
from dbo.ExpenseBatch EB
INNER JOIN dbo.ExpBatchDetail EBD
	ON EBDBatch = EBBatchNbr
LEFT OUTER JOIN dbo.Employee EC
	ON EC.EmpSysNbr = EBEnteredBy
INNER JOIN dbo.Matter M
	ON MatSysNbr = EBDMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
where EBStatus IN ('R', 'U')

GO

/*================================================
VIEW - Invoices and statements that have records in the matter allocation table
NOTE: Does not include OLD bills that are in the ledger history, but not in the matter allocation table
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[Bills]'))
	DROP VIEW [juris].[Bills]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Retrieves unbilled time/expense as well as unposted time/expense
CREATE VIEW [juris].[Bills]
AS

SELECT
	T.dboId
	, CliSysNbr, CliCode, CliNickName, MatSysNbr, MatCode, MatNickName
	, T.LHType, T.TypeName, T.InvoiceNumber, T.IssueDate, T.Memo
	, T.Fees, T.CashExpenses, T.NonCashExpenses
	, T.Total, T.Payments, T.CreditAdjustments, T.Balance
	, T.TimeEntryTotal, T.ExpenseEntryTotal
	, T.IsStatement
	, CASE WHEN LHType = '4' AND TimeEntryTotal + ExpenseEntryTotal > 0 THEN (T.TimeEntryTotal + T.ExpenseEntryTotal) - T.Total ELSE 0 END AS [Discount]
	, T.INTEREST
	--, T.cbrowindex
FROM (
	SELECT 'ARMLH-' + CONVERT(varchar(100), LHSysNbr) AS [dboId]
		, CliSysNbr, CliCode, CliNickName, MatSysNbr, MatCode, MatNickName
		, LHType
		, CASE LHType
			WHEN '1' THEN 'Prepaid Balance Forward'
			WHEN '2' THEN 'A/R Balance Forward'
			WHEN '3' THEN 'Manual Bill'
			WHEN '4' THEN 'Regular Bill'
			WHEN '5' THEN 'Prepaid Receipt'
			WHEN '6' THEN 'Prepaid Applied'
			WHEN '7' THEN 'Cash Receipt'
			WHEN '8' THEN 'A/R Adjustment'
			WHEN '9' THEN 'Trust Applied'
			WHEN 'A' THEN 'Unposted Bill'
			WHEN 'B' THEN 'Unposted Bill, Prepaid Applied'
			WHEN 'C' THEN 'Unposted Bill, Trust Applied'
			END AS [TypeName]
		, LHBillNbr AS [InvoiceNumber]
		, LHDate AS [IssueDate]
		, LHComment AS [Memo]
		, ARMFeeBld AS [Fees], ARMCshExpBld AS [CashExpenses], ARMNCshExpBld AS [NonCashExpenses]
		, (ARM.ARMFeeBld  + ARM.ARMCshExpBld  + ARM.ARMNCshExpBld ) AS [Total]
		, (ARM.ARMFeeRcvd + ARM.ARMCshExpRcvd + ARM.ARMNCshExpRcvd) AS [Payments]
		, -(ARM.ARMFeeAdj  + ARM.ARMCshExpAdj  + ARM.ARMNCshExpAdj ) AS [CreditAdjustments]
		, ARMBalDue AS [Balance]
		, CASE WHEN (ARM.ARMFeeBld  + ARM.ARMCshExpBld  + ARM.ARMNCshExpBld ) > 0 THEN 0 ELSE 1 END AS [IsStatement]
		, ISNULL((SELECT SUM(BTAmtOnBill) FROM dbo.BilledTime WHERE BTBillNbr = LHBillNbr AND BTMatter = LHMatter), 0) AS [TimeEntryTotal]
		, ISNULL((SELECT SUM(BEAmtOnBill) FROM dbo.BilledExpenses WHERE BEBillNbr = LHBillNbr AND BEMatter = LHMatter), 0) AS [ExpenseEntryTotal]
		, lh.LHInterest AS INTEREST
		--, LH.cbrowindex
	FROM dbo.ARMatAlloc ARM
	INNER JOIN dbo.LedgerHistory LH
		ON LHSysNbr = ARMLHLink
	INNER JOIN dbo.Matter 
		ON MatSysNbr = LHMatter
	INNER JOIN dbo.Client
		ON CliSysNbr = MatCliNbr 
	WHERE NOT EXISTS (SELECT LH2.LHSysNbr FROM dbo.LedgerHistory LH2 WHERE LH2.LHType = 'A' AND LH2.LHMatter = LH.LHMatter AND LH2.LHBillNbr = LH.LHBillNbr)
) T


GO

/*================================================
VIEW - Manual Bill Entries
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[ManualBilledEntries]'))
	DROP VIEW [juris].[ManualBilledEntries]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Details about billing entries that are on Manual Bills
CREATE VIEW [juris].[ManualBilledEntries]
AS

SELECT 'ARE-' + CONVERT(varchar(100), AREID) AS [dboId]
	, LHDate AS [Date]
	, 2 as [ClassId], 'Expense' AS [Class]
	, AREBillNbr AS [BillNumber]
	, NULL AS [UserId], NULL AS [UserName]
	, 'E-' + ExpCdCode AS [BillingCodeId], ExpCdDesc AS [BillingCodeName]
	, NULL AS [TaskCodeId], NULL AS [TaskCodeName]
	, 1 AS [ActualQty], AREBldAmount AS [ActualPrice], AREBldAmount AS [ActualTotal]
	, 1 AS [BilledQty], AREBldAmount AS [BilledPrice], AREBldAmount AS [BilledTotal]
	, 1 AS [IsFlatRate], 0 AS [IsNonBillable], 0 AS [IsHidden]
	, ExpCdText AS [Description]
	, 'ARMLH-' + CONVERT(varchar(100), LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, ARE.cbrowindex
FROM dbo.LedgerHistory LH
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.ARExpAlloc ARE
	ON AREMatter = ARMMatter
	AND AREBillNbr = ARMBillNbr
INNER JOIN dbo.ExpenseCode ExpCd
	ON ExpCdCode = AREExpCd
WHERE LHType = '3'
UNION ALL
SELECT 'ARFT-' + CONVERT(varchar(100), ARFTID) AS [dboId]
	, LHDate AS [Date]
	, 1 as [ClassId], 'Time' AS [Class]
	, ARFTBillNbr AS [BillNumber]
	, EmpSysNbr AS [UserId], empinitials AS [UserName]
	, 'A-' + ActyCdCode AS [BillingCodeId], ActyCdDesc AS [BillingCodeName]
	, 'T-' + TaskCdCode AS [TaskCodeId], TaskCdDesc AS [TaskCodeName]
	, 1 AS [ActualQty], ARFTActualAmtBld AS [ActualPrice], ARFTActualAmtBld AS [ActualTotal]
	, 1 AS [BilledQty], ARFTActualAmtBld AS [BilledPrice], ARFTActualAmtBld AS [BilledTotal]
	, 1 AS [IsFlatRate], 0 AS [IsNonBillable], 0 AS [IsHidden]
	, 'For professional services rendered' AS [Description]
	, 'ARMLH-' + CONVERT(varchar(100), LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, ARFT.cbrowindex
FROM dbo.LedgerHistory LH
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.ARFTaskAlloc ARFT
	ON ARFTMatter = ARMMatter
	AND ARFTBillNbr = ARMBillNbr
INNER JOIN dbo.Employee  Emp
	ON EmpSysNbr = ARFTTkpr
LEFT OUTER JOIN dbo.TaskCode TaskCd
	ON TaskCdCode = ARFTTaskCd
LEFT OUTER JOIN dbo.ActivityCode ActyCd
	ON ActyCdCode = ARFTActivityCd
WHERE LHType = '3'


GO

/*================================================
VIEW - Regular Bill Entries
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[RegularBilledEntries]'))
	DROP VIEW [juris].[RegularBilledEntries]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Details about billing entries that are on Regular Bills
CREATE VIEW [juris].[RegularBilledEntries]
AS

SELECT 'BE-' + CONVERT(varchar(100), BEBatch) + '-' + CONVERT(varchar(100), BERecNbr) AS [dboId]
	, BEDate AS [Date]
	, 2 as [ClassId], 'Expense' AS [Class]
	, BEBillNbr AS [BillNumber]
	, NULL AS [UserId], NULL AS [UserName]
	, 'E-' + ExpCdCode AS [BillingCodeId], ExpCdDesc AS [BillingCodeName]
	, 'T-' + TaskCdCode AS [TaskCodeId], TaskCdDesc AS [TaskCodeName]
	, BEMult AS [ActualQty], BEUnits AS [ActualPrice], BEAmount AS [ActualTotal]
	, CASE WHEN BEAmtOnBill <> 0 AND BEUnitsOnBill <> 0 THEN BEAmtOnBill / BEUnitsOnBill ELSE 1 END AS [BilledQty]
	, CASE WHEN BEUnitsOnBill <> 0 THEN BEUnitsOnBill WHEN BEAmtOnBill <> 0 THEN BEAmtOnBill ELSE 0 END AS [BilledPrice]
	, BEAmtOnBill AS [BilledTotal]
	, CASE WHEN BEAmtOnBill <> 0 AND BEUnitsOnBill = 0 THEN 1 ELSE 0 END AS [IsFlatRate]
	, CASE WHEN BEAmtOnBill = 0 THEN 1 ELSE 0 END AS [IsNonBillable]
	, CASE WHEN BEAmtOnBill = 0 AND BEStatusOnBill = 'S' THEN 1 ELSE 0 END AS [IsHidden]
	, BENarrative AS [Description], BEBillNote AS [Note]
	, 'ARMLH-' + CONVERT(varchar(100), LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, BE.cbrowindex
FROM dbo.LedgerHistory LH
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.BilledExpenses BE
	ON BEMatter = LHMatter
	AND BEBillNbr = LHBillNbr
LEFT OUTER JOIN dbo.ExpenseCode ExpCd
	ON ExpCdCode = BEExpCd
LEFT OUTER JOIN dbo.TaskCode TaskCd
	ON TaskCdCode = BEBudgTaskCd
WHERE LHType IN ('4','7','8')
UNION ALL
SELECT 'BT-' + CONVERT(varchar(100), BTBatch) + '-' + CONVERT(varchar(100), BTRecNbr) AS [dboId]
	, BTDate AS [Date]
	, 1 as [ClassId], 'Time' AS [Class]
	, BTBillNbr AS [BillNumber]
	, EmpSysNbr AS [UserId], empinitials AS [UserName]
	, 'A-' + ActyCdCode AS [BillingCodeId], ActyCdDesc AS [BillingCodeName]
	, 'T-' + TaskCdCode AS [TaskCodeId], TaskCdDesc AS [TaskCodeName]
	, BTActualHrsWrk AS [ActualQty], BTRate AS [ActualPrice], BTAmount AS [ActualTotal]
	, CASE WHEN BTAmtOnBill <> 0 AND BTRateOnBill <> 0 THEN BTAmtOnBill / BTRateOnBill ELSE 1 END AS [BilledQty]
	, CASE WHEN BTRateOnBill <> 0 THEN BTRateOnBill WHEN BTAmtOnBill <> 0 THEN BTAmtOnBill ELSE 0 END AS [BilledPrice]
	, BTAmtOnBill AS [BilledTotal]
	, CASE WHEN BTAmtOnBill <> 0 AND BTRateOnBill = 0 THEN 1 ELSE 0 END AS [IsFlatRate]
	, CASE WHEN BTAmtOnBill = 0 THEN 1 ELSE 0 END AS [IsNonBillable]
	, CASE WHEN BTAmtOnBill = 0 AND BTStatusOnBill = 'S' THEN 1 ELSE 0 END AS [IsHidden]
	, BTNarrative AS [Description], BTBillNote AS [Note]
	, 'ARMLH-' + CONVERT(varchar(100), LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, BT.cbrowindex
FROM dbo.LedgerHistory LH
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.BilledTime BT
	ON BTMatter = LHMatter
	AND BTBillNbr = LHBillNbr
INNER JOIN dbo.Employee  Emp
	ON EmpSysNbr = BTTkpr
LEFT OUTER JOIN dbo.ActivityCode ActyCd
	ON ActyCdCode = BTActivityCd
LEFT OUTER JOIN dbo.TaskCode TaskCd
	ON TaskCdCode = BTTaskCd
WHERE LHType IN ('4','7','8')

GO

/*================================================
VIEW - All Billed Entries
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[BilledEntries]'))
	DROP VIEW [juris].[BilledEntries]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Details about billing entries that are on Regular Bills
CREATE VIEW [juris].[BilledEntries]
AS

SELECT B.dboId, B.Date, B.ClassId, B.Class, B.BillNumber, B.UserId, B.UserName
	, B.BillingCodeId, B.BillingCodeName, B.TaskCodeId, B.TaskCodeName
	, B.ActualQty, B.ActualPrice, B.ActualTotal
	, B.BilledQty, B.BilledPrice, B.BilledTotal
	, B.IsFlatRate, B.IsNonBillable, B.IsHidden
	, B.Description, B.Note
	, B.InvoiceId
	, B.MatterId, B.ClientId
	, B.CliCode, B.CliNickName, B.MatCode, B.MatNickName
	--, B.cbrowindex
FROM JURIS.RegularBilledEntries B
UNION ALL
SELECT B.dboId, B.Date, B.ClassId, B.Class, B.BillNumber, B.UserId, B.UserName
	, B.BillingCodeId, B.BillingCodeName, B.TaskCodeId, B.TaskCodeName
	, B.ActualQty, B.ActualPrice, B.ActualTotal
	, B.BilledQty, B.BilledPrice, B.BilledTotal
	, B.IsFlatRate, B.IsNonBillable, B.IsHidden
	, B.Description, NULL
	, B.InvoiceId
	, B.MatterId, B.ClientId
	, B.CliCode, B.CliNickName, B.MatCode, B.MatNickName
	--, B.cbrowindex
FROM JURIS.ManualBilledEntries B

GO

/*================================================
VIEW - All payments from Cash Receipts
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[PaymentsCR]'))
	DROP VIEW [juris].[PaymentsCR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- All payments from Cash Receipts
CREATE VIEW [juris].[PaymentsCR]
AS

SELECT 'CR-' + CONVERT(varchar(100), CRBatch) + '-' + CONVERT(varchar(100), CRRecNbr) AS [dboId]
	, CRBDateEntered AS [CreationDate], CRBEnteredBy AS [CreatorId], EC.EMPINITIALS AS [CreatorName]
	, CRDate AS [PaymentDate]
	, CRCheckNbr AS [CheckNumber]
	, CRPayor AS [Payor]
	, (SELECT SUM(CRAFeeAmt + CRACshExpAmt + CRANCshExpAmt) FROM dbo.CRARAlloc WHERE CRABatch = CRBatch AND CRARecNbr = CRRecNbr)  AS [PaymentAmount]
	, CRBComment AS [Comment]
	, Cli.MatCliNbr AS [ClientId]
	, Mat.CRAMatter AS [MatterId]
	--, CR.cbrowindex
FROM dbo.CashReceipt CR
INNER JOIN dbo.CashReceiptsBatch CRB
	ON CRBBatchNbr = CRBatch 
LEFT OUTER JOIN dbo.Employee EC
	ON EC.EmpSysNbr = CRBEnteredBy
LEFT OUTER JOIN (
		SELECT CRA.CRABatch, CRA.CRARecNbr, MatCliNbr
		FROM (
			SELECT CRABatch, CRARecNbr, COUNT(*) AS [TotalDistributions]
			FROM dbo.CRARAlloc
			GROUP BY CRABatch, CRARecNbr
		) T
		INNER JOIN dbo.CRARAlloc CRA
			ON T.CRABatch = CRA.CRABatch
			AND T.CRARecNbr = CRA.CRARecNbr
		INNER JOIN dbo.Matter M
			ON MatSysNbr = CRAMatter
		GROUP BY CRA.CRABatch, CRA.CRARecNbr, MatCliNbr, T.TotalDistributions
		HAVING COUNT(*) = T.TotalDistributions ) Cli
	ON Cli.CRABatch = CRBatch
		AND Cli.CRARecNbr = CRRecNbr
LEFT OUTER JOIN (
		SELECT CRA.CRABatch, CRA.CRARecNbr, CRAMatter
		FROM (
			SELECT CRABatch, CRARecNbr, COUNT(*) AS [TotalDistributions]
			FROM dbo.CRARAlloc
			GROUP BY CRABatch, CRARecNbr
		) T
		INNER JOIN dbo.CRARAlloc CRA
			ON T.CRABatch = CRA.CRABatch
			AND T.CRARecNbr = CRA.CRARecNbr
		GROUP BY CRA.CRABatch, CRA.CRARecNbr, CRAMatter, T.TotalDistributions
		HAVING COUNT(*) = T.TotalDistributions ) Mat
	ON Mat.CRABatch = CRBatch
		AND Mat.CRARecNbr = CRRecNbr
where CRARCsh <> 0

GO

/*================================================
VIEW - All payment distributions from Cash Receipts
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[DistributionsCR]'))
	DROP VIEW [juris].[DistributionsCR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- All payment distributions from Cash Receipts
CREATE VIEW [juris].[DistributionsCR]
AS

SELECT 'CRA-' + CONVERT(varchar(100), CRABatch) + '-' + CONVERT(varchar(100), CRARecNbr) + '-' + CONVERT(varchar(100), CRAMatter) + '-' + CONVERT(varchar(100), CRABillNbr) AS [dboId]
	, CRADate AS [DistributionDate]
	, CRAFeeAmt + CRACshExpAmt + CRANCshExpAmt AS [DistributionAmount]
	, 'CR-' + CONVERT(varchar(100), CRABatch) + '-' + CONVERT(varchar(100), CRARecNbr) AS [PaymentId]
	, 'ARMLH-' + CONVERT(varchar(100), LH.LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, CRA.cbrowindex
FROM dbo.LedgerHistory LH
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.CRARAlloc CRA
	ON CRAMatter = ARMMatter
	AND CRABillNbr = ARMBillNbr
INNER JOIN dbo.LedgerHistory LHdist
	ON LHdist.LHSysNbr = CRALHLink

GO

/*================================================
VIEW - A list of payments that could be created to reflect the Prepaid balance of each in dbo
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[PrepaidBalances]'))
	DROP VIEW [juris].[PrepaidBalances]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- A list of payments that could be created to reflect the Prepaid balance of each in dbo
CREATE VIEW [juris].[PrepaidBalances]
AS

SELECT 'LHPPD-' + CONVERT(varchar(100), MatSysNbr) AS [dboId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, MAX(CASE LHType WHEN '5' THEN LHDate END) AS [PrePaidDate]
	, SUM(CASE LHType WHEN '5' THEN LHCashAmt WHEN '6' THEN -LHCashAmt END) AS [PrePaidBalance]
	, CliCode, CliNickName, MatCode, MatNickName
	--, M.cbrowindex
FROM dbo.LedgerHistory LH
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
WHERE LHType IN ('5','6')
	AND NOT EXISTS (SELECT * FROM dbo.LedgerHistory LH2 WHERE LH.LHType = '6' AND LH2.LHType = 'B' AND LH2.LHMatter = LH.LHMatter AND LH2.LHBillNbr = LH.LHBillNbr )
GROUP BY MatSysNbr, CliSysNbr, CliCode, CliNickName, MatCode, MatNickName--, M.cbrowindex
HAVING SUM(CASE LHType WHEN '5' THEN LHCashAmt WHEN '6' THEN -LHCashAmt END) <> 0

GO

/*================================================
VIEW - Returns all the distributions / payments that do not have a cash receipt connected
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[DistributionsWithoutCR]'))
	DROP VIEW [juris].[DistributionsWithoutCR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns all the distributions / payments that do not have a cash receipt connected
CREATE VIEW [juris].[DistributionsWithoutCR]
AS

SELECT 'LH7-' + CONVERT(varchar(100), LHpay.LHSysNbr) AS [dboID]
	, LHPay.LHDate AS [Date]
	, LHPay.LHCashAmt AS [Amount]
	, LHpay.LHComment AS [Comment]
	, 'ARMLH-' + CONVERT(varchar(100), LHbill.LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, LHpay.cbrowindex
FROM dbo.LedgerHistory LHbill
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHbill.LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.LedgerHistory LHpay
	ON LHpay.LHMatter = LHbill.LHMatter
	AND LHpay.LHBillNbr = LHbill.LHBillNbr
WHERE LHpay.LHType IN ('7')
	AND NOT EXISTS (SELECT * FROM dbo.CRARAlloc WHERE CRALHLink = LHpay.LHSysNbr)

GO

/*================================================
VIEW - Returns all the distributions / payments that will be created to cover prepaid applied transactions
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[DistributionsPrepaid]'))
	DROP VIEW [juris].[DistributionsPrepaid]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns all the distributions / payments that will be created to cover prepaid applied transactions
CREATE VIEW [juris].[DistributionsPrepaid]
AS

SELECT 'LH6-' + CONVERT(varchar(100), LHpay.LHSysNbr) AS [dboID]
	, LHPay.LHDate AS [Date]
	, LHPay.LHCashAmt AS [Amount]
	, LHpay.LHComment AS [Comment]
	, 'ARMLH-' + CONVERT(varchar(100), LHbill.LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, LHpay.cbrowindex
FROM dbo.LedgerHistory LHbill
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHbill.LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.LedgerHistory LHpay
	ON LHpay.LHMatter = LHbill.LHMatter
	AND LHpay.LHBillNbr = LHbill.LHBillNbr
WHERE LHpay.LHType IN ('6')
	AND NOT EXISTS (SELECT * FROM dbo.LedgerHistory LH2 WHERE LH2.LHMatter = LHpay.LHMatter AND LH2.LHBillNbr = LHpay.LHBillNbr and LH2.LHType = 'B' )

GO

/*================================================
VIEW - Returns all the distributions / payments that will be created to cover trust payments
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[DistributionsTrust]'))
	DROP VIEW [juris].[DistributionsTrust]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns all the distributions / payments that will be created to cover trust payments
CREATE VIEW [juris].[DistributionsTrust]
AS

SELECT 'LH9-' + CONVERT(varchar(100), LHpay.LHSysNbr) AS [dboId]
	, LHPay.LHDate AS [Date]
	, LHPay.LHCashAmt AS [Amount]
	, LHpay.LHComment AS [Comment]
	, 'ARMLH-' + CONVERT(varchar(100), LHbill.LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, LHpay.cbrowindex
FROM dbo.LedgerHistory LHbill
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHbill.LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.LedgerHistory LHpay
	ON LHpay.LHMatter = LHbill.LHMatter
	AND LHpay.LHBillNbr = LHbill.LHBillNbr
WHERE LHpay.LHType = '9' 
	AND NOT EXISTS (SELECT * FROM dbo.LedgerHistory LH2 WHERE LH2.LHMatter = LHpay.LHMatter AND LH2.LHBillNbr = LHpay.LHBillNbr and LH2.LHType = 'C' )

GO

/*================================================
VIEW - Returns all the payments from various sources
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[PaymentsAll]'))
	DROP VIEW [juris].[PaymentsAll]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns all the payments from various sources
CREATE VIEW [juris].[PaymentsAll]
AS

SELECT dboId, CreationDate, CreatorId, CreatorName
	, PaymentDate, CheckNumber, Payor, PaymentAmount, Comment
	, ClientId, MatterId
	--, cbrowindex
FROM JURIS.PaymentsCR
UNION ALL
SELECT dboId, PrePaidDate AS [CreationDAte], NULL AS [CreatorId], NULL AS [CreatorName]
	, PrepaidBalance AS [PaymentDate], NULL AS [CheckNumber], NULL AS [Payor], PrePaidBalance AS [PaymentAmount], 'Prepaid Balance' AS [Comment]
	, ClientId, MatterId
	--, cbrowindex
FROM JURIS.PrepaidBalances
WHERE PrePaidBalance > 0
UNION ALL
SELECT dboID, Date AS [CreationDAte], NULL AS [CreatorId], NULL AS [CreatorName]
	, Date AS [PaymentDate], NULL AS [CheckNumber], NULL AS [Payor], Amount AS [PaymentAmount], Comment
	, ClientId, MatterId
	--, cbrowindex
FROM JURIS.DistributionsWithoutCR
UNION ALL
SELECT dboID, Date AS [CreationDAte], NULL AS [CreatorId], NULL AS [CreatorName]
	, Date AS [PaymentDate], NULL AS [CheckNumber], NULL AS [Payor], Amount AS [PaymentAmount], Comment
	, ClientId, MatterId
	--, cbrowindex
FROM JURIS.[DistributionsPrepaid]
UNION ALL
SELECT dboID, Date AS [CreationDAte], NULL AS [CreatorId], NULL AS [CreatorName]
	, Date AS [PaymentDate], NULL AS [CheckNumber], NULL AS [Payor], Amount AS [PaymentAmount], Comment
	, ClientId, MatterId
	--, cbrowindex
FROM JURIS.[DistributionsTrust]

GO

/*================================================
VIEW - Returns all the payment distributions from various sources
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[DistributionsAll]'))
	DROP VIEW [juris].[DistributionsAll]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns all the payment distributions from various sources
CREATE VIEW [juris].[DistributionsAll]
AS

SELECT dboId, DistributionDate, DistributionAmount
	, PaymentId, InvoiceId, MatterId
	--, cbrowindex
FROM JURIS.[DistributionsCR]
UNION ALL
SELECT dboID, Date, Amount
	, dboID AS [PaymentId], InvoiceId, MatterId
	--, cbrowindex
FROM JURIS.[DistributionsWithoutCR]
UNION ALL
SELECT dboID, Date, Amount
	, dboID AS [PaymentId], InvoiceId, MatterId
	--, cbrowindex
FROM JURIS.[DistributionsPrepaid]
UNION ALL
SELECT dboID, Date, Amount
	, dboID AS [PaymentId], InvoiceId, MatterId
	--, cbrowindex
FROM JURIS.[DistributionsTrust]

GO


/*================================================
VIEW - Returns all the credits/distributions
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[Credits]'))
	DROP VIEW [juris].[Credits]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Returns all the credits/distributions
CREATE VIEW [juris].[Credits]
AS

SELECT 'LH8-' + CONVERT(varchar(100), LHCredit.LHSysNbr) AS [dboID]
	, LHCredit.LHDate AS [Date]
	, -(LHCredit.LHFees + LHCredit.LHCshExp + LHCredit.LHNCshExp) AS [Amount]
	, LHCredit.LHComment AS [Comment]
	, 'ARMLH-' + CONVERT(varchar(100), LHbill.LHSysNbr) AS [InvoiceId]
	, MatSysNbr AS [MatterId], CliSysNbr AS [ClientId]
	, CliCode, CliNickName, MatCode, MatNickName
	--, LHCredit.cbrowindex
FROM dbo.LedgerHistory LHbill
INNER JOIN dbo.ARMatAlloc ARM
	ON ARMLHLink = LHbill.LHSysNbr
INNER JOIN dbo.Matter M
	ON MatSysNbr = LHMatter
INNER JOIN dbo.Client C
	ON CliSysNbr = MatCliNbr
INNER JOIN dbo.LedgerHistory LHCredit
	ON LHCredit.LHMatter = LHbill.LHMatter
	AND LHCredit.LHBillNbr = LHbill.LHBillNbr
WHERE LHCredit.LHType IN ('8')

GO

/*================================================
VIEW - Trust Deposits from Cash Receipts
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustDepositsCR]'))
	DROP VIEW [juris].[TrustDepositsCR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Trust Deposits from Cash Receipts
CREATE VIEW [juris].[TrustDepositsCR]
AS

-- Find any deposits that came from a cash receipt
select 'TCR-' + CONVERT(varchar(100), CRTBatch) + '-' + CONVERT(varchar(100), CRTRecNbr) + CONVERT(varchar(100), CRTSeqNbr) AS [dboId]
	, CRTBank AS [Bank], CRTAmount AS [Credit], CRDate AS [Date], CRBComment + ': ' + CRPayor AS [Memo]
	, CRTMatter AS [MatterId]
	, 'CR-' + CONVERT(varchar(100), CRBatch) + '-' + CONVERT(varchar(100), CRRecNbr) AS [PaymentId]
	--, CRT.cbrowindex
FROM dbo.CRTrustAlloc CRT
INNER JOIN dbo.CashReceipt CR
	ON CRBatch = CRTBatch
	AND CRRecNbr = CRTRecNbr
INNER JOIN dbo.CashReceiptsBatch CRB
	ON CRBBatchNbr = CRTBatch 
WHERE CR.CRARCsh <> 0

GO

/*================================================
VIEW - Trust Deposits without cash receipts (usually for older transactions)
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustDepositsWithoutCR]'))
	DROP VIEW [juris].[TrustDepositsWithoutCR]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Trust Deposits without cash receipts (usually for older transactions)
CREATE VIEW [juris].[TrustDepositsWithoutCR]
AS

SELECT 'TL1-' + CONVERT(varchar(100), TLSysNbr) AS [dboId]
	, TLBank AS [Bank], TLAmount AS [Credit], TLDate AS [Date], TLMemo AS [Memo]
	, TLMatter AS [MatterId]
	--, cbrowindex
from dbo.TrustLedger L
WHERE TLType = 1
	AND NOT EXISTS (
		SELECT C.dboId
		FROM JURIS.TrustDepositsCR C
		WHERE C.MatterId = TLMatter
			AND C.Date = TLDate
			AND C.Credit = TLAmount )

GO

/*================================================
VIEW - All Trust Deposits
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustDeposits]'))
	DROP VIEW [juris].[TrustDeposits]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- All Trust Deposits
CREATE VIEW [juris].[TrustDeposits]
AS

SELECT dboId, 5 AS [TypeId], 'Pay To Account' AS [TransactionType], Bank, Credit, Date, Memo, MatterId, PaymentId--, cbrowindex
FROM JURIS.TrustDepositsCR C
UNION ALL
SELECT dboId, 0 AS [TypeId], 'Deposit' AS [TransactionType], Bank, Credit, Date, Memo, MatterId, NULL AS [PaymentId]--, cbrowindex
FROM JURIS.TrustDepositsWithoutCR

GO


/*================================================
VIEW - Trust transfer details from dual batches
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustTransferDetails]'))
	DROP VIEW [juris].[TrustTransferDetails]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Trust transfers from dual batches
CREATE VIEW [juris].[TrustTransferDetails]
AS

SELECT TABBatchNbr AS [BatchId], TABComment AS [BatchDescription]
	, TABStatus AS [BatchStatusId]
	, CASE TABStatus
		WHEN 'P' THEN 'Posted'
		WHEN 'U' THEN 'Unposted'
		WHEN 'L' THEN 'Locked'
		WHEN 'R' THEN 'Ready to Post'
		WHEN 'D' THEN 'Deleted'
		END AS [BatchStatus]
	, TABUser AS [CreatorId], Ecreator.EMPINITIALS AS [CreatorName]
	, TABDate AS [CreationDate]
	
	, 'TABD-' + CONVERT(varchar(100), rec1.TABDBatch) + '-' + CONVERT(varchar(100), rec1.TABDRecNbr) AS [dboId1]
	, rec1.TABDBank AS [Bank1]
	, rec1.TABDLedgerLink AS [LedgerId1]
	, rec1.TABDMatter AS [Matter1]
	, rec1.TABDDate AS [Date1]
	, CASE WHEN rec1.TABDAmount > 0 THEN rec1.TABDAmount ELSE 0 END AS [Credit1]
	, CASE WHEN rec1.TABDAmount < 0 THEN -rec1.TABDAmount ELSE 0 END AS [Debit1]
	, rec1.TABDMemo AS [Description1]

	
	, 'TABD-' + CONVERT(varchar(100), rec2.TABDBatch) + '-' + CONVERT(varchar(100), rec2.TABDRecNbr) AS [dboId2]
	, rec2.TABDBank AS [Bank2]
	, rec2.TABDLedgerLink AS [LedgerId2]
	, rec2.TABDMatter AS [Matter2]
	, rec2.TABDDate AS [Date2]
	, CASE WHEN rec2.TABDAmount > 0 THEN rec2.TABDAmount ELSE 0 END AS [Credit2]
	, CASE WHEN rec2.TABDAmount < 0 THEN -rec2.TABDAmount ELSE 0 END AS [Debit2]
	, rec2.TABDMemo AS [Description2]
	--, rec1.cbrowindex
FROM dbo.TrAdjBatch
LEFT OUTER JOIN dbo.Employee Ecreator
	ON Ecreator.EmpSysNbr = TABUser
INNER JOIN dbo.TrAdjBatchDetail rec1
	ON rec1.TABDBatch = TABBatchNbr
INNER JOIN dbo.TrAdjBatchDetail rec2
	ON rec2.TABDBatch = TABBatchNbr
	AND rec2.TABDRecNbr > rec1.TABDRecNbr
	AND rec2.TABDAmount * -1 = rec1.TABDAmount
	AND rec2.TABDMatter <> rec1.TABDMatter
	AND rec2.TABDDate = rec1.TABDDate

GO

/*================================================
VIEW - Trust transfers
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustTransfers]'))
	DROP VIEW [juris].[TrustTransfers]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Trust transfers from dual batches
CREATE VIEW [juris].[TrustTransfers]
AS

SELECT dboId1 AS [dboId], 3 AS [TypeId], 'Transfer' AS [TransactionType]
	, Bank1 AS [Bank], Date1 AS [Date], Description1 AS [Memo]
	, Credit1 AS [Credit], Debit1 AS [Debit]
	, Matter1 AS [MatterId], dboId2 AS [LinkedTransaction]
	--, cbrowindex
FROM JURIS.TrustTransferDetails
UNION ALL 
SELECT dboId2 AS [dboId], 3 AS [TypeId], 'Transfer' AS [TransactionType]
	, Bank2 AS [Bank], Date2 AS [Date], Description2 AS [Memo]
	, Credit2 AS [Credit], Debit2 AS [Debit]
	, Matter2 AS [MatterId], dboId1 AS [LinkedTransaction]
	--, cbrowindex
FROM JURIS.TrustTransferDetails

GO

/*================================================
VIEW - Trust adjustments (converted to deposits / disbursements)
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustAdjustments]'))
	DROP VIEW [juris].[TrustAdjustments]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Trust adjustments (converted to deposits / disbursements)
CREATE VIEW [juris].[TrustAdjustments]
AS

SELECT 'TL2-' + CONVERT(varchar(100), TLSysNbr) AS [dboId]
	, CASE WHEN TLAmount > 0 THEN 0 ELSE 1 END AS [TypeId]		-- Positive adjustments are considered deposits
	, CASE WHEN TLAmount > 0 THEN 'Deposit' ELSE 'Disburse Funds' END AS [TransactionType]
	, TLBank AS [Bank], TLDate AS [Date], TLMemo AS [Memo]
	, CASE WHEN TLAmount > 0 THEN TLAmount ELSE 0 END AS [Credit]
	, CASE WHEN TLAmount < 0 THEN -TLAmount ELSE 0 END AS [Debit]
	, TLMatter AS [MatterId]
	--, cbrowindex
FROM dbo.TrustLedger TL
where TLType IN (2)
	AND NOT EXISTS (SELECT * FROM JURIS.TrustTransferDetails WHERE LedgerId1 = TLSysNbr)
	AND NOT EXISTS (SELECT * FROM JURIS.TrustTransferDetails WHERE LedgerId2 = TLSysNbr)

GO

/*================================================
VIEW - Disbursements / invoice payments made from trust
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustChecks]'))
	DROP VIEW [juris].[TrustChecks]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Disbursements / invoice payments made from trust
CREATE VIEW [juris].[TrustChecks]
AS

SELECT 'TL' + CONVERT(varchar(5), TLType) + '-' + CONVERT(varchar(100), TLSysNbr) AS [dboId]
	, 1 AS [TypeId], 'Disburse Funds' AS [TransactionType]
	, TLBank AS [Bank], TLDate AS [Date], TLMemo AS [Memo]
	, CASE WHEN TLAmount > 0 THEN TLAmount ELSE 0 END AS [Credit]
	, CASE WHEN TLAmount < 0 THEN -TLAmount ELSE 0 END AS [Debit]
	, TLMatter AS [MatterId]
	--, cbrowindex
FROM dbo.TrustLedger  
WHERE TLType IN ('3','4','5') 

GO

/*================================================
VIEW - All trust transactions
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustTransactions]'))
	DROP VIEW [juris].[TrustTransactions]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- All trust transactions
CREATE VIEW [juris].[TrustTransactions]
AS

SELECT dboId, TypeId, TransactionType, Bank, Date, Memo
	, Credit, 0 AS [Debit]
	, MatterId, NULL AS [LinkedTransaction], PaymentId
	--, cbrowindex
FROM JURIS.TrustDeposits D
UNION ALL
SELECT dboId, TypeId, TransactionType, Bank, Date, Memo
	, Credit, Debit
	, MatterId, LinkedTransaction, NULL AS [PaymentId]
	--, cbrowindex
FROM JURIS.TrustTransfers
UNION ALL
SELECT dboId, TypeId, TransactionType, Bank, Date, Memo
	, Credit, Debit
	, MatterId, NULL AS [LinkedTransaction], NULL AS [PaymentId]
	--, cbrowindex
FROM JURIS.TrustAdjustments
UNION ALL
SELECT dboId, TypeId, TransactionType, Bank, Date, Memo
	, Credit, Debit
	, MatterId, NULL AS [LinkedTransaction], NULL AS [PaymentId]
	--, cbrowindex
FROM JURIS.TrustChecks

GO

/*================================================
VIEW - All trust transactions - IMPORTABLE
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[TrustTransactionsImport]'))
	DROP VIEW [juris].[TrustTransactionsImport]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--TRUST TRANSACTIONS IMPORTABLE FORMAT - NO NEGATIVE CREDITS OR DEBITS
CREATE VIEW [JURIS].[TrustTransactionsImport]
AS


SELECT TT.dboId
, TT.TypeId
, TT.Bank
, TT.Date
, TT.Memo
, TT.MatterId
, TT.LinkedTransaction
, TT.PaymentId
, CASE WHEN CREDIT>0 AND DEBIT=0 THEN CREDIT WHEN CREDIT < 0 AND DEBIT=0 THEN NULL WHEN DEBIT < 0 AND CREDIT=0 THEN DEBIT*-1 END [CREDIT AMOUNT]
, CASE WHEN DEBIT>0 AND CREDIT=0 THEN DEBIT WHEN DEBIT < 0 AND CREDIT=0 THEN NULL WHEN CREDIT < 0 AND DEBIT=0 THEN CREDIT*-1 END [DEBIT AMOUNT]
, CASE WHEN TRANSACTIONTYPE='TRANSFER' THEN TRANSACTIONTYPE WHEN CREDIT < 0 OR DEBIT > 0 THEN 'Disburse Funds' ELSE 'Deposit' END [TRANSACTION TYPE]
, B.BnkDesc [Imported Bank Account Name]
FROM JURIS.TrustTransactions TT
LEFT JOIN BankAccount B ON TT.Bank=B.BnkCode

GO

/*================================================
VIEW - dbo Users
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[Users]'))
	DROP VIEW [juris].[Users]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- dbo Users
CREATE VIEW [juris].[Users]
AS

SELECT EmpSysNbr AS [otherkey], empinitials AS [username], EmpName AS [fullname]--, cbrowindex
FROM dbo.Employee

GO


/*================================================
VIEW - Payment Distributions Non-Prepaid
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[DistributionsNonPrepaid]'))
	DROP VIEW [juris].[DistributionsNonPrepaid]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- dbo NonPrepaid Distributions
CREATE VIEW [juris].[DistributionsNonPrepaid]
AS

select * from JURIS.DistributionsAll da 
where da.PaymentId not in (select dboid from JURIS.paymentsall where dboid not in (select dboid from JURIS.PrepaidBalances))

GO

/*================================================
VIEW - CLIENTS
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[CLIENTS]'))
	DROP VIEW [juris].CLIENTS
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [juris].CLIENTS
AS

SELECT C.*
, E.EmpInitials [CLIENT BILLING ATTORNEY]
, E2.EmpInitials [CLIENT RESPONSIBLE ATTORNEY]
, PC.PrctClsDesc [PRACTICE AREA]
, BA.BilAdrPhone [BILL TO PHONE NUMBER]
, BA.BilAdrFax [BILL TO FAX NUMBER]
, BA.BilAdrContact [BILL TO CONTACT]
, BA.BilAdrName [BILL TO NAME]
, BA.BilAdrAddress [BILL TO ADDRESS LINES]
, BA.BilAdrCity [BILL TO CITY]
, BA.BilAdrState [BILL TO STATE]
, BA.BilAdrZip [BILL TO ZIP]
, BA.BilAdrCountry [BILL TO COUNTRY]
, BA.BilAdrEmail [BILL TO EMAIL ADDRESS]
, CASE WHEN C.CLIBILLAGREECODE = 'H' THEN 'Hourly' WHEN C.CLIBILLAGREECODE = 'C' THEN 'Contingent' WHEN C.CLIBILLAGREECODE = 'B' THEN 'Pro Bono' WHEN C.CLIBILLAGREECODE = 'N' THEN 'Non-Billable' WHEN C.CliBillAgreeCode = 'F' THEN 'Flat Fee' END AS [FEE ARRANGEMENT]
FROM DBO.Client C
LEFT JOIN Employee E ON C.CliBillingAtty=E.EmpSysNbr
LEFT JOIN Employee E2 ON C.CliRespAtty=E2.EmpSysNbr
LEFT JOIN PracticeClass PC ON C.CliPracticeClass=PC.PrctClsCode
LEFT JOIN BillingAddress BA ON C.CliPrimaryAddr=BA.BilAdrSysNbr

GO




/*================================================
VIEW - MATTERS
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[MATTERS]'))
	DROP VIEW [juris].MATTERS
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [juris].MATTERS
AS



SELECT M.*
, E.EmpInitials [MATTER BILLING ATTORNEY]
, C.CliCode [CLIENT NUMBER]
, RIGHT(MATCODE,5) [MATTER SEQUENCE NUMBER]
, CONCAT(C.CLICODE, '-', RIGHT(MATCODE,5)) [MATTER NUMBER]
, CONCAT(C.CLICODE, '-', RIGHT(MATCODE,5), ' - ', C.CliNickName, ' - ', M.MatNickName) [MATTER NAME]
, PC.PrctClsDesc [PRACTICE CLASS]
, CASE WHEN M.MatStatusFlag='O' THEN 'Open' WHEN M.MatStatusFlag='C' THEN 'Closed' WHEN M.MatStatusFlag='F' THEN 'Final Bill Sent' END [MATTER STATUS]
, CASE WHEN M.MatStatusFlag<>'O' THEN M.MatDateClosed ELSE NULL END [MATTER CLOSE DATE]
, CASE WHEN M.MatBillAgreeCode = 'H' THEN 'Hourly' WHEN m.MatBillAgreeCode = 'C' THEN 'Contingent' WHEN m.MatBillAgreeCode = 'B' THEN 'Pro Bono' WHEN m.MatBillAgreeCode = 'N' THEN 'Non-Billable' WHEN M.MATBILLAGREECODE='F' THEN 'Fixed' ELSE M.MATBILLAGREECODE END AS [FEE ARRANGEMENT]
, BT.BillToBillFormat [BILL FORMAT]
FROM DBO.Matter M
LEFT JOIN BILLTO BT ON M.MatBillTo=BT.BillToSysNbr
LEFT JOIN Employee E ON BT.BillToBillingAtty=E.EmpSysNbr
LEFT JOIN PracticeClass PC ON M.MatPracticeClass=PC.PrctClsCode
JOIN CLIENT C ON M.MatCliNbr=C.CliSysNbr

GO


/*================================================
VIEW - RATE TABLES
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[RateTableDefinitions]'))
	DROP VIEW [juris].RateTableDefinitions
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [juris].RateTableDefinitions
AS



-- RATE TABLE DEFINITIONS THAT ARE EITHER IN CLIENT OR MATTER
select F.FeeSchDesc AS [RateTableName], E.EMPINITIALS AS [UserName], NULL AS [GroupName], R.TKRRate AS [Rate], NULL AS [EffectiveDate]
FROM dbo.FeeSchedule F
INNER JOIN dbo.TkprRate R
    ON R.TKRFeeSch = F.FeeSchCode
INNER JOIN dbo.Employee E
    ON E.EmpSysNbr = R.TKREmp
WHERE EXISTS (SELECT * FROM dbo.Matter M WHERE M.MatFeeSch = F.FeeSchCode)
	OR EXISTS (SELECT * FROM dbo.Client C WHERE C.CliFeeSch = F.FeeSchCode)
UNION ALL
select F.FeeSchDesc AS [RateTableName], NULL AS [UserName], T.PrsTypDesc AS [GroupName], R.PTRRate AS [Rate], NULL AS [EffectiveDate]
FROM dbo.FeeSchedule F
INNER JOIN dbo.PersTypRate R
    ON R.PTRFeeSch = F.FeeSchCode
INNER JOIN dbo.PersonnelType T
    ON T.PrsTypCode = R.PTRPrsTyp
WHERE EXISTS (SELECT * FROM dbo.Matter M WHERE M.MatFeeSch = F.FeeSchCode)
	OR EXISTS (SELECT * FROM dbo.Client C WHERE C.CliFeeSch = F.FeeSchCode)


GO


/*================================================
VIEW - RATE TABLES - MATTERS
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[MatterRateTables]'))
	DROP VIEW [juris].MatterRateTables
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [juris].MatterRateTables
AS


-- MATTER RATE TABLES
SELECT M.matsysnbr AS [ImportID], F.FeeSchDesc AS [RateTableName]
FROM dbo.Matter M
inner JOIN dbo.FeeSchedule F
    oN F.FeeSchCode = M.MatFeeSch



GO


/*================================================
VIEW - RATE TABLES - CLIENTS
=================================================*/
IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[juris].[ClientRateTables]'))
	DROP VIEW [juris].ClientRateTables
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [juris].ClientRateTables
AS


-- CLIENT RATE TABLES
SELECT C.CliSysNbr AS [ImportID], F.FeeSchDesc AS [RateTableName]
FROM dbo.Client C
inner JOIN dbo.FeeSchedule F
    oN F.FeeSchCode = C.CliFeeSch

GO