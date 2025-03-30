USE DBCoursework1;

CREATE PROCEDURE prCreateOrderGroup
    @OrderNumber NVARCHAR(50),
    @OrderCreateDate DATETIME,
    @CustomerCityId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
		IF EXISTS (SELECT 1 FROM Customer WITH (ROWLOCK) WHERE Id = @CustomerCityId)
		BEGIN
			IF @OrderNumber LIKE 'OR\[0-3][0-9][0-1][0-9][0-9][0-9][0-9][0-9]\[0-9][0-9]'
			BEGIN
				-- Check if the OrderNumber is unique, assuming OrderNumber is a unique identifier for each order
				IF NOT EXISTS (SELECT 1 FROM OrderGroup WITH (ROWLOCK) WHERE OrderNumber = @OrderNumber)
				BEGIN
						-- Insert the new entry into the OrderGroup table without calculating the SUM
						INSERT INTO OrderGroup(OrderNumber, OrderCreateDate, CustomerCityId)
						VALUES (@OrderNumber, @OrderCreateDate, @CustomerCityId);

						-- Output a success message
						PRINT 'OrderGroup entry created successfully, You may create an entry in the OrderItem table for this Order.';
					-- Commit the transaction if everything is successful
					COMMIT;
				END
				ELSE
				BEGIN
					-- Throw an error if the OrderNumber is not unique
					THROW 50000, 'Error: OrderNumber must be unique. Entry not created.', 1;
				END
			END
			ELSE
			BEGIN
				-- Throw an error if OrderItemNumber format is incorrect
				THROW 500001, 'Error: Invalid OrderNumber', 1;
			END
		END
		ELSE
		BEGIN
			-- Throw an error if OrderItemNumber format is incorrect
			THROW 500008, 'Error: Invalid CustomerID', 1;
		END
	END TRY
    BEGIN CATCH
        -- Output the error message
        PRINT 'Error: ' + ERROR_MESSAGE();

        -- Rollback the transaction in case of an error
        ROLLBACK;
    END CATCH;
END



CREATE PROCEDURE prCreateOrderItem
    @OrderNumber NVARCHAR(50),
    @OrderItemNumber NVARCHAR(32),
    @ProductGroup NVARCHAR(128),
    @ProductCode NVARCHAR(50),
    @VariantCode NVARCHAR(50),
    @Quantity INT,
    @UnitPrice MONEY
AS
BEGIN
    BEGIN TRY
        -- Start a transaction
        BEGIN TRANSACTION;

        -- Check if the OrderNumber exists in the Order table
        IF EXISTS (SELECT 1 FROM OrderGroup WHERE OrderNumber = @OrderNumber)
        BEGIN
            -- Check the format of OrderItemNumber
            IF @OrderItemNumber LIKE 'OR\[0-3][0-9][0-1][0-9][0-9][0-9][0-9][0-9]\[0-9][0-9]\[0-9]' 
				AND LEFT(@OrderItemNumber, LEN(@OrderItemNumber) - 2) = @OrderNumber
            BEGIN
				IF NOT EXISTS (SELECT 1 FROM OrderItem WITH (ROWLOCK) WHERE OrderItemNumber = @OrderItemNumber)
				BEGIN
					-- Check if VariantCode exists in the Products table
					IF EXISTS (	SELECT 1
								FROM Product P
								WHERE P.VariantCode = @VariantCode
								  AND P.ProductCode = @ProductCode
								  AND P.Price = @UnitPrice) 
							AND EXISTS
							  (	SELECT 1
								FROM ProductGroupTable PG
								WHERE PG.ProductCode = @ProductCode      
								  AND PG.ProductGroup = @ProductGroup) 
					BEGIN
                    
					   -- Insert the new order item into the OrderItem table

					   INSERT INTO OrderItem (OrderNumber, OrderItemNumber, ProductGroup, VariantCode, Quantity, LineItemTotal)
					   VALUES (@OrderNumber, @OrderItemNumber, @ProductGroup, @VariantCode, @Quantity, @UnitPrice*@Quantity);


					   -- Update OrderGroup table values
					   UPDATE OrderGroup 
					   SET 
						   TotalLineItems = TotalLineItems + @Quantity,
						   SavedTotal = SavedTotal + (@UnitPrice*@Quantity)
					   WHERE OrderNumber = @OrderNumber;

					   -- Output a success message
					   PRINT 'OrderItem created successfully.';
					END
					ELSE
					BEGIN
						-- Throw an error if VariantCode does not exist in the Products table
						THROW 500003, 'Error: ProductGroup, ProductCode or VariantCode values do not exist or match. OrderItem not created.', 1;
					END
				END
				ELSE
					BEGIN
						-- Throw an error if VariantCode does not exist in the Products table
						THROW 500009, 'Error: OrderItemNumber already exists.', 1;
					END
            END
            ELSE
            BEGIN
                -- Throw an error if OrderItemNumber format is incorrect
                THROW 500004, 'Error: Invalid OrderItemNumber format, it should match with the OrderNumber except of the last two characters after \. OrderItem not created.', 1;
            END
        END
        ELSE
        BEGIN
            -- Throw an error if the OrderNumber does not exist in the OrderGroup table
            THROW 500001, 'Error: OrderNumber does not exist in the OrderGroup table. OrderItem not created.', 1;
        END

        -- Commit the transaction if everything is successful
        COMMIT;
    END TRY
    BEGIN CATCH
        -- Output the error message
        PRINT ERROR_MESSAGE();

        -- Rollback the transaction in case of an error
        ROLLBACK;
    END CATCH;
END





DECLARE @OrderNumber NVARCHAR(50) = 'OR\31122006\22',
        @OrderCreateDate DATETIME = '2006-12-31 00:00:00.000',
        @CustomerCityId INT = 37834;

-- Execute the stored procedure
EXEC prCreateOrderGroup
    @OrderNumber,
    @OrderCreateDate,
    @CustomerCityId;


--Handle CustomerCityID check in the first stored procedure


DECLARE @OrderNumber NVARCHAR(50) = 'OR\31122006\22',
    @OrderItemNumber NVARCHAR(32) = 'OR\31122006\22\2',
    @ProductGroup NVARCHAR(128) = 'Baby Sale',
    @ProductCode NVARCHAR(50) = '23551',
    @VariantCode NVARCHAR(50) = '286757',
    @Quantity INT = 2,
    @UnitPrice MONEY = 9.99


EXEC prCreateOrderItem
	@OrderNumber,
    @OrderItemNumber,
    @ProductGroup,
    @ProductCode,
    @VariantCode,
    @Quantity,
    @UnitPrice


SET STATISTICS IO ON;
SELECT * FROM OrderGroup WHERE OrderNumber = 'OR\31122006\22';
SELECT * FROM OrderItem WHERE OrderNumber = 'OR\31122006\22';



DELETE FROM OrderItem WHERE OrderNumber = 'OR\31122006\22';
DELETE FROM OrderGroup WHERE OrderNumber = 'OR\31122006\22';

EXEC sp_helpindex 'Product'
EXEC sp_helpindex 'Customer'
EXEC sp_helpindex 'OrderItem'
EXEC sp_helpindex 'OrderGroup'
EXEC sp_helpindex 'Products'
