--SELECT * FROM dbo.ObjectItems I WHERE I.objecttype in (48,47,30) AND I.lookuptype = 3
--30	Bills	3004	Client
--47	Credits	4833	Client
--48	Payments	4833	Client

DECLARE @clientLookup int
SELECT @clientLookup = s.val FROM dbo.MesaSysSettings S WHERE S.[desc] = 'BillableClientLookup'

DECLARE @blankid uniqueidentifier = NEWID()

IF (OBJECT_ID('tempdb..#PaymentIds') IS NOT NULL)
	DROP TABLE #PaymentIds
	
CREATE TABLE #PaymentIds (
	paymentid uniqueidentifier
	, clientToSet uniqueidentifier
	, PRIMARY KEY (paymentid)		-- Gives faster performance for various join operations
	, UNIQUE (paymentid))
		
INSERT INTO #PaymentIds
(paymentid, clientToSet)
SELECT P.paymentid, Lmatclient.objectid
FROM dbo.BillingPayments P
INNER JOIN dbo.ObjectLookups Lmatclient
	ON Lmatclient.parentid = P.billableid
	AND Lmatclient.itemtype = @clientLookup
WHERE ISNULL(P.companyid, @blankid) <> Lmatclient.objectid

UPDATE Lpayclient SET objectid = clientToSet
--SELECT *
FROM #PaymentIds T
INNER JOIN dbo.ObjectLookups Lpayclient
	ON Lpayclient.parentid = T.paymentid
	AND Lpayclient.itemtype = 4833

INSERT INTO dbo.ObjectLookups
(parentid, itemtype, objectid)
SELECT T.paymentid, 4833, t.clientToSet
FROM #PaymentIds T
WHERE NOT EXISTS (SELECT * FROM dbo.ObjectLookups Lpayclient WHERE Lpayclient.parentid = T.paymentid AND Lpayclient.itemtype = 4833)

INSERT INTO dbo.ObjectXRef
(objectid1, type1, objectid2, type2)
SELECT O1.objectid, O1.type, O2.objectid, O2.type
FROM #PaymentIds T
INNER JOIN dbo.Objects O1
	ON O1.objectid = T.paymentid
INNER JOIN dbo.Objects O2
	ON O2.objectid = T.clientToSet
WHERE   NOT EXISTS (SELECT * FROM dbo.ObjectXRef X WHERE X.objectid1 = O1.objectid AND X.objectid2 = O2.objectid)
	AND NOT EXISTS (SELECT * FROM dbo.ObjectXRef X WHERE X.objectid2 = O1.objectid AND X.objectid1 = O2.objectid)

IF (EXISTS(SELECT * FROM #PaymentIds))
	EXEC DBO.cb_BillingPayments_InsertUpdate


IF (OBJECT_ID('tempdb..#InvoiceIds') IS NOT NULL)
	DROP TABLE #InvoiceIds
	
CREATE TABLE #InvoiceIds (
	invoiceid uniqueidentifier
	, clientToSet uniqueidentifier
	, PRIMARY KEY (invoiceid)		-- Gives faster performance for various join operations
	, UNIQUE (invoiceid))
	
INSERT INTO #InvoiceIds
(invoiceid, clientToSet)
SELECT i.invoiceid, Lmatclient.objectid
FROM dbo.BillingInvoices I
INNER JOIN dbo.ObjectLookups Lmatclient
	ON Lmatclient.parentid = I.billableid
	AND Lmatclient.itemtype = @clientLookup
WHERE ISNULL(I.companyid, @blankid) <> Lmatclient.objectid


UPDATE Lbillclient SET objectid = clientToSet
--SELECT *
FROM #InvoiceIds T
INNER JOIN dbo.ObjectLookups Lbillclient
	ON Lbillclient.parentid = T.invoiceid
	AND Lbillclient.itemtype = 3004

INSERT INTO dbo.ObjectLookups
(parentid, itemtype, objectid)
SELECT T.invoiceid, 3004, t.clientToSet
FROM #InvoiceIds T
WHERE NOT EXISTS (SELECT * FROM dbo.ObjectLookups Lbillclient WHERE Lbillclient.parentid = T.invoiceid AND Lbillclient.itemtype = 3004)

INSERT INTO dbo.ObjectXRef
(objectid1, type1, objectid2, type2)
SELECT O1.objectid, O1.type, O2.objectid, O2.type
FROM #InvoiceIds T
INNER JOIN dbo.Objects O1
	ON O1.objectid = T.invoiceid
INNER JOIN dbo.Objects O2
	ON O2.objectid = T.clientToSet
WHERE   NOT EXISTS (SELECT * FROM dbo.ObjectXRef X WHERE X.objectid1 = O1.objectid AND X.objectid2 = O2.objectid)
	AND NOT EXISTS (SELECT * FROM dbo.ObjectXRef X WHERE X.objectid2 = O1.objectid AND X.objectid1 = O2.objectid)

IF (EXISTS(SELECT * FROM #InvoiceIds))
	EXEC DBO.cb_BillingInvoices_InsertUpdate_Step2


DROP TABLE #PaymentIds
DROP TABLE #InvoiceIds