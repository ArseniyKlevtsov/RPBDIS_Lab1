USE master
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'RailwayTraffic')
    DROP DATABASE RailwayTraffic;
CREATE DATABASE RailwayTraffic

GO
ALTER DATABASE RailwayTraffic SET RECOVERY SIMPLE
GO

USE RailwayTraffic

CREATE TABLE Stops (
	StopID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    StopName NVARCHAR(50),
    IsSuburbanTrainsPassed BIT,
    IsLongDistanceTrainsPassed BIT,
    IsRailwayStation BIT,
    HasWaitingRoom BIT
);

CREATE TABLE Trains (
	TrainID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TrainNumber NVARCHAR(4),
    TrainTypeID INT,
	ArrivalStopID INT,
    DepartureStopID INT,
    DistanceInKm real,
	ArrivalTime TIME,
    DepartureTime TIME,
    IsBrandedTrain BIT
);

CREATE TABLE TrainTypes (
	TrainTypeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	TypeName NVARCHAR(50),
)

CREATE TABLE Schedule (
	ScheduleID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TrainID INT,
    StopID INT,
    NumberOfDayOfWeek  TINYINT,
    ArrivalTime TIME,
    DepartureTime TIME
);

CREATE TABLE Employees (
	EmployeeID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    EmployeeName NVARCHAR(50),
    Age INT,
    WorkExperience REAL,
    PositionID INT,
    HireDate DATE
);

CREATE TABLE Positions (
	PositionID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    PositionName NVARCHAR(100),
    SalaryUsd REAL
);

CREATE TABLE TrainStaffs (
	TrainStaffID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    TrainID INT,
    EmployeeID INT,
    NumberOfDayOfWeek TINYINT
);

ALTER TABLE Trains
ADD CONSTRAINT FK_Trains_TrainTypes
FOREIGN KEY (TrainTypeID)
REFERENCES TrainTypes (TrainTypeID);

ALTER TABLE Trains
ADD CONSTRAINT FK_Trains_DepartureStops
FOREIGN KEY (DepartureStopID)
REFERENCES Stops (StopID);

ALTER TABLE Trains
ADD CONSTRAINT FK_Trains_ArrivalStops
FOREIGN KEY (ArrivalStopID)
REFERENCES Stops (StopID);

ALTER TABLE Schedule
ADD CONSTRAINT FK_Schedule_Trains
FOREIGN KEY (TrainID)
REFERENCES Trains (TrainID);

ALTER TABLE Schedule
ADD CONSTRAINT FK_Schedule_Stops
FOREIGN KEY (StopID)
REFERENCES Stops (StopID);

ALTER TABLE Employees
ADD CONSTRAINT FK_Employees_Positions
FOREIGN KEY (PositionID)
REFERENCES Positions (PositionID);

ALTER TABLE TrainStaffs
ADD CONSTRAINT FK_TrainStaffs_Trains
FOREIGN KEY (TrainID)
REFERENCES Trains (TrainID);

ALTER TABLE TrainStaffs
ADD CONSTRAINT FK_TrainStaffs_Employees
FOREIGN KEY (EmployeeID)
REFERENCES Employees (EmployeeID);

SET NOCOUNT ON
 
-- Объявление переменных
DECLARE @Symbol CHAR(52) = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
        @Position INT,
        @i INT,
        @NameLimit INT,
        @RowCount INT,

		@RandomHoursAr INT, 
		@RandomMinutesAr INT,
		@RandomTimeAr TIME,
		@RandomHoursDep INT, 
		@RandomMinutesDep INT,
		@RandomTimeDep TIME,

        @NumberStops INT,
        @NumberTrains INT,
        @NumberTrainTypes INT,

        @MinNumberSymbols INT,
        @MaxNumberSymbols INT,

        @TypeName NVARCHAR(50),  
        @StopName NVARCHAR(50),  
        @TrainNumber NVARCHAR(4)  

-- Количество остановок, поездов и типов поездов, которое хотите создать
SET @NumberStops = 500
SET @NumberTrains = 2000
SET @NumberTrainTypes = 500

-- Установка минимальной и максимальной длины для имени остановки и типа поезда
SET @MinNumberSymbols = 5
SET @MaxNumberSymbols = 50

-- Начало транзакции
BEGIN TRAN

-- Эти строки блокируют таблицы для других операций
SELECT @i = 0 FROM Stops WITH (TABLOCKX) WHERE 1 = 0
SELECT @i = 0 FROM Trains WITH (TABLOCKX) WHERE 1 = 0
SELECT @i = 0 FROM TrainTypes WITH (TABLOCKX) WHERE 1 = 0

-- Заполнение таблицы TrainTypes
SET @RowCount = 1

WHILE @RowCount <= @NumberTrainTypes
BEGIN
    SET @NameLimit = @MinNumberSymbols + RAND() * (@MaxNumberSymbols - @MinNumberSymbols) -- длина имени от 5 до 20 символов
    SET @i = 1
    SET @TypeName = ''

    WHILE @i <= @NameLimit
    BEGIN
        SET @Position = RAND() * 52
        SET @TypeName = @TypeName + SUBSTRING(@Symbol, @Position, 1)
        SET @i = @i + 1
    END

    INSERT INTO TrainTypes (TypeName) VALUES (@TypeName)

    SET @RowCount += 1
END

-- Заполнение таблицы Stops
SET @RowCount = 1

WHILE @RowCount <= @NumberStops
BEGIN
    SET @NameLimit = @MinNumberSymbols + RAND() * (@MaxNumberSymbols - @MinNumberSymbols) 
    SET @i = 1
    SET @StopName = ''

    WHILE @i <= @NameLimit
    BEGIN
        SET @Position = RAND() * 52
        SET @StopName = @StopName + SUBSTRING(@Symbol, @Position, 1)
        SET @i = @i + 1
    END

    INSERT INTO Stops (StopName, IsSuburbanTrainsPassed, IsLongDistanceTrainsPassed, IsRailwayStation, HasWaitingRoom)
    VALUES (@StopName, CASE WHEN RAND() <= 0.5 THEN 0 ELSE 1 END, CASE WHEN RAND() <= 0.5 THEN 0 ELSE 1 END, CASE WHEN RAND() <= 0.5 THEN 0 ELSE 1 END, CASE WHEN RAND() <= 0.5 THEN 0 ELSE 1 END)

    SET @RowCount += 1
END

-- Заполнение таблицы Trains
SET @RowCount = 1

WHILE @RowCount <= @NumberTrains
BEGIN
    SET @NameLimit = 4
    SET @i = 1
    SET @TrainNumber = ''

    WHILE @i <= @NameLimit
    BEGIN
        SET @Position = RAND() * 52
        SET @TrainNumber = @TrainNumber + SUBSTRING(@Symbol, @Position, 1)
        SET @i = @i + 1
    END

	SET @RandomHoursAr = CAST(RAND() * 24 AS INT)
	SET @RandomMinutesAR = CAST(RAND() * 60 AS INT)
	SET @RandomTimeAr = TIMEFROMPARTS(@RandomHoursAr, @RandomMinutesAr, 0, 0, 0)

	SET @RandomHoursDep = CAST(RAND() * 24 AS INT)
	SET @RandomMinutesDep = CAST(RAND() * 60 AS INT)
	SET @RandomTimeDep = TIMEFROMPARTS(@RandomHoursDep, @RandomMinutesDep, 0, 0, 0)

    INSERT INTO Trains (TrainNumber, TrainTypeID, ArrivalStopID , DepartureStopID, DistanceInKm, ArrivalTime ,DepartureTime, IsBrandedTrain)
    VALUES (@TrainNumber, CAST(RAND() * @NumberTrainTypes + 1 AS INT), CAST(RAND() * @NumberStops + 1 AS INT), CAST(RAND() * @NumberStops + 1 AS INT), RAND() * 100, @RandomTimeAr, @RandomTimeDep, CASE WHEN RAND() <= 0.5 THEN 0 ELSE 1 END)

    SET @RowCount += 1
END

-- Завершение транзакции
COMMIT TRAN
GO
-- Создание представления для полной информации о поезде
CREATE VIEW TrainInformation AS
SELECT
    T.TrainID,
    T.TrainNumber,
    TT.TypeName AS TrainType,
    S1.StopName AS DepartureStop,
    S2.StopName AS ArrivalStop,
    T.DistanceInKm,
    T.DepartureTime,
    T.ArrivalTime,
    CASE WHEN T.IsBrandedTrain = 1 THEN 'Да' ELSE 'Нет' END AS IsBrandedTrain
FROM
    Trains T
INNER JOIN
    TrainTypes TT ON T.TrainTypeID = TT.TrainTypeID
INNER JOIN
    Stops S1 ON T.DepartureStopID = S1.StopID
INNER JOIN
    Stops S2 ON T.ArrivalStopID = S2.StopID;

Go
CREATE PROCEDURE InsertStop
    @StopName NVARCHAR(50),
    @IsSuburbanTrainsPassed BIT,
    @IsLongDistanceTrainsPassed BIT,
    @IsRailwayStation BIT,
    @HasWaitingRoom BIT
AS
BEGIN
    INSERT INTO Stops (StopName, IsSuburbanTrainsPassed, IsLongDistanceTrainsPassed, IsRailwayStation, HasWaitingRoom)
    VALUES (@StopName, @IsSuburbanTrainsPassed, @IsLongDistanceTrainsPassed, @IsRailwayStation, @HasWaitingRoom);
END;

Go
CREATE PROCEDURE InsertTrain
    @TrainNumber NVARCHAR(4),
    @TrainTypeID INT,
    @ArrivalStopID INT,
    @DepartureStopID INT,
    @DistanceInKm REAL,
    @ArrivalTime TIME,
    @DepartureTime TIME,
    @IsBrandedTrain BIT
AS
BEGIN
    INSERT INTO Trains (TrainNumber, TrainTypeID, ArrivalStopID, DepartureStopID, DistanceInKm, ArrivalTime, DepartureTime, IsBrandedTrain)
    VALUES (@TrainNumber, @TrainTypeID, @ArrivalStopID, @DepartureStopID, @DistanceInKm, @ArrivalTime, @DepartureTime, @IsBrandedTrain);
END;

Go
CREATE PROCEDURE UpdateTrainType
    @TrainTypeID INT,
    @TypeName NVARCHAR(50)
AS
BEGIN
    UPDATE TrainTypes
    SET TypeName = @TypeName
    WHERE TrainTypeID = @TrainTypeID;
END;
