/*

REVERT
DECLARE @sqllogin sysname
SELECT @sqllogin = U.sqllogin FROM dbo.UserView U WHERE U.userid = 'A3F13D51-9F5A-4088-BF5E-F701CD31BC59'
EXECUTE AS LOGIN = @sqllogin
EXEC DBO.cb_BillingInvoices_UnPostAllInvoices

*/

/*

REVERT
DECLARE @sqllogin sysname
SELECT @sqllogin = U.sqllogin FROM dbo.UserView U WHERE U.userid = 'A3F13D51-9F5A-4088-BF5E-F701CD31BC59'
EXECUTE AS LOGIN = @sqllogin
EXEC dbo.cb_BillingInvoices_PostAllInvoices

*/