/*=====================================================================*
  0)  SWITCH TO AdventureWorks2022
 *=====================================================================*/
USE AdventureWorks2022;
GO


/*=====================================================================*
  0‑B)  DROP ANY OLD COPIES (ALL SCHEMAS)
 *=====================================================================*/
------------------------------------------------------------------
-- Drop triggers if they exist in ANY schema
------------------------------------------------------------------
DROP TRIGGER IF EXISTS Sales.trg_InsteadOfDeleteOrders;
DROP TRIGGER IF EXISTS dbo.trg_InsteadOfDeleteOrders;
DROP TRIGGER IF EXISTS Sales.trg_CheckStockBeforeInsert;
DROP TRIGGER IF EXISTS dbo.trg_CheckStockBeforeInsert;
GO

------------------------------------------------------------------
-- Drop views
------------------------------------------------------------------
DROP VIEW   IF EXISTS dbo.vwCustomerOrders;
DROP VIEW   IF EXISTS dbo.vwCustomerOrders_Yesterday;
DROP VIEW   IF EXISTS dbo.MyProducts;
GO

------------------------------------------------------------------
-- Drop procedures
------------------------------------------------------------------
DROP PROCEDURE IF EXISTS dbo.InsertOrderDetails;
DROP PROCEDURE IF EXISTS dbo.UpdateOrderDetails;
DROP PROCEDURE IF EXISTS dbo.GetOrderDetails;
DROP PROCEDURE IF EXISTS dbo.DeleteOrderDetails;
GO

------------------------------------------------------------------
-- Drop scalar functions
------------------------------------------------------------------
DROP FUNCTION  IF EXISTS dbo.fn_DateToMMDDYYYY;
DROP FUNCTION  IF EXISTS dbo.fn_DateToYYYYMMDD;
GO



/*=====================================================================*
  1)  SCALAR FUNCTIONS
 *=====================================================================*/
CREATE FUNCTION dbo.fn_DateToMMDDYYYY (@inputDate DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    RETURN FORMAT(@inputDate, 'MM/dd/yyyy');   -- e.g. 06/16/2025
END;
GO

CREATE FUNCTION dbo.fn_DateToYYYYMMDD (@inputDate DATETIME)
RETURNS VARCHAR(8)
AS
BEGIN
    RETURN CONVERT(VARCHAR(8), @inputDate, 112);  -- e.g. 20250616
END;
GO



/*=====================================================================*
  2)  VIEWS
 *=====================================================================*/
CREATE VIEW dbo.vwCustomerOrders AS
SELECT
    COALESCE(st.Name, CONCAT(pp.FirstName, ' ', pp.LastName)) AS CompanyName,
    soh.SalesOrderID                                           AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name                                                    AS ProductName,
    sod.OrderQty                                              AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice                              AS TotalPrice
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product     AS p   ON sod.ProductID    = p.ProductID
JOIN Sales.Customer         AS c   ON soh.CustomerID   = c.CustomerID
LEFT JOIN Sales.Store       AS st  ON c.StoreID        = st.BusinessEntityID
LEFT JOIN Person.Person     AS pp  ON c.PersonID       = pp.BusinessEntityID;
GO

CREATE VIEW dbo.vwCustomerOrders_Yesterday AS
SELECT *
FROM   dbo.vwCustomerOrders
WHERE  CAST(OrderDate AS DATE) = CAST(DATEADD(DAY,-1,GETDATE()) AS DATE);
GO

CREATE VIEW dbo.MyProducts AS
SELECT
    p.ProductID,
    p.Name          AS ProductName,
    p.Size          AS QuantityPerUnit,
    p.ListPrice     AS UnitPrice,
    v.Name          AS CompanyName,
    pc.Name         AS CategoryName
FROM Production.Product            AS p
JOIN Production.ProductSubcategory AS ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory    AS pc ON ps.ProductCategoryID   = pc.ProductCategoryID
JOIN Purchasing.ProductVendor      AS pv ON p.ProductID            = pv.ProductID
JOIN Purchasing.Vendor             AS v  ON pv.BusinessEntityID    = v.BusinessEntityID
WHERE p.DiscontinuedDate IS NULL;
GO



/*=====================================================================*
  3)  TRIGGERS  (CREATE OR ALTER so they overwrite cleanly)
 *=====================================================================*/
CREATE OR ALTER TRIGGER Sales.trg_InsteadOfDeleteOrders
ON Sales.SalesOrderHeader
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM Sales.SalesOrderDetail
    WHERE  SalesOrderID IN (SELECT SalesOrderID FROM DELETED);

    DELETE FROM Sales.SalesOrderHeader
    WHERE  SalesOrderID IN (SELECT SalesOrderID FROM DELETED);
END;
GO


CREATE OR ALTER TRIGGER Sales.trg_CheckStockBeforeInsert
ON Sales.SalesOrderDetail
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM   INSERTED i
        JOIN   Production.Product p ON i.ProductID = p.ProductID
        WHERE  i.OrderQty > (p.SafetyStockLevel - p.ReorderPoint)
    )
    BEGIN
        RAISERROR ('Insufficient stock to place the order.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    INSERT INTO Sales.SalesOrderDetail
           (SalesOrderID, OrderQty, ProductID, SpecialOfferID,
            UnitPrice, UnitPriceDiscount)
    SELECT  i.SalesOrderID,
            i.OrderQty,
            i.ProductID,
            i.SpecialOfferID,
            i.UnitPrice,
            i.UnitPriceDiscount
    FROM     INSERTED i;
END;
GO



/*=====================================================================*
  4)  STORED PROCEDURES
 *=====================================================================*/
------------------------------------------------------------------
-- InsertOrderDetails
------------------------------------------------------------------
CREATE PROCEDURE dbo.InsertOrderDetails
    @OrderID        INT,
    @ProductID      INT,
    @UnitPrice      MONEY = NULL,
    @Quantity       INT,
    @Discount       FLOAT = 0,     -- fraction: 0‑1  (0.1 = 10 %)
    @SpecialOfferID INT  = NULL
AS
BEGIN
    SET NOCOUNT ON;

    /* Default price */
    IF @UnitPrice IS NULL
        SELECT @UnitPrice = ListPrice
        FROM   Production.Product
        WHERE  ProductID = @ProductID;

    /* Default special‑offer ID for this product (or 1 = "No Discount") */
    IF @SpecialOfferID IS NULL
        SELECT TOP 1 @SpecialOfferID = SpecialOfferID
        FROM Sales.SpecialOfferProduct
        WHERE ProductID = @ProductID;

    IF @SpecialOfferID IS NULL SET @SpecialOfferID = 1;

    /* Insert detail row (INSTEAD‑OF trigger will validate stock) */
    INSERT INTO Sales.SalesOrderDetail
           (SalesOrderID, OrderQty, ProductID,
            SpecialOfferID, UnitPrice, UnitPriceDiscount)
    VALUES (@OrderID,     @Quantity, @ProductID,
            @SpecialOfferID, @UnitPrice, ISNULL(@Discount,0));

    IF @@ROWCOUNT = 0
    BEGIN
        RAISERROR ('Failed to place the order.', 16, 1);
        RETURN;
    END

    /* Pseudo‑inventory update */
    UPDATE Production.Product
    SET    SafetyStockLevel = SafetyStockLevel - @Quantity
    WHERE  ProductID = @ProductID;

    DECLARE @Stock INT, @Reorder INT;
    SELECT @Stock   = SafetyStockLevel,
           @Reorder = ReorderPoint
    FROM   Production.Product
    WHERE  ProductID = @ProductID;

    IF @Stock < @Reorder
        PRINT 'Warning: stock level is below the reorder point.';
END;
GO


------------------------------------------------------------------
-- UpdateOrderDetails
------------------------------------------------------------------
CREATE PROCEDURE dbo.UpdateOrderDetails
    @OrderID   INT,
    @ProductID INT,
    @UnitPrice MONEY = NULL,
    @Quantity  INT = NULL,
    @Discount  FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldQty INT = 0;
    SELECT @OldQty = OrderQty
    FROM   Sales.SalesOrderDetail
    WHERE  SalesOrderID = @OrderID
      AND  ProductID    = @ProductID;

    UPDATE Sales.SalesOrderDetail
    SET    OrderQty          = ISNULL(@Quantity,  OrderQty),
           UnitPrice         = ISNULL(@UnitPrice, UnitPrice),
           UnitPriceDiscount = ISNULL(@Discount,  UnitPriceDiscount)
    WHERE  SalesOrderID = @OrderID
      AND  ProductID    = @ProductID;

    /* Adjust pseudo inventory */
    IF @Quantity IS NOT NULL AND @Quantity <> @OldQty
    BEGIN
        UPDATE Production.Product
        SET    SafetyStockLevel = SafetyStockLevel - (@Quantity - @OldQty)
        WHERE  ProductID = @ProductID;
    END
END;
GO


------------------------------------------------------------------
-- GetOrderDetails
------------------------------------------------------------------
CREATE PROCEDURE dbo.GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                   FROM   Sales.SalesOrderDetail
                   WHERE  SalesOrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR) + ' does not exist';
        RETURN 1;
    END

    SELECT *
    FROM   Sales.SalesOrderDetail
    WHERE  SalesOrderID = @OrderID;
END;
GO


------------------------------------------------------------------
-- DeleteOrderDetails
------------------------------------------------------------------
CREATE PROCEDURE dbo.DeleteOrderDetails
    @OrderID   INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1
                   FROM   Sales.SalesOrderDetail
                   WHERE  SalesOrderID = @OrderID
                     AND  ProductID    = @ProductID)
    BEGIN
        PRINT 'Invalid OrderID or ProductID.';
        RETURN -1;
    END

    DELETE FROM Sales.SalesOrderDetail
    WHERE  SalesOrderID = @OrderID
      AND  ProductID    = @ProductID;
END;
GO



/*=====================================================================*
  5)  OPTIONAL SAMPLE‑DATA DEMO  (comment out if you don’t need it)
 *=====================================================================*/
PRINT '---  SAMPLE‑DATA DEMO  ---------------------------------------';
DECLARE @CustomerID       INT  = (SELECT TOP 1 CustomerID FROM Sales.Customer ORDER BY NEWID());
DECLARE @BillToAddressID  INT  = (SELECT TOP 1 AddressID  FROM Person.Address ORDER BY NEWID());
DECLARE @ShipToAddressID  INT  = @BillToAddressID;
DECLARE @ShipMethodID     INT  = (SELECT TOP 1 ShipMethodID FROM Purchasing.ShipMethod);
DECLARE @TerritoryID      INT  = (SELECT TOP 1 TerritoryID  FROM Sales.SalesTerritory);
DECLARE @OrderDate        DATE = GETDATE();
DECLARE @DueDate          DATE = DATEADD(DAY, 7, @OrderDate);
DECLARE @ShipDate         DATE = DATEADD(DAY, 2, @OrderDate);

/* Insert header with required columns */
INSERT INTO Sales.SalesOrderHeader
(
    RevisionNumber, Status, CustomerID, TerritoryID,
    BillToAddressID, ShipToAddressID, ShipMethodID,
    SubTotal, TaxAmt, Freight,
    OrderDate, DueDate, ShipDate
)
VALUES
(
    0, 1, @CustomerID, @TerritoryID,
    @BillToAddressID, @ShipToAddressID, @ShipMethodID,
    0, 0, 0,
    @OrderDate, @DueDate, @ShipDate
);

DECLARE @NewOrderID INT = SCOPE_IDENTITY();
PRINT 'New SalesOrderID = ' + CAST(@NewOrderID AS VARCHAR);

/* Pick a product with good stock */
DECLARE @ProductID INT,
        @SpecialOfferID INT;

SELECT TOP 1
    @ProductID = sp.ProductID,
    @SpecialOfferID = sp.SpecialOfferID
FROM Sales.SpecialOfferProduct AS sp
JOIN Production.Product         AS p ON p.ProductID = sp.ProductID
WHERE p.SafetyStockLevel >= 100
ORDER BY NEWID();


/* Insert detail via your proc */
EXEC dbo.InsertOrderDetails
     @OrderID   = @NewOrderID,
     @ProductID = @ProductID,
     @Quantity  = 5;

/* Show what we created */
SELECT * FROM Sales.SalesOrderHeader WHERE SalesOrderID = @NewOrderID;
SELECT * FROM Sales.SalesOrderDetail WHERE SalesOrderID = @NewOrderID;
SELECT * FROM dbo.vwCustomerOrders   WHERE OrderID      = @NewOrderID;
GO



/*=====================================================================*
  6)  QUICK SANITY CHECK (functions & view)
 *=====================================================================*/
PRINT '---  Sanity check: functions';
SELECT dbo.fn_DateToMMDDYYYY(GETDATE()) AS Today_MMDDYYYY,
       dbo.fn_DateToYYYYMMDD(GETDATE()) AS Today_YYYYMMDD;

PRINT '---  Sanity check: view';
SELECT TOP 3 * FROM dbo.vwCustomerOrders;
GO
