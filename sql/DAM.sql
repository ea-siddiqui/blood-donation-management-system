CREATE DATABASE BloodDonationDB;
USE BloodDonationDB;

SELECT COLUMN_NAME, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'BloodRequests'
SELECT TOP 1 * FROM BloodRequests;

--TABLES
CREATE TABLE Donors (
    DonorID INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
    DonorName VARCHAR(50) NOT NULL,
    Age INT NOT NULL CHECK (Age >= 18 AND Age <= 65),
    BloodType CHAR(3) CHECK (BloodType IN ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-')),
    ContactNumber INT
);
DELETE FROM Donors; -- Removes all rows but retains the table structure
INSERT INTO Donors (DonorName, Age, BloodType, ContactNumber)
VALUES
('Saif Aslam', 24, 'A-', '0312-3698769'),
('Eisha Awais', 30, 'A+', '0315-6094330'),
('Amal Jamil', 25, 'O-', '0321-9876543'),
('Taha Sheikh', 28, 'B+', '0345-1234567'),
('Haris Khan', 35, 'AB+', '0333-7654321'),
('Karim', 40, 'O+', '0300-1122334'),
('Isra Saleem', 22, 'A-', '0314-5566778'),
('Muhammad Umer', 45, 'B-', '0331-9988776');
DBCC CHECKIDENT ('BloodDonation', RESEED, 0); -- Resets identity counter to 0; next insert starts at 1ALTER TABLE Donors ALTER COLUMN ContactNumber VARCHAR(12) NOT NULL;
UPDATE Donors 
SET ContactNumber = 
    LEFT(ContactNumber, 4) + '-' + RIGHT(ContactNumber, LEN(ContactNumber)-4)
WHERE LEN(ContactNumber) = 10;

CREATE TABLE BloodDonation (
    DonationID INT IDENTITY(1,1) PRIMARY KEY,
    DonorID INT,
    DonationDate DATETIME DEFAULT GETDATE(),
    AmountDonated DECIMAL(5,2) CHECK (AmountDonated > 0 AND AmountDonated <= 500), -- Amount in milliliters
    FOREIGN KEY (DonorID) REFERENCES Donors(DonorID)
);
DELETE FROM BloodDonation;
INSERT INTO BloodDonation (DonorID, DonationDate, AmountDonated)
VALUES
(1, '2023-01-15', 450.00),        -- DonorID 1 (Saif)
(2, '2023-02-20', 480.50),       -- DonorID 2 (Eisha Awais)
(3, '2023-03-10', 300.00),       -- DonorID 3 (Amal Jamil)
(4, '2023-04-05', 499.99),       -- DonorID 4 (Taha Sheikh)
(5, '2023-05-12', 250.75),       -- DonorID 5 (Haris Khan)
(6, GETDATE(), 500.00),          -- DonorID 6 (Karim) - Uses current date/time
(7, '2023-07-01', 350.25),       -- DonorID 7 (Isra Saleem)
(8, '2023-08-18', 200.00);       -- DonorID 8 (Muhammad Umer)
SELECT * FROM BloodDonation;
-- Check allowed blood types
SELECT *
FROM INFORMATION_SCHEMA.CHECK_CONSTRAINTS
WHERE CONSTRAINT_NAME = 'CK__Donors__BloodTyp__619B8048';


CREATE TABLE BloodInventory (
    BloodID INT IDENTITY(1,1) PRIMARY KEY,
    BloodType CHAR(3) CHECK (BloodType IN ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-')),
    Quantity INT  CHECK (Quantity >= 0)
);
INSERT INTO BloodInventory (BloodType, Quantity)
VALUES
('A+', 50),
('A-', 20),
('B+', 20),
('B-', 10),
('O+', 40),
('O-', 30),
('AB+', 10),
('AB-', 15);
SELECT * FROM BloodInventory ORDER BY BloodType;
ALTER TABLE BloodInventory
ADD CONSTRAINT UQ_BloodType UNIQUE (BloodType);
WITH DuplicateCTE AS (
    SELECT
        BloodID,
        BloodType,
        ROW_NUMBER() OVER (PARTITION BY BloodType ORDER BY BloodID) AS rn
    FROM BloodInventory
)
DELETE FROM DuplicateCTE WHERE rn > 1;

UPDATE BloodInventory
SET Quantity = CASE BloodType
    WHEN 'A+'  THEN 3
    WHEN 'A-'  THEN 6
    WHEN 'B+'  THEN 9
    WHEN 'B-'  THEN 10
    WHEN 'O+'  THEN 4
    WHEN 'O-'  THEN 7
    WHEN 'AB+' THEN 5
    WHEN 'AB-' THEN 8
    ELSE Quantity
END;





CREATE TABLE BloodRequests (
    RequestID INT IDENTITY(1,1) PRIMARY KEY,
    BloodType CHAR(3) CHECK (BloodType IN ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-')),
    Quantity int CHECK (Quantity > 0),
    RequestDate DATETIME DEFAULT GETDATE(),
    Fulfilled BIT DEFAULT 0, -- 0 = Not fulfilled, 1 = Fulfilled
	RequestBy VARCHAR(100)   
);
INSERT INTO BloodRequests (BloodType, Quantity, RequestBy)
VALUES
    ('A+', 5, 'City Hospital'),
    ('O-', 3, 'Local Clinic'),
    ('B+', 2, 'Emergency Medical Services'),
    ('AB-', 1, 'Blood Bank'),
    ('O+', 4, 'General Hospital');
SELECT * FROM BloodRequests;
UPDATE BloodRequests
SET Fulfilled = 1
WHERE RequestID = 1;  -- Change ID as needed

CREATE TABLE Logtable (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    ActionType VARCHAR(50),
    TableName VARCHAR(50),  
    RecordID INT,          -- The affected record's ID
    ActionDate DATETIME DEFAULT GETDATE(),
    PerformedBy NVARCHAR(100) 
);


SELECT DonorID, DonorName FROM Donors;


------------------------------------------------------------------------------------------
--TRIGGERS 

--1--DELETE DONOR
CREATE TRIGGER DeleteDonor
ON Donors
AFTER DELETE
AS
BEGIN
    DECLARE @DonorID INT, @PerformedBy NVARCHAR(100);
    SELECT @DonorID = DonorID FROM DELETED;
    SET @PerformedBy = SYSTEM_USER;

    INSERT INTO Logtable (ActionType, TableName, RecordID, PerformedBy)
    VALUES ('DELETE', 'Donors', @DonorID, @PerformedBy);

    -- First delete the related records in BloodDonation table
    DELETE FROM BloodDonation WHERE DonorID = @DonorID;
END;

ALTER TABLE BloodDonation
ADD CONSTRAINT FK_BloodDonation_DonorID
FOREIGN KEY (DonorID) REFERENCES Donors(DonorID)
ON DELETE CASCADE;

--//DELETE FROM Donors WHERE DonorID = 3;

SELECT * FROM Donors;

-------------------------------------------------------------------------------------------
    ---2---InsertBloodRequest

CREATE TRIGGER InsertBloodRequest
ON BloodRequests
AFTER INSERT
AS
BEGIN
    DECLARE @BloodType CHAR(3), @Quantity INT, @PerformedBy NVARCHAR(100);

    -- Get data from inserted record
    SELECT @BloodType = BloodType, @Quantity = Quantity FROM INSERTED;
    SET @PerformedBy = SYSTEM_USER;

    INSERT INTO Logtable (ActionType, TableName, RecordID, PerformedBy)
    VALUES ('INSERT', 'BloodRequests', (SELECT RequestID FROM INSERTED), @PerformedBy);

    PRINT 'New blood request received for ' + CONVERT(NVARCHAR(10), @Quantity) + ' units of ' + @BloodType;
END;

--//INSERT INTO BloodRequests (BloodType, Quantity, RequestBy) VALUES ('A+', 5, 'City Hospital');

SELECT * FROM BloodRequests;


--3--RestrictSchemaModifications(DDLTRIGGER)

CREATE TRIGGER RestrictSchemaModifications
ON DATABASE
FOR ALTER_TABLE, DROP_TABLE,Create_Table
AS
BEGIN
    -- Check if the current user is a system user (DBO or admin)
    IF SYSTEM_USER <>'dbo' 
    BEGIN
       
            PRINT 'Only the dbo user is allowed to make changes';
            ROLLBACK;
        
    END
END;

--//CREATE TABLE TestTable (ID INT);
--//ALTER TABLE Donors ADD Email VARCHAR(50);
--//DROP TABLE BloodDonation;

DROP TRIGGER RestrictSchemaModifications ON DATABASE;

------------------------------------------------------------------------------------------------------

--!PROCEDURES

--1--InsertDonor

CREATE PROCEDURE InsertDonor
    @DonorName VARCHAR(50),
    @Age INT,
    @BloodType CHAR(3),
    @ContactNumber INT
AS
BEGIN
    IF @Age < 18 OR @Age > 65
    BEGIN
        PRINT 'Error: Donor age must be between 18 and 65.';
        RETURN;
    END

    IF @BloodType NOT IN ('A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-')
    BEGIN
        PRINT 'Error: Invalid blood type.';
        RETURN;
    END

    INSERT INTO Donors (DonorName, Age, BloodType, ContactNumber)
    VALUES (@DonorName, @Age, @BloodType, @ContactNumber);



    PRINT 'Donor successfully inserted.';
END;

--//EXEC InsertDonor @DonorName = 'John ', @Age = 30, @BloodType = 'O+', @ContactNumber = 1234567890;

-----------------------------------------------------------------------------------------------------------
--2--DonateBlood

CREATE PROCEDURE DonateBlood
    @DonorID INT,
    @Amount DECIMAL(5,2)
AS
BEGIN
    -- Insert the donation record
    INSERT INTO BloodDonation (DonorID, AmountDonated)
    VALUES (@DonorID, @Amount);

    DECLARE @BloodType CHAR(3);
    SELECT @BloodType = BloodType FROM Donors WHERE DonorID = @DonorID;

    IF EXISTS (SELECT BloodType FROM BloodInventory WHERE BloodType = @BloodType)
    BEGIN
        -- Update the inventory
        UPDATE BloodInventory
        SET Quantity = (Quantity + @Amount) 
        WHERE BloodType = @BloodType;
    END
    ELSE
    BEGIN
        PRINT 'Blood type not found in inventory';
    END
END;

--//EXEC DonateBlood  @DonorID = 2, @Amount = 40; 
--//SELECT * FROM BloodDonation;

--//SELECT * FROM BloodInventory;
--//SELECT * FROM Logtable;

---------------------------------------------------------------------------------------------------------------
--3--FulfillBloodRequest(CONCURRENCY CONTROL,ISOLATION LEVEL,DEADLOCK)
CREATE PROCEDURE FulfillBloodRequest
    @RequestID INT
AS
BEGIN
    DECLARE @BloodType CHAR(3), @Quantity INT, @PerformedBy NVARCHAR(100);
    SET @PerformedBy = SYSTEM_USER;

    SELECT @BloodType = BloodType, @Quantity = Quantity 
    FROM BloodRequests
    WHERE RequestID = @RequestID;

    -- Set isolation level to SERIALIZABLE 
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    -- Begin transaction to ensure atomicity
    BEGIN TRANSACTION;
    BEGIN TRY
        INSERT INTO Logtable(ActionType, TableName, RecordID, PerformedBy)
        VALUES ('UPDATE', 'BloodRequests', @RequestID, @PerformedBy);

      --// SELECT Quantity 
        --//FROM BloodInventory WITH (ROWLOCK, HOLDLOCK) 
        --//WHERE BloodType = @BloodType;
        --//WAITFOR DELAY '00:00:05';
    
        IF (SELECT Quantity FROM BloodInventory WHERE BloodType = @BloodType) >= @Quantity
        BEGIN
            WAITFOR DELAY '00:00:05'; 
            UPDATE BloodInventory
            SET Quantity = Quantity - @Quantity
            WHERE BloodType = @BloodType;

            -- Mark the request as fulfilled
            UPDATE BloodRequests
            SET Fulfilled = 1
            WHERE RequestID = @RequestID;

            PRINT 'Request fulfilled successfully';
        END
        ELSE
        BEGIN
            PRINT 'Insufficient blood supply to fulfill the request';
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        PRINT 'Rolling back the transaction';
        ROLLBACK TRANSACTION;
    END CATCH
END;
--//DROP PROCEDURE FulfillBloodRequest
--//EXEC FulfillBloodRequest @RequestID =4;
--//SELECT * FROM BloodRequests;

---------------------------------------------------------------------------------------------------------------------
  ---4---GenerateBloodDonationReport


CREATE PROCEDURE GenerateBloodDonationReport
AS
BEGIN
    PRINT '------ Total Donors Report ------';
    SELECT COUNT(*) AS TotalDonors FROM Donors;

    PRINT '------ Total Blood Donations ------';
    SELECT COUNT(*) AS TotalDonations, SUM(AmountDonated) AS TotalAmountDonated
    FROM BloodDonation;

    PRINT '------ Blood Inventory Report ------';
    SELECT BloodType, Quantity
    FROM BloodInventory;
 
    PRINT '------ Blood Requests Report ------';
    SELECT RequestID, BloodType, Quantity, RequestDate, Fulfilled
    FROM BloodRequests;

    PRINT '------ Donors and Donations ------';
    SELECT d.DonorName, d.BloodType, COUNT(b.DonationID) AS TotalDonations, SUM(b.AmountDonated) AS TotalAmountDonated
    FROM Donors d
    LEFT JOIN BloodDonation b ON d.DonorID = b.DonorID
    GROUP BY d.DonorName, d.BloodType;

    PRINT '------ Blood Request Fulfillment Status ------';
    SELECT r.RequestID, r.BloodType, r.Quantity, r.Fulfilled
    FROM BloodRequests r
    ORDER BY r.RequestID;
   
END;

ALTER PROCEDURE GenerateBloodDonationReport
AS
BEGIN
    -- Total Donors
    SELECT COUNT(*) AS TotalDonors FROM Donors;

    -- Total Donations
    SELECT 
        COUNT(*) AS TotalDonations, 
        SUM(AmountDonated) AS TotalAmountDonated
    FROM BloodDonation;

    -- Blood Inventory
    SELECT BloodType, Quantity FROM BloodInventory;

    -- Blood Requests
    SELECT 
        RequestID, 
        BloodType, 
        Quantity, 
        RequestDate, 
        Fulfilled 
    FROM BloodRequests;

    -- Donors and Donations
    SELECT 
        d.DonorName, 
        d.BloodType, 
        COUNT(b.DonationID) AS TotalDonations, 
        SUM(b.AmountDonated) AS TotalAmountDonated
    FROM Donors d
    LEFT JOIN BloodDonation b ON d.DonorID = b.DonorID
    GROUP BY d.DonorName, d.BloodType;

    -- Fulfillment Status
    SELECT 
        RequestID, 
        BloodType, 
        Quantity, 
        Fulfilled 
    FROM BloodRequests
    ORDER BY RequestID;
END;

EXEC GenerateBloodDonationReport;


-----------------------------------------------------------------------------------------------------------------------
----- ISOLATION LEVELS -----
-- For BloodInventory queries by type
CREATE NONCLUSTERED INDEX idx_BloodType ON BloodInventory(BloodType);

-- For BloodDonation joins with Donors
CREATE NONCLUSTERED INDEX idx_DonorID ON BloodDonation(DonorID);

BACKUP DATABASE BLOODDONATIONDB TO DISK = 'C:\blooddonation.bak';

CREATE VIEW vw_BloodInventorySummary AS
SELECT 
    d.BloodType,
    COUNT(*) AS TotalDonations,
    FLOOR(SUM(bd.AmountDonated) / 450) AS Quantity -- Convert ml to units
FROM BloodDonation bd
JOIN Donors d ON bd.DonorID = d.DonorID
GROUP BY d.BloodType;

SELECT * FROM vw_BloodInventorySummary ORDER BY BloodType;

CREATE TRIGGER trg_AfterDonationInsert
ON BloodDonation
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE bi
    SET Quantity = Quantity + FLOOR(i.AmountDonated / 450)
    FROM BloodInventory bi
    JOIN Donors d ON bi.BloodType = d.BloodType
    JOIN INSERTED i ON d.DonorID = i.DonorID;
END;



CREATE TRIGGER trg_AfterDonationDelete
ON BloodDonation
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE bi
    SET Quantity = CASE 
        WHEN Quantity >= FLOOR(d.AmountDonated / 450) 
        THEN Quantity - FLOOR(d.AmountDonated / 450)
        ELSE 0
    END
    FROM BloodInventory bi
    JOIN Donors dn ON bi.BloodType = dn.BloodType
    JOIN DELETED d ON dn.DonorID = d.DonorID;
END;
