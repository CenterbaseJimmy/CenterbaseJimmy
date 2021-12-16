SELECT * FROM baseqry

--validorders=ABCDMRIOSVTE    
Select u.CLT_CODE,u.MAT_CODE,u.NAME,u.BILL_ATTY,   u.ORDER_BY, u.OFF_CODE,u.RESP_ATTY,u.INIT_ATTY,u.CLASS,   b.[Date] as Date  , d.Ref_Code as Ref_Code  , '(Select Order_by from Client c Where  c.Clt_Code = u.Clt_Code)' as clt_order  , '(Select Order_by from Atty Where Atty_code = u.Bill_Atty)' as BAttyOrderBy  , '(Select Order_by from Atty Where Atty_code = u.Init_Atty)' as IAttyOrderBy  , '(Select Order_by from Atty Where Atty_code = u.Resp_Atty)' as RAttyOrderBy  , '(Select Order_by from Atty Where Atty_code = d.ref_code)' as WkgAttyOrderBy  ,   b.BILL_CODE,   b.DESCRIP,b.BILL_NUM,   sum(d.BILL_AMT) as TotalBilled,   sum(case when d.type='F' then d.BILL_AMT else 0 end) as FeeBilled,   sum(case when d.type='E' then d.BILL_AMT else 0 end) as ExpBilled,   sum(d.REL_AMT) as TotalRelieved,   sum(case when d.type='F' then d.REL_AMT else 0 end) as FeeRelieved,   sum(case when d.type='E' then d.REL_AMT else 0 end) as ExpRelieved,   sum(d.DUE_AMT) as TotalDue,   sum(case when d.type='F' then d.DUE_AMT else 0 end) as FeeDue,   sum(case when d.type='E' then d.DUE_AMT else 0 end) as ExpDue    , 0 as SpareV1  , 0 as SpareV2  , 0 as SpareV3  , '         ' as SpareT1  , '         ' as SpareT2  , '         ' as SpareT3  , 'Matter,WriteOff,WOFDetl' as FT /* From Table */  , 1 as SA /* Section Area */  , 'Billed' as UAD /* Union Area Description */  , 1 as UA /* 'Union Area' */      from matter U,bill b, billdetl d, client c     where u.clt_code = b.clt_code and u.mat_code =b.mat_code   and u.clt_code = c.clt_code   and b.date >= :p2 and b.date <= :p3   and b.BILL_CODE = d.BILL_CODE  --filter  --tefilter  --tfilterr  --efilterr    group by u.CLT_CODE,u.MAT_CODE,u.NAME,u.BILL_ATTY,   u.ORDER_BY, u.OFF_CODE,u.RESP_ATTY,u.INIT_ATTY,u.CLASS,   b.DATE,b.BILL_CODE,c.ORDER_BY,   b.DESCRIP,b.BILL_NUM, d.ref_Code    order by u.Bill_Atty, u.Clt_Code,u.Mat_Code

select * from matter

SELECT * FROM Invoices

SELECT SUM(AMOUNT) FROM Invoices

SELECT * FROM inv

SELECT * FROM invdetl

SELECT SUM(FEE_AMT+EXP_AMT+TAX_AMT-PPD_APPL-TRUST_APPL) FROM postbill

SELECT * FROM billdetl

SELECT SUM(DUE_AMT) FROM billdetl

SELECT SUM(INVOICEBALANCE) FROM PL.CB_Bills
WHERE InvoiceBalance>=0
AND InvoiceTotal>=0

SELECT * FROM PL.CB_Bills
WHERE InvoiceBalance>=0
AND InvoiceTotal>=0

SELECT * FROM bill

SELECT * FROM BILL

SELECT * FROM PL.CB_Bills
WHERE InvoiceTotal<0 

SELECT * FROM PARTY
WHERE rec_num<>''

SELECT SUM(DOL_VALUE) FROM TIME
WHERE on_bill=0
AND BILLABLE=1

SELECT * FROM time

SELECT * FROM disburse

SELECT * FROM expense

SELECT * FROM relparty

SELECT * FROM dparty

SELECT * FROM partytext

SELECT * FROM expdetl

SELECT * FROM CMCodeName

SELECT * FROM client

SELECT CLT_CODE, COUNT(*)
FROM CLIENT
GROUP BY clt_code
HAVING COUNT(*)<>1

SELECT MROW_ID, COUNT(*)
FROM MATTER
GROUP BY mrow_id
HAVING COUNT(*)<>1

SELECT * FROM time

SELECT * FROM atty

SELECT * FROM MatterBillAddrBlocks

SELECT * FROM address
WHERE addr_code LIKE '%11C4670%'

SELECT * FROM time

SELECT * FROM CLTMGRCO
WHERE mat_code LIKE '%15U8510%'

SELECT * FROM matter
where mrow_id is null

SELECT * FROM ClientMatterQuickSearch

SELECT MAX(MAT_CODE) FROM matter
WHERE MAT_CODE<>'TEST'


SELECT * FROM PL.UNBILLEDTIME
WHERE on_bill=0

SELECT SUM([BILLABLE VALUE]), SUM([ACTUAL VALUE]) FROM PL.UNBILLEDTIME
WHERE BILLABLE=1

SELECT 1090126.00 - 1089811.50

SELECT * FROM PL.UnbilledTime UT
WHERE UT.[ACTUAL VALUE]<>UT.[BILLABLE VALUE]

SELECT SUM(DOL_VALUE) FROM TIME
WHERE on_bill=0
AND BILLABLE=1

SELECT * FROM PL.UnbilledTime

SELECT * FROM PL.UnbilledTime UT
WHERE UT.[Is Non Billable]='FALSE' AND billable=0

SELECT SUM([BILLABLE VALUE]), SUM([ACTUAL VALUE]) FROM PL.UnbilledExpenses

SELECT * FROM PL.UnbilledExpenses

SELECT *
, CASE WHEN exp_type=1 THEN 'Hard Cost' WHEN exp_type=2 THEN 'Soft Cost' ELSE NULL END [EXPENSE TYPE]
, CASE WHEN exp_code LIKE '%E[0-9][0-9][0-9]%' THEN exp_code END [LEDES CODE]
FROM expense




SELECT SUM(ORIG_VALUE), SUM(DOL_VALUE) FROM time
WHERE BILLABLE=1


SELECT * FROM TIME

SELECT * FROM rec

SELECT * FROM recdetl

SELECT * FROM writeoff

SELECT * FROM wofdetl

SELECT P.PaymentId, P.Amount, SUM(PD.AMOUNT)
FROM PL.CB_PaymentDistributions PD
JOIN PL.CB_Payments P
	ON PD.PaymentId=P.PaymentId
GROUP BY P.PaymentId, P.Amount
HAVING SUM(PD.AMOUNT)<>P.Amount

SELECT 
B.InvoiceTotal-B.InvoiceBalance [AMOUNTPAID]
, B.BillId
, SUM(PD.AMOUNT) [AMTSUM]
FROM PL.CB_PaymentDistributions PD
JOIN PL.CB_Bills B
	ON PD.BillId=B.BillId
GROUP BY B.InvoiceTotal-B.InvoiceBalance
, B.BillId
HAVING SUM(PD.AMOUNT)<>B.InvoiceTotal-B.InvoiceBalance



SELECT pd.* FROM PL.CB_PaymentDistributions PD
LEFT JOIN PL.CB_Bills B ON PD.BillId=B.BillId
WHERE B.BillId IS NULL

SELECT DISTINCT PD.* FROM PL.CB_PaymentDistributions PD
JOIN PL.CB_Bills B 
	ON PD.BillId=B.BillId
JOIN PL.CB_Matters M 
	ON PD.MatterId=M.MatterID
JOIN PL.CB_Payments P 
	ON PD.PaymentId=P.PaymentId
WHERE InvoiceBalance>=0
AND InvoiceTotal>=0
AND PD.PAYMENTID='165814'

SELECT * FROM PL.CB_Payments
WHERE MatterId IS NULL


SELECT PD.PaymentId, COUNT(*) FROM PL.CB_PaymentDistributions PD
JOIN PL.CB_Bills B 
	ON PD.BillId=B.BillId
JOIN PL.CB_Matters M 
	ON PD.MatterId=M.MatterID
JOIN PL.CB_Payments P 
	ON PD.PaymentId=P.PaymentId
WHERE InvoiceBalance>=0
AND InvoiceTotal>=0
GROUP BY PD.PaymentId
HAVING COUNT(*)<>1


SELECT BILLID, COUNT(*) FROM PL.CB_Bills
GROUP BY BILLID
HAVING COUNT(*)<>1

SELECT * FROM PL.CB_Bills B
WHERE B.BillId='11V5809'



SELECT * FROM trust

SELECT * FROM acctdetl


SELECT SUM(CREDIT)-SUM(DEBIT) FROM PL.CB_TrustTransactions


SELECT * FROM PL.CB_CHARTOFACCOUNTS



SELECT SUM([BILLABLE VALUE]) FROM PL.UnbilledExpenses

SELECT * FROM PL.UnbilledExpenses

SELECT * FROM PL.UnbilledExpenses E
JOIN PL.UnbilledTime T ON E.event_code=T.event_code


SELECT * FROM PL.UnbilledExpenses
ORDER BY DATE DESC

SELECT 13322.30 - 13305.84


SELECT BILL_CODE, SUM([BILLABLE VALUE]) [FEE SUM]
FROM PL.BilledTime
GROUP BY bill_code

SELECT BILL_CODE, SUM([BILLABLE VALUE]) [EXPENSE SUM]
FROM PL.BilledExpenses
GROUP BY bill_code



SELECT BILLID, SUM(AMOUNT) [AMOUNT PAID] 
FROM PL.CB_PaymentDistributions PD
GROUP BY BillId

SELECT BILLID, SUM(AMOUNT) [AMOUNT CREDITED]
FROM PL.CB_CreditDistributions CD
GROUP BY BillId

SELECT * FROM PL.BilledExpenses


SELECT B.*
, T.[FEE SUM]
, E.[EXPENSE SUM]
, P.[AMOUNT PAID]
, C.[AMOUNT CREDITED]
, ISNULL([FEE SUM],0) + ISNULL([EXPENSE SUM],0) - ISNULL([AMOUNT PAID],0) - ISNULL([AMOUNT CREDITED],0) - ISNULL(W.WUDFEES*-1,0) [CALCULATED BALANCE]
, B.InvoiceBalance - (ISNULL([FEE SUM],0) + ISNULL([EXPENSE SUM],0) - ISNULL([AMOUNT PAID],0) - ISNULL([AMOUNT CREDITED],0) - ISNULL(W.WUDFEES*-1,0)) [REQUIRED ADJUSTMENT AMOUNT]
, W.WUD
, W.WUDfees
, W.WUDexps
FROM PL.CB_Bills B
LEFT JOIN (
	SELECT BILL_CODE, SUM([BILLABLE VALUE]) [FEE SUM]
	FROM PL.BilledTime
	WHERE billable=1
	GROUP BY bill_code
) T 
	ON B.BillId=T.bill_code
LEFT JOIN (
	SELECT BILL_CODE, SUM([BILLABLE VALUE]) [EXPENSE SUM]
	FROM PL.BilledExpenses
	GROUP BY bill_code
) E 
	ON B.BillId=E.BILL_CODE
LEFT JOIN (
	SELECT BILLID, SUM(AMOUNT) [AMOUNT PAID] 
	FROM PL.CB_PaymentDistributions PD
	GROUP BY BillId
) P
	ON B.BillId=P.BillId
LEFT JOIN (
	SELECT BILLID, SUM(AMOUNT) [AMOUNT CREDITED]
	FROM PL.CB_CreditDistributions CD
	GROUP BY BillId
) C
	ON B.BillId=C.BillId
LEFT JOIN (
	SELECT ID_CODE, WUD, WUDfees, WUDexps
	FROM BillsNRecs 
) W
	ON B.BillId=W.id_code
WHERE B.InvoiceBalance - (ISNULL([FEE SUM],0) + ISNULL([EXPENSE SUM],0) - ISNULL([AMOUNT PAID],0) - ISNULL([AMOUNT CREDITED],0) - ISNULL(W.WUDFEES*-1,0)) <> 0
--B.InvoiceTotal-B.InvoiceBalance<>ISNULL([AMOUNT PAID],0) + ISNULL([AMOUNT CREDITED],0)
--AND B.InvoiceBalance - (ISNULL([FEE SUM],0) + ISNULL([EXPENSE SUM],0) - ISNULL([AMOUNT PAID],0) - ISNULL([AMOUNT CREDITED],0)) <> W.WUDfees
--AND B.BillId='15P2130'
AND BillNumber<>0
ORDER BY ISSUEDATE DESC


SELECT * FROM atty

SELECT attY_CODE [Username], NAME [FullName]
FROM atty


SELECT * FROM PL.CB_Bills
WHERE BillId='1652729'

SELECT * FROM TimeTran
WHERE Bill_Code='1652729'

--SELECT * FROM CostTran
--WHERE bill_num='15P2130'

SELECT * FROM PL.BilledExpenses
WHERE bill_code='1652729'

SELECT * FROM billdetl
WHERE Bill_Code='1652729'

SELECT * FROM BillsNRecs
WHERE id_code='1652729'

SELECT *
,[BILLABLE HOURS]*[BILLABLE RATE]
FROM PL.BilledTime
WHERE [BILLABLE HOURS]*[BILLABLE RATE]<>[BILLABLE VALUE]
AND billable=1

SELECT *
,[BILLABLE QUANTITY]*[BILLABLE RATE]
 FROM PL.BilledExpenses
WHERE [BILLABLE QUANTITY]*[BILLABLE RATE]<>[BILLABLE VALUE]

SELECT BT.* FROM PL.BilledTime BT
JOIN PL.CB_Bills B 
	ON BT.bill_code=B.BillId
JOIN PL.CB_Matters M
	ON BT.MatterID=M.MatterID

SELECT BE.* FROM PL.BilledExpenses BE
JOIN PL.CB_Bills B 
	ON BE.bill_code=B.BillId
JOIN PL.CB_Matters M
	ON BE.MatterID=M.MatterID

SELECT *
, DISCOUNT*-1 [ADJUSTMENT AMOUNT]
FROM PL.CB_Bills
WHERE DISCOUNT<0

SELECT * FROM PL.CB_Bills WHERE DISCOUNT>0

SELECT B.*
FROM PL.CB_Bills B
LEFT JOIN PL.BILLS_REMOVEDISCOUNT RD 
	ON B.BillId=RD.BillId
WHERE B.Discount>0
AND RD.BillId IS NULL

SELECT * FROM PL.CB_Matters

SELECT DISTINCT BILL_CODE FROM TimeTran
WHERE Bill_Code NOT IN (SELECT DISTINCT BILL_CODE FROM PL.BilledTime)

SELECT * FROM PL.BilledTime BT
WHERE BT.bill_code='1011287'

SELECT * FROM PL.BilledExpenses

SELECT * FROM CostTran


SELECT * FROM BillsNRecs


SELECT * FROM datadict

SELECT * FROM dataclas

SELECT * FROM elecdata

SELECT * FROM tbdata

SELECT * FROM viedata

SELECT * FROM utime

SELECT * FROM autime



SELECT * FROM class

SELECT * FROM office

SELECT * FROM matter

SELECT * FROM PL.CB_Matters

SELECT * FROM PL.CB_Contacts

SELECT * FROM client

SELECT * FROM party

SELECT DISTINCT [FEE CREDITS] FROM PL.CB_Matters
WHERE [FEE CREDITS] LIKE '%50%'


SELECT DISTINCT [FEE CREDITS] FROM PL.CB_Matters
ORDER BY [FEE CREDITS] ASC




SELECT * FROM NOTES

SELECT * FROM notesrel

SELECT * FROM notetype

SELECT * FROM ccltnote

SELECT * FROM matnotes

SELECT * FROM notesx

SELECT * FROM svdnotes

SELECT * FROM company

SELECT * FROM PL.CB_Matters
WHERE BILLABLE<>1


SELECT * FROM matter
WHERE BILLABLE<>1


SELECT * FROM ReferralParties

SELECT * FROM PARTY


SELECT * FROM PL.CB_RelatedParties
WHERE [Party Name] LIKE '%LEISTER%'

SELECT DISTINCT [FEE ARRANGEMENT] FROM PL.CB_Matters

SELECT * FROM PL.CB_RelatedParties_Matter

SELECT DISTINCT office FROM PL.CB_Matters




SELECT MATTERID, COUNT(*) FROM (
SELECT PM.* FROM PL.CB_RelatedParties_Matter PM
JOIN PL.CB_RelatedParties RP 
	ON PM.PartyId=RP.PartyId
WHERE RP.beeperph='REF'
) A GROUP BY MATTERID HAVING COUNT(*)<>1

SELECT * FROM party
WHERE email_addr LIKE '%KLETT%'

SELECT * FROM PARTY
WHERE name LIKE '%LEISTER%'

SELECT DISTINCT EMPLOYER, email_addr FROM PARTY


SELECT * FROM client

SELECT * FROM PL.CB_Contacts

SELECT * FROM PL.CB_ChartOfAccountsimport

SELECT * FROM PL.CB_TrustTransactions


SELECT *
, REPLACE(REPLACE([PARTY NAME],'<',''),'>','') [FIXEDNAME]
FROM PL.CB_RelatedParties WHERE PARTYID IN




('1616216','1166483','14S9682','10Q7785','1616148','10U0920','10Q1004','10Q1007','10S3424','1070242','1024048','10U0282','10R9274','10S6328')





SELECT * FROM client
WHERE NAME LIKE '%COWMAN%'

SELECT * FROM CLIENT WHERE clt_code LIKE '%11859       %'

SELECT * FROM gbclient

SELECT * FROM PL.CB_RelatedParties

SELECT * FROM party
WHERE NAME LIKE '%COWMAN%'

SELECT * FROM relparty
WHERE RELATED LIKE '%14S4681%'

SELECT 
 P.name
 , P.party_code
, C.name
,RP.*
FROM relparty RP
JOIN CLIENT C
	ON RP.clt_code=C.clt_code
JOIN PARTY P
	ON P.event_code=RP.related
WHERE RELATED='    451'


SELECT 
 P.name
 , P.party_code
, C.name
,RP.*
FROM relparty RP
JOIN CLIENT C
	ON RP.clt_code=C.clt_code
JOIN PARTY P
	ON P.event_code=RP.related
WHERE REL_CODE='REFERRAL  '

SELECT DISTINCT REL_CODE FROM relparty



SELECT DISTINCT RP.rel_data1 FROM relparty RP
JOIN PARTY P
	ON RP.related=P.event_code
--WHERE P.name LIKE '%SEARCH ENGINE%'



SELECT * FROM PARTY P WHERE P.NAME LIKE '%SEARCH ENGINE%'

SELECT RELATED, COUNT(*) FROM relparty
GROUP BY RELATED
HAVING COUNT(*)<>1

SELECT * FROM relparty WHERE RELATED='    451'

SELECT * FROM PARTY P

SELECT * FROM relparty RP
WHERE RP.rel_code='REFERRAL  '


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




SELECT DISTINCT EVENT_CODE FROM (
SELECT 
P.name
, P.party_code
, P.event_code
, RP.*
--, M.mrow_id [MATTER ID]
FROM relparty RP
JOIN PARTY P
	ON P.event_code=RP.related
--INNER JOIN matter M
--	ON M.clt_code = RP.clt_code
--	AND M.mat_code = RP.mat_code
WHERE REL_CODE='REFERRAL  '
) A

SELECT DISTINCT P.*, RP.rel_data1 
--P.name
--, P.party_code
--, P.event_code
--, RP.*
--, M.mrow_id [MATTER ID]
FROM relparty RP
JOIN PARTY P
	ON P.event_code=RP.related
--INNER JOIN matter M
--	ON M.clt_code = RP.clt_code
--	AND M.mat_code = RP.mat_code
WHERE REL_CODE='REFERRAL  '


SELECT EVENT_CODE, COUNT(*) FROM (
SELECT DISTINCT P.event_code
, RP.rel_data1
FROM party P
JOIN relparty RP
	ON P.event_code=RP.related
WHERE REL_CODE='REFERRAL  '
) A
GROUP BY A.event_code
HAVING COUNT(*)<>1



SELECT EVENT_CODE, COUNT(*) FROM PARTY GROUP BY EVENT_CODE HAVING COUNT(*)<>1




SELECT * FROM party

--REFERRAL PARTIES
SELECT P1.*
, M.mrow_id [MATTER ID]
, RP1.rel_data1
FROM PARTY P1 
JOIN relparty RP1
	ON P1.event_code=RP1.related
JOIN matter M
	ON M.clt_code = RP1.clt_code
	AND M.mat_code = RP1.mat_code
WHERE P1.event_code IN (
SELECT DISTINCT P.event_code FROM relparty RP
JOIN PARTY P
	ON RP.related=P.event_code
WHERE REL_CODE='REFERRAL  '
)
AND RP1.rel_code='REFERRAL  '
AND TRIM(county)<>''

SELECT distinct REL_DATA1 FROM (
--REFERRALS
SELECT RP.*
, M.mrow_id [MATTERID]
FROM relparty RP
JOIN PARTY P
	ON RP.related=P.event_code
JOIN matter M
	ON M.clt_code = RP.clt_code
	AND M.mat_code = RP.mat_code
WHERE REL_CODE='REFERRAL  '
) A
GROUP BY A.MATTERID HAVING COUNT(*)<>1



SELECT * FROM PL.CB_Contacts

SELECT * FROM PL.CB_Matters

SELECT * FROM company

SELECT * FROM client

SELECT * FROM party




SELECT * FROM client

SELECT * FROM gbclient

SELECT * FROM PL.CB_Rates

SELECT * FROM PL.CB_SetRates

SELECT * FROM PL.CB_SetRateExceptions


SELECT * FROM PL.CB_VendorBills



SELECT * FROM PL.CB_ChartOfAccountsImport

SELECT * FROM atty

SELECT * FROM PL.CB_Matters

2549258.01

SELECT SUM(CREDIT)-SUM(DEBIT) FROM PL.CB_TrustTransactions

SELECT * FROM PL.CB_TrustTransactions
WHERE CREDIT<0 OR DEBIT<0

SELECT * FROM trust

SELECT * FROM account

SELECT SUM(INVOICEBALANCE) FROM PL.CB_Bills

SELECT * FROM PL.CB_Bills

SELECT * FROM PL.importBilledTime BT
WHERE BT.[BILLABLE HOURS]*BT.[BILLABLE RATE]
SELECT * FROM PL.importBilledExpenses BE

SELECT BT.* 
INTO PL.importBilledTime
FROM PL.BilledTime BT
JOIN PL.CB_Bills B
	ON BT.bill_code=B.BillId

SELECT BE.* 
INTO PL.importBilledExpenses
FROM PL.BilledExpenses BE
JOIN PL.CB_Bills B
	ON BE.bill_code=B.BillId



SELECT * FROM archivet
WHERE bill_code IS NULL


SELECT * FROM archive

SELECT * FROM PL.CB_Matters

SELECT * FROM PL.CB_Payments


SELECT * FROM PL.CB_Credits

SELECT *
, ROW_NUMBER() OVER ( ORDER BY BILLID, DATE) [ROWNUMBER]
FROM PL.CB_CreditDistributions

SELECT * FROM PL.CB_VendorBills



SELECT * FROM inv

SELECT * FROM Invoices

SELECT * FROM ALLInvDt



SELECT * FROM PL.BilledExpenses

SELECT * FROM archived


SELECT * FROM matter
WHERE clt_code LIKE '%1667%'

SELECT * FROM party
WHERE party_code LIKE '%todd king%'


--35220 TOTAL
--14010 INVALID ADDRESS
--21210 VALID

--use 31 dec 2020
SELECT *
, CASE WHEN (TRY_CONVERT(DATETIME, CONTACTDAT) IS NULL OR TRY_CONVERT(DATETIME, CONTACTDAT)=CONVERT(DATETIME,'1900-01-01 00:00:00.000')) THEN CONVERT(DATETIME,'2020-12-31 00:00:00.000') ELSE TRY_CONVERT(DATETIME, CONTACTDAT) END [CONTACT DATE AS DATE]
FROM CLTMGRCO
WHERE (TRY_CONVERT(DATETIME, CONTACTDAT) IS NULL OR TRY_CONVERT(DATETIME, CONTACTDAT)=CONVERT(DATETIME,'1900-01-01 00:00:00.000'))

SELECT rec_num, COUNT(*) 
FROM CLTMGRCO
GROUP BY rec_num
HAVING COUNT(*)<>1

SELECT * FROM CLTMGRCO
WHERE rec_num IS NULL


SELECT * FROM matter
WHERE CLOSED IS NOT NULL

SELECT * FROM PL.CB_Matters
WHERE [Matter Number] LIKE '%14067%'

SELECT * FROM PL.UnbilledExpenses

SELECT *
, 'c/o Hayley Collins Blair' [USE THIS ADDRESS1]
FROM PL.CB_Matters
WHERE [Address 1]='c/o Hayley Collins'

SELECT * FROM PL.CB_Payments P
JOIN PL.CB_Contacts C
	ON P.ClientId=C.ClientId
WHERE [Client Name] LIKE '%CHABAN%'
ORDER BY DATE DESC

SELECT * FROM PL.CB_Payments P
JOIN PL.CB_Contacts C
	ON P.ClientId=C.ClientId
WHERE [Client Name] LIKE '%Christl%'
ORDER BY DATE DESC

SELECT * FROM PL.CB_Payments P
JOIN PL.CB_Contacts C
	ON P.ClientId=C.ClientId
WHERE [Client Name] LIKE '%turner%'
ORDER BY DATE DESC




SELECT * FROM recdetl
WHERE rec_code='16B0283'

SELECT SUM(REC_AMT) FROM (
	SELECT R.*, RD.rec_amt, M.MatterID 
	, CASE WHEN RD.rec_amt >= 0 THEN RD.rec_amt END [CREDIT]
	, CASE WHEN RD.rec_amt < 0 THEN RD.rec_amt*-1 END [DEBIT]
	, CASE WHEN RD.rec_amt>=0 THEN 'Deposit' ELSE 'Disburse Funds' END [TYPE]
	FROM recdetl RD
	JOIN REC R
		ON RD.rec_code=R.rec_code
	JOIN PL.CB_Matters M
		ON R.clt_code=M.CLT_CODE AND R.mat_code=M.mat_code
	WHERE bill_code IS NULL
	AND post_code IS NULL
) A

SELECT * FROM rec

SELECT SUM(REC_AMT) FROM recdetl RD
JOIN REC R
	ON RD.rec_code=R.rec_code
WHERE bill_code IS NULL
AND post_code IS NULL
AND reversed=0

SELECT * FROM recdetl RD
JOIN REC R
	ON RD.rec_code=R.rec_code
WHERE bill_code IS NULL
AND post_code IS NULL
AND rec_amt<0


SELECT * FROM PL.CB_Matters



SELECT M.clt_code [PL Clt_Code], M.mat_code [PL Mat_Code]
, M2.[Matter Number]				[CB Matter Number]
, M2.[Client Number]				[CB Client Number]
, M2.[Matter Sequence Number]	[CB Matter Sequence Number]
, M2.MatterID
FROM matter M
JOIN PL.CB_Matters M2
	ON M.mrow_id=M2.MatterID




SELECT * FROM (
--REFERRAL PARTIES
SELECT P1.*
, M.mrow_id [MATTER ID]
, RP1.rel_data1
FROM PARTY P1 
JOIN relparty RP1
	ON P1.event_code=RP1.related
JOIN matter M
	ON M.clt_code = RP1.clt_code
	AND M.mat_code = RP1.mat_code
WHERE P1.event_code IN (
SELECT DISTINCT P.event_code FROM relparty RP
JOIN PARTY P
	ON RP.related=P.event_code
WHERE REL_CODE='REFERRAL  '
)
AND RP1.rel_code='REFERRAL  '
) A
WHERE A.party_code LIKE '%NOT SPE%'


SELECT DISTINCT specialty FROM PARTY	
WHERE TRIM(specialty) NOT LIKE '% %'

SELECT * FROM PL.CB_Contacts
WHERE [Client Name]
LIKE '%,%'

SELECT * FROM PL.CB_Matters

SELECT * FROM PL.CB_RelatedParties
WHERE [Party Name] LIKE '%BEAUCHAMP, SCOTT%'


SELECT * FROM PARTY
WHERE party_code LIKE '%BEAUCHAMP, SCOTT%'



SELECT * FROM PL.CB_Vendors

SELECT DISTINCT FORM_1099 FROM PL.CB_VendorS

SELECT * FROM vendor

SELECT * FROM vendloc

