--SELECT * FROM imports order by rundate desc



--exec cb_Billing_Populate
--exec cb_Billing_Populate '5451F228-CDB6-4CA4-AF17-B4CD2E3DE583'


/*=== If Error Out Use Below ===*/
--REVERT
--DECLARE @sqllogin sysname
--SELECT @sqllogin = U.sqllogin FROM dbo.UserView U WHERE U.userid = 'A3F13D51-9F5A-4088-BF5E-F701CD31BC59'
--EXECUTE AS LOGIN = @sqllogin
--EXEC cb_Billing_Populate

--exec cb_BillingPaymentDistributions_AutoAllocatePaymentsAndCredits

--SELECT * FROM Accounting_Accounts order by accountname	
