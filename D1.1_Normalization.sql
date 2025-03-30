CREATE DATABASE DBCoursework1;
USE DBCoursework1; -- Switch to the target database

---Shifting the tables to our new DB
SELECT * 
INTO DBCoursework1.dbo.Product
FROM AssignmentPart1.dbo.Product;


SELECT * INTO DBCoursework1.dbo.Customer
FROM AssignmentPart1.dbo.CustomerCity;


SELECT * INTO DBCoursework1.dbo.OrderItem
FROM AssignmentPart1.dbo.OrderItem;



--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Lets normalize Customers table -------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--Setting the primary key as non-nullable
ALTER TABLE customer
ALTER COLUMN Id BIGINT NOT NULL;

-- First setting up the primary key
ALTER TABLE customer
ADD CONSTRAINT PK_CustomerID PRIMARY KEY (Id);

 -- Altering the City column type to resolve the foriegn key error on collation, the type of the attribute was not correctly set
ALTER TABLE customer
ALTER COLUMN City NVARCHAR(255) COLLATE SQL_Latin1_General_CP1_CI_AS;


-- Create a new table with specified columns
CREATE TABLE CityTable (
    City NVARCHAR(255) PRIMARY KEY,
    County NVARCHAR(255),
);

-- Adding the values in the new table city_location
INSERT INTO CityTable(City, County)
SELECT DISTINCT City, County
FROM customer;

 -- Defining Foreign key for City
ALTER TABLE Customer
ADD CONSTRAINT FK_City
FOREIGN KEY (City)
REFERENCES  CityTable(City);


-- Creating county location
CREATE TABLE CountyTable (
    County NVARCHAR(255) PRIMARY KEY,
    Region NVARCHAR(255)
);

 
INSERT INTO CountyTable(County, Region)
SELECT DISTINCT County, region
FROM customer;


 -- Defining Foreign key for County
ALTER TABLE CityTable
ADD CONSTRAINT FK_County
FOREIGN KEY (County)
REFERENCES  CountyTable(County);
 

 -- Creating region location
 CREATE TABLE RegionTable (
    Region NVARCHAR(255) PRIMARY KEY,
    Country NVARCHAR(255)
);

 

INSERT INTO RegionTable(Region, Country)
SELECT DISTINCT region,country
FROM Customer;
 

-- Defining Foreign key for Region
ALTER TABLE CountyTable
ADD CONSTRAINT FK_Region
FOREIGN KEY (region)
REFERENCES  RegionTable(region);

-- Drop columns except City from the Customer table
ALTER TABLE Customer
DROP COLUMN County,Region,Country;

Select * from Customer
-------------------------------------------Customers Table Normalized----------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Lets normalize Product table -------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

ALTER TABLE Product
ALTER COLUMN VariantCode NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL;

ALTER TABLE Product
ALTER COLUMN ProductCode NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL;

-- Create a new table to store unique combinations of Product_Group and Variant_Code
CREATE TABLE ProductGroupTable (
    ProductGroup NVARCHAR(128),
    ProductCode NVARCHAR(50),

    PRIMARY KEY (ProductGroup, ProductCode)
);

-- Insert unique combinations of Product_Group and Variant_Code into the new table
INSERT INTO ProductGroupTable (ProductGroup, ProductCode)
SELECT DISTINCT ProductGroup, ProductCode
FROM Product;


-- Drop the Product_Group column from the Product table
ALTER TABLE Product
DROP COLUMN ProductGroup;


-- Delete duplicate rows based on remaining columns (except Product_Group)
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY VariantCode ORDER BY (SELECT NULL)) AS RowNum
    FROM product
)
DELETE FROM CTE WHERE RowNum > 1;


-- Now we set the Primary Key which would be VariantCode. The VariantCode is set as nullable here but in the document it shows non-nullable, so we set it as the same
ALTER TABLE Product
ADD CONSTRAINT PK_VariantCode PRIMARY KEY (VariantCode);



-- Now we take out values which are not dependant on our primary key, VariantCode, in Product Table, which are Name, Features and Description
CREATE TABLE ProductDetails (
    ProductCode NVARCHAR(50),
    Name NVARCHAR(256),
	Features NVARCHAR(3600),
	Description NVARCHAR(3600),

    PRIMARY KEY (ProductCode)
);



-- Insert unique combinations of Product_Group and Variant_Code into the new table
INSERT INTO ProductDetails(ProductCode, Name, Features, Description)
SELECT DISTINCT ProductCode, Name, Features, Description
FROM product;

--SELECT * FROM ProductDetails;
ALTER TABLE Product
DROP COLUMN Name, Features, Description;


ALTER TABLE Product
ADD CONSTRAINT FK_ProductCode
FOREIGN KEY (ProductCode)
REFERENCES  ProductDetails(ProductCode);

ALTER TABLE ProductGroupTable
ADD CONSTRAINT FK_ProductCodeforGroup
FOREIGN KEY (ProductCode)
REFERENCES  ProductDetails(ProductCode);

-- Next in order to eliminate the NULL values, we create separate tables mapping VariantCode to Cup, Size, LegLength and Colour
CREATE TABLE CupTable (
    VariantCode NVARCHAR(50),
    Cup NVARCHAR(256),
    PRIMARY KEY (VariantCode),
	FOREIGN KEY (VariantCode) REFERENCES Product(VariantCode)
);

CREATE TABLE SizeTable (
    VariantCode NVARCHAR(50),
    Size NVARCHAR(256),
    PRIMARY KEY (VariantCode),
	FOREIGN KEY (VariantCode) REFERENCES Product(VariantCode)
);

CREATE TABLE LegLengthTable (
    VariantCode NVARCHAR(50),
    LegLength NVARCHAR(256),
    PRIMARY KEY (VariantCode),
	FOREIGN KEY (VariantCode) REFERENCES Product(VariantCode)
);

CREATE TABLE ColourTable (
    VariantCode NVARCHAR(50),
    Colour NVARCHAR(256),
    PRIMARY KEY (VariantCode),
	FOREIGN KEY (VariantCode) REFERENCES Product(VariantCode)
);

INSERT INTO CupTable(VariantCode, Cup)
SELECT DISTINCT VariantCode, Cup
FROM Product
WHERE Cup <> '' AND Cup IS NOT NULL;

INSERT INTO SizeTable(VariantCode, Size)
SELECT DISTINCT VariantCode, Size
FROM Product
WHERE Size <> '' AND Size IS NOT NULL;

INSERT INTO LegLengthTable(VariantCode, LegLength)
SELECT DISTINCT VariantCode, LegLength
FROM Product
WHERE LegLength <> '' AND LegLength IS NOT NULL;

INSERT INTO ColourTable(VariantCode, Colour)
SELECT DISTINCT VariantCode, Colour
FROM Product
WHERE Colour <> '' AND Colour IS NOT NULL;


-- Now we drop the columns from the Product table
ALTER TABLE Product
DROP COLUMN Cup, Size, LegLength, Colour;





SELECT * FROM Product;
SELECT * FROM ProductGroupTable;
SELECT * FROM ProductDetails;
SELECT * FROM ColourTable;
SELECT * FROM CupTable;
SELECT * FROM LegLengthTable;
SELECT * FROM SizeTable;


-------------------------------------------Product Table Normalized----------------------------------------------------



--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
----------------------------------------- Lets normalize OrderItem table ----------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------



ALTER TABLE OrderItem
ALTER COLUMN OrderItemNumber NVARCHAR(32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL;

ALTER TABLE OrderItem
ADD CONSTRAINT PK_OrderItemNumber PRIMARY KEY (OrderItemNumber);


CREATE TABLE OrderGroup (
    OrderNumber NVARCHAR(50) PRIMARY KEY NOT NULL,
    OrderStatusCode INT NOT NULL DEFAULT 0,
    OrderCreateDate DATETIME NOT NULL,
	CustomerCityID BIGINT NOT NULL,
    BillingCurrency NVARCHAR(8) NOT NULL DEFAULT 'GBP',
    TotalLineItems INT NOT NULL DEFAULT 0,
    SavedTotal MONEY NOT NULL DEFAULT 0.0,
);

-- Defining Foreign key for Region
ALTER TABLE OrderGroup
ADD CONSTRAINT FK_CustomerID
FOREIGN KEY (CustomerCityID)
REFERENCES  Customer(Id);

SELECT DISTINCT OrderNumber, OrderStatusCode, OrderCreateDate, CustomerCityID
INTO OrderGroup1
FROM OrderItem;

SELECT OrderNumber, SUM(Quantity) AS TotalItems, SUM(LineItemTotal) AS OrderTotal
INTO OrderGroup2
FROM OrderItem
GROUP BY OrderNumber;



INSERT INTO OrderGroup(OrderNumber, OrderStatusCode, OrderCreateDate, CustomerCityID, TotalLineItems, SavedTotal)
SELECT OrderGroup1.OrderNumber, OrderGroup1.OrderStatusCode, OrderGroup1.OrderCreateDate, OrderGroup1.CustomerCityID, 
		OrderGroup2.TotalItems, OrderGroup2.OrderTotal
FROM OrderGroup1 JOIN OrderGroup2 ON OrderGroup1.OrderNumber = OrderGroup2.OrderNumber;

DROP TABLE OrderGroup1, OrderGroup2;


ALTER TABLE OrderItem
DROP COLUMN OrderCreateDate, OrderStatusCode, CustomerCityID, BillingCurrency, ProductCode, UnitPrice;



ALTER TABLE OrderItem
ALTER COLUMN OrderNumber NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL;

ALTER TABLE OrderItem
ADD CONSTRAINT FK_OrderVariantCode
FOREIGN KEY (VariantCode)
REFERENCES  Product(VariantCode);

ALTER TABLE OrderItem
ADD CONSTRAINT FK_OrderNumber
FOREIGN KEY (OrderNumber)
REFERENCES  OrderGroup(OrderNumber);


USE DBCoursework1;
select * from OrderItem WHERE OrderNumber = 'OR\01012005\02';
select * from OrderGroup;
SELECT * from Product;


SET STATISTICS IO ON;

