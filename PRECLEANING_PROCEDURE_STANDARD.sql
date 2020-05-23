/**************************************************** 
SQL Precleaning procedure - Standard

Similar process to custom procedure, but run for dates 70-90 days from current date
******************************************************/
CREATE OR ALTER PROCEDURE PRECLEANING_PROCEDURE_STANDARD  
AS
DECLARE @i INT = 0 
DECLARE @j INT = 0 
DECLARE @STRING VARCHAR(MAX)
DECLARE @DEPARTURE VARCHAR(15)
DECLARE @TANYT VARCHAR(15)
DECLARE @Start_Date DATE
DECLARE @End_Date DATE 
DECLARE @Trip_Length INT = 14

SET @DEPARTURE = 'departure'
SET @TANYT = 'TANYT'

SET @Start_Date = DATEADD(DAY, 70, CONVERT(DATE,GETDATE()))
SET @End_Date = DATEADD(DAY, 90, CONVERT(DATE,GETDATE()))


TRUNCATE TABLE Standard_URL_List
DROP TABLE IF EXISTS #TEMP 
SELECT * INTO #TEMP FROM Precleaning_Standard_Table 	
WHILE (SELECT COUNT(*) FROM #TEMP) > 0 
BEGIN
	SET @i = 0
	SET @j = 0 
	SET @STRING = (select top 1 Expedia_URL from #TEMP)
	SET @STRING = REPLACE(@STRING, @DEPARTURE, ',')
	SET @STRING = REPLACE(@STRING, @TANYT, ',')
		
	DROP TABLE IF EXISTS #Expedia_Parts 

	SELECT ROW_NUMBER() OVER(order by [value]) as rowid,value INTO #Expedia_Parts
	FROM string_split(@STRING, ',')

	WHILE @i <=  (DATEDIFF(day, @Start_Date, @End_Date) - @Trip_Length)
	BEGIN
		WHILE @j <= (DATEDIFF(day, @Start_Date, @End_Date) - @Trip_Length)
		BEGIN
			IF DATEDIFF(DAY,DATEADD(DAY, @i, @Start_Date), 
					DATEADD(DAY, -@j, @End_Date)) < @Trip_Length 
			BEGIN
				-- Blanket Do Nothing Statement 
				IF NULL = NULL PRINT NULL 
			END
			ELSE 
			BEGIN
				INSERT INTO Standard_URL_List
				SELECT TOP 1 A.IATA_FROM, A.IATA_TO, DATEADD(day, @i,@Start_Date) AS Depart_Date,
					DATEADD(day,-@j,@End_Date) AS Return_Date,
					'https:/www.kayak.com/flights/' + A.IATA_FROM + '-'+ A.IATA_TO + '/' + 
					CONVERT(VARCHAR,DATEADD(day, @i,@Start_Date))
					+ '/' + CONVERT(VARCHAR,DATEADD(day,-@j,@End_Date)) +'?sort=bestflight_a'
					AS Kayak_Link, 
					'https:/www.google.com/flights?hl=en#flt=' +
					CASE WHEN B.GOOGLE_CODE = '' THEN A.IATA_FROM ELSE '/m/' + B.GOOGLE_CODE END + '.' +
					CASE WHEN C.GOOGLE_CODE = '' THEN A.IATA_TO ELSE '/m/' + C.GOOGLE_CODE END + '.' +
					CONVERT(VARCHAR,DATEADD(day, @i,@Start_Date)) + '*' +
					CASE WHEN C.GOOGLE_CODE = '' THEN A.IATA_TO ELSE '/m/' + C.GOOGLE_CODE END + '.' +
					CASE WHEN B.GOOGLE_CODE = '' THEN A.IATA_FROM ELSE '/m/' + B.GOOGLE_CODE END + '.' +
					CONVERT(VARCHAR,DATEADD(day,-@j, @End_Date)) + ';c:USD;e:1;sd:1;t:f'
					AS Google_Link, (SELECT [value]  FROM #Expedia_Parts WHERE rowid = 5)
					+ 'departure%3A' + CONVERT(VARCHAR,MONTH(DATEADD(day, @i, @Start_date))) +
					'%2F' +  CONVERT(VARCHAR,DAY(DATEADD(day, @i,@End_Date))) + '%2F' +
						CONVERT(VARCHAR,YEAR(DATEADD(day, @i,@Start_Date))) + 'TANYT' +
						(SELECT [value] FROM #Expedia_Parts WHERE rowid = 3) + 'departure%3A' + 
						CONVERT(VARCHAR,MONTH(DATEADD(day, -@j, @End_date))) +
					'%2F' +  CONVERT(VARCHAR,DAY(DATEADD(day, -@j, @End_Date))) + '%2F' +
						CONVERT(VARCHAR,YEAR(DATEADD(day, -@j,@End_Date))) + 'TANYT' +
						(SELECT [value] FROM #Expedia_Parts WHERE rowid = 4) AS Expedia_Link 
				FROM #TEMP A 
				LEFT JOIN IATA_Codes B 
				ON A.IATA_FROM = B.IATA_CODE
				LEFT JOIN IATA_Codes C 
				ON A.IATA_TO = C.IATA_CODE
			END
		SET @j = @j + 1 
		END
	SET @j = 0 
	SET @i = @i + 1
	END 
	DELETE TOP(1) FROM #TEMP 
END
