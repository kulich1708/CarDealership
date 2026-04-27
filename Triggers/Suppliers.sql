DROP TRIGGER IF EXISTS TR_Suppliers_Delete
GO
CREATE TRIGGER TR_Suppliers_Delete
ON Suppliers INSTEAD OF DELETE AS 
BEGIN 
	SET NOCOUNT ON;
	
    BEGIN TRY
		BEGIN TRANSACTION;
		DELETE FROM SupplierOrders
		WHERE SupplierId IN (SELECT SupplierId FROM deleted);
		
		DELETE FROM Suppliers
		WHERE SupplierId IN (SELECT SupplierId FROM deleted);
	
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO
