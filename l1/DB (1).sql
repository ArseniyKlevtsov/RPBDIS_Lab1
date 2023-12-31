﻿--    данный скрипт создает базу данных toplivo с тремя таблицами и генерирует тестовые записи:
-- 1. виды топлива (Fuels) - 1000 штук
-- 2. список емкостей (Tanks) - 100 штук
-- 3. факты совершения операций прихода, расхода топлива (Operations) - 300000 штук

--Создание базы данных
USE master
CREATE DATABASE toplivo

GO
ALTER DATABASE toplivo SET RECOVERY SIMPLE
GO

USE toplivo
--DROP TABLE Fuels, Tanks, Operations
--DROP VIEW View_AllOperations

-- Создание таблиц
CREATE TABLE dbo.Fuels (FuelID int IDENTITY(1,1) NOT NULL PRIMARY KEY, FuelType nvarchar(50), FuelDensity real) -- виды топлива
CREATE TABLE dbo.Tanks (TankID int IDENTITY(1,1) NOT NULL PRIMARY KEY, TankType nvarchar(20), TankVolume real, TankWeight real, TankMaterial nvarchar(20), TankPicture nvarchar(50)) -- емкости
CREATE TABLE dbo.Operations (OperationID int IDENTITY(1,1) NOT NULL PRIMARY KEY, FuelID int, TankID int, Inc_Exp real, [Date] date) -- операции
-- Добавление связей между таблицами
ALTER TABLE dbo.Operations  WITH CHECK ADD  CONSTRAINT FK_Operations_Fuels FOREIGN KEY(FuelID)
REFERENCES dbo.Fuels (FuelID) ON DELETE CASCADE
GO
ALTER TABLE dbo.Operations  WITH CHECK ADD  CONSTRAINT FK_Operations_Tanks FOREIGN KEY(TankID)
REFERENCES dbo.Tanks (TankID) ON DELETE CASCADE
GO


SET NOCOUNT ON


DECLARE @Symbol CHAR(52)= 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz',
		@Position int,
		@i int,
		@NameLimit int,
		@FuelType nvarchar(50),
		@TankType nvarchar(20),
		@TankMaterial nvarchar(20),
	    @FuelID int,
		@TankID int,
		@odate date,
		@Inc_Exp real,
		@RowCount INT,
		@NumberFuels int,
		@NumberTanks int,
		@NumberOperations int,
		@MinNumberSymbols int,
		@MaxNumberSymbols int




SET @NumberFuels =1000
SET @NumberTanks =  100
SET @NumberOperations =  300000


BEGIN TRAN

SELECT @i=0 FROM dbo.Fuels WITH (TABLOCKX) WHERE 1=0


-- Заполнение видов топлива 
	SET @RowCount=1
	SET @MinNumberSymbols=5
	SET @MaxNumberSymbols=50	
	WHILE @RowCount<=@NumberFuels
	BEGIN		

		SET @NameLimit=@MinNumberSymbols+RAND()*(@MaxNumberSymbols-@MinNumberSymbols) -- имя от 5 до 50 символов
		SET @i=1
        SET @FuelType=''
		WHILE @i<=@NameLimit
		BEGIN
			SET @Position=RAND()*52
			SET @FuelType = @FuelType + SUBSTRING(@Symbol, @Position, 1)
			SET @i=@i+1
		END

		INSERT INTO dbo.Fuels (FuelType, FuelDensity) SELECT @FuelType, (1+RAND())
		

		SET @RowCount +=1
	END



-- Заполнение емкостей 
SELECT @i=0 FROM dbo.Tanks WITH (TABLOCKX) WHERE 1=0
	SET @RowCount=1
	SET @MinNumberSymbols=5
	SET @MaxNumberSymbols=20	
	
	WHILE @RowCount<=@NumberTanks
	BEGIN	


		SET @NameLimit=@MinNumberSymbols+RAND()*(@MaxNumberSymbols-@MinNumberSymbols)  -- имя от 5 до 20 символов
		SET @i=1
		SET @TankType=''
		SET @TankMaterial=''
		WHILE @i<=@NameLimit
		BEGIN
			SET @Position=RAND()*52
			SET @TankType = @TankType + SUBSTRING(@Symbol, @Position, 1)
			SET @Position=RAND()*52
			SET @TankMaterial=@TankMaterial + SUBSTRING(@Symbol, @Position, 1)
			SET @i=@i+1
		END

		INSERT INTO dbo.Tanks (TankType, TankVolume, TankWeight, TankMaterial) 
		SELECT @TankType, RAND()*500, RAND()*700, @TankMaterial
		

		SET @RowCount +=1
	END



-- Заполнение операций
SELECT @RowCount=1 FROM dbo.Operations WITH (TABLOCKX) WHERE 1=0
	
	WHILE @RowCount<=@NumberOperations
	BEGIN
		
		SET @odate=dateadd(day,-RAND()*15000,GETDATE())
		SET @Inc_Exp=250-RAND()*500
		SET @FuelID=CAST( (1+RAND()*(@NumberFuels-1)) as int)
		SET @TankID=CAST( (1+RAND()*(@NumberTanks-1)) as int)
		INSERT INTO dbo.Operations (FuelID, TankID, Inc_Exp, [Date])
		SELECT @FuelID, @TankID, @Inc_Exp, @odate
		
		SET @RowCount +=1
	END


COMMIT TRAN
GO
-- ================================================
-- создание представления для отбора данных всех операций
CREATE VIEW [dbo].[View_AllOperations]
AS
SELECT        dbo.Operations.OperationID, dbo.Operations.FuelID, dbo.Operations.TankID, dbo.Operations.Inc_Exp, dbo.Operations.Date, dbo.Fuels.FuelType, 
                         dbo.Tanks.TankType
FROM            dbo.Fuels INNER JOIN
                         dbo.Operations ON dbo.Fuels.FuelID = dbo.Operations.FuelID INNER JOIN
                         dbo.Tanks ON dbo.Operations.TankID = dbo.Tanks.TankID
GO
-- ================================================
-- создание хранимой процедуры для выбора данных одной или нескольких операций по заданным параметрам.

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID ( 'dbo.uspGetOperations', 'P' ) IS NOT NULL 
    DROP PROCEDURE dbo.uspGetOperations;
GO
CREATE PROCEDURE dbo.uspGetOperations
	@FuelID int =-100, 
    @FuelType nvarchar(50) ='',
	@TankID int =-100, 
    @TankType nvarchar(20) =''
AS 
    BEGIN
    
	if @TankID>0 and @FuelID>0 	
	SELECT * 
    FROM dbo.View_AllOperations
	WHERE (
	(FuelType Like (@FuelType + '%')) AND 
	(TankType Like (@TankType + '%')) AND
	(TankID=@TankID) AND
    (FuelID=@FuelID)	
	);	
	
	if @TankID>0 and @FuelID<0	
	SELECT * 
    FROM dbo.View_AllOperations
	WHERE (
	(FuelType Like (@FuelType + '%')) AND 
	(TankType Like (@TankType + '%')) AND
	(TankID=@TankID)
	);	
	
	if @TankID<0 and @FuelID>0	
	SELECT * 
    FROM dbo.View_AllOperations
	WHERE (
	(FuelType Like (@FuelType + '%')) AND 
	(TankType Like (@TankType + '%')) AND
	(FuelID=@FuelID)
	);
	
	if @TankID<0 and @FuelID<0	
	SELECT * 
    FROM dbo.View_AllOperations
	WHERE (
	(FuelType Like (@FuelType + '%')) AND 
	(TankType Like (@TankType + '%')) 
	);		
	
	END;
GO