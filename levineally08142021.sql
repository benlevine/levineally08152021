--BFL, 8/14/2021
USE levineally08142021
GO

/*

	SELECT * FROM dbo.Banks
	SELECT * FROM dbo.RiskRating
	SELECT * FROM dbo.TotalAssets

	DROP TABLE dbo.Banks
	DELETE FROM dbo.RiskRating
	DELETE FROM dbo.TotalAssets
*/

--Create tables.
IF OBJECT_ID('dbo.Banks', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.Banks
	(
		id INT IDENTITY(1,1),
		BankName VARCHAR(50),
		Approved BIT
	)
END

IF OBJECT_ID('dbo.RiskRating', 'U') IS NULL
	BEGIN
		CREATE TABLE dbo.RiskRating
		(
			BankId INT,
			AsOfDate DATE,
			Rating INT
		)
	END

IF OBJECT_ID('dbo.TotalAssets', 'U') IS NULL
	BEGIN
		CREATE TABLE dbo.TotalAssets
		(
			BankId INT,
			AsOfDate DATE,
			TotalAssets FLOAT
		)
	END

IF OBJECT_ID('dbo.DailyBankLimits', 'U') IS NULL
	BEGIN
		CREATE TABLE dbo.DailyBankLimits
		(
			BankId INT,
			AsOfDate DATE,
			Limit FLOAT
		)
	END

IF OBJECT_ID('dbo.lkpRiskRating', 'U') IS NULL
	BEGIN
		CREATE TABLE dbo.lkpRiskRating
		(
			id INT IDENTITY(1, 1),
			--AsOfDate DATE,
			LowerLimit INT,
			UpperLimit INT,
			Multiplier FLOAT
		)
	END

DECLARE @TodaysDate DATE = CAST(GETDATE() AS DATE)

IF ((SELECT COUNT(1) FROM dbo.lkpRiskRating) = 0)
	INSERT dbo.lkpRiskRating
	(LowerLimit, UpperLimit, Multiplier)
	VALUES
	(-5, -3, .88),
	(-2, 0, .91),
	(1, 3, 1.05),
	(4, 6, 1.08),
	(7, 10, 1.13)

IF ((SELECT COUNT(1) FROM dbo.Banks) = 0)
	INSERT dbo.Banks
	(BankName, Approved)
	VALUES
	('Bank of America', 1),
	('Wells Fargo', 1),
	('JP Morgan', 0),
	('Royal Bank of Canada', 1),
	('Bank of Montreal', 1),
	('Citibank', 1),
	('Bank of Nova Scotia', 0),
	('Goldman Sachs', 0)
	
IF ((SELECT COUNT(1) FROM dbo.RiskRating WHERE AsOfDate = @TodaysDate) = 0)
	INSERT dbo.RiskRating
	(BankId, AsOfDate, Rating)
	VALUES
	(1, @TodaysDate, 7),
	(2, @TodaysDate, -4),
	(7, @TodaysDate, 2),
	(4, @TodaysDate, -1),
	(5, @TodaysDate, 9)

IF ((SELECT COUNT(1) FROM dbo.TotalAssets WHERE AsOfDate = @TodaysDate) = 0)
	INSERT dbo.TotalAssets
	(BankId, AsOfDate, TotalAssets)
	VALUES
	(1, @TodaysDate, 1234000),
	(2, @TodaysDate, 5657345),
	(7, @TodaysDate, 2999002),
	(4, @TodaysDate, 4346823),
	(5, @TodaysDate, 15342679)


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.CalculateApprovedBankLimits
	@BaseLimit FLOAT,
	@AssetCieling FLOAT,
	@LimitMultiplier FLOAT
AS
BEGIN
	SET NOCOUNT ON;
	--DECLARE @BaseLimit FLOAT = 2000000
	--DECLARE @AssetCieling FLOAT = 3000000
	--DECLARE @LimitMultiplier FLOAT = 1.23

	DECLARE @TodaysDate DATE = CAST(GETDATE() AS DATE)

	--CROSS JOIN banks, ratings and lkpRiskRatings
	
	SELECT b.BankName, a.Rating, FORMAT(a.TotalAssets, 'N') AS TotalAssets, FORMAT(CASE WHEN a.TotalAssets > @AssetCieling THEN a.AdjBaseLimit * @LimitMultiplier ELSE a.AdjBaseLimit END, 'N') AS CalculatedDailyLimit, FORMAT(@TodaysDate,  'D', 'en-US') AS AsOfDate
	FROM dbo.Banks b JOIN
	(
		SELECT b.id, rr.Rating,
			CASE WHEN rr.Rating >= -5 AND rr.Rating <= -3 THEN .88 * @BaseLimit
			WHEN rr.Rating >= -2 AND rr.Rating <= 0 THEN .91 * @BaseLimit
			WHEN rr.Rating >= 1 AND rr.Rating <= 3 THEN 1.05 * @BaseLimit
			WHEN rr.Rating >= 4 AND rr.Rating <= 6 THEN 1.08 * @BaseLimit
			WHEN rr.Rating >= 7 AND rr.Rating <= 10 THEN 1.13 * @BaseLimit
			ELSE 0 END AS AdjBaseLimit,
			ta.TotalAssets
		FROM dbo.Banks b LEFT JOIN dbo.RiskRating rr ON b.id = rr.BankId
		LEFT JOIN dbo.TotalAssets ta ON b.id = ta.BankId AND rr.AsOfDate = ta.AsOfDate
		WHERE b.Approved = 1 AND ta.AsOfDate = @TodaysDate
	) a ON b.id = a.id
END
GO