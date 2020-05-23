/***************************************************** 
SQL Precleaning procedure 

Procedure to generate URLs as needed for custom tables
Standard tables procedure is run separately 
******************************************************/
CREATE OR ALTER PROCEDURE PRECLEANING_PROCEDURE
AS 
DECLARE @i INT = 0 
DECLARE @j INT = 0 
DECLARE @STRING VARCHAR(max)
DECLARE @DEPARTURE VARCHAR(15)
DECLARE @TANYT VARCHAR(15)

-- Variables to create custom Expedia Links
SET @DEPARTURE = 'departure'
SET @TANYT = 'TANYT'

--If no updates needed, only check if there are incompatible dates 
IF (SELECT TOP 1 [Update] FROM UpdatesNeeded) = 0
BEGIN
	WHILE (SELECT MIN(Depart_Date) FROM Custom_URL_LIST) <= CONVERT(DATE,GETDATE())
	BEGIN
		DELETE 
		-- SELECT * 
		FROM Custom_URL_List
		WHERE Depart_Date = (SELECT MIN(Depart_Date) FROM Custom_URL_List)
	END	
END 
ELSE
BEGIN
	--If updates needed, recreates the entire base table 
	TRUNCATE TABLE Custom_URL_List
	DROP TABLE IF EXISTS #TEMP 
	SELECT * INTO #TEMP FROM Precleaning_Base_Table 	
	WHILE (SELECT COUNT(*) FROM #TEMP) > 0 
	BEGIN
		SET @i = 0
		SET @j = 0 
		SET @STRING = (select top 1 Expedia_Link from #TEMP)
		SET @STRING = REPLACE(@STRING, @DEPARTURE, ',')
		SET @STRING = REPLACE(@STRING, @TANYT, ',')
		
		DROP TABLE IF EXISTS #Expedia_Parts 

		SELECT ROW_NUMBER() OVER(order by [value]) as rowid,value INTO #Expedia_Parts
		FROM string_split(@STRING, ',')

		WHILE @i <= (SELECT TOP 1 DATEDIFF(day, Depart_Date, Return_Date) - Min_Trip_Length FROM #TEMP)
		BEGIN
			WHILE @j <= (SELECT TOP 1 DATEDIFF(day, Depart_Date, Return_Date) - Min_Trip_Length FROM #TEMP)
			BEGIN
				IF (DATEADD(day, @i, (SELECT TOP 1 Depart_Date FROM #TEMP) )) <= CONVERT(DATE, GETDATE())
				BEGIN
					-- Blanket Do Nothing Statement 
					IF NULL = NULL PRINT NULL 
				END
				ELSE IF DATEDIFF(DAY,DATEADD(DAY, @i, (SELECT TOP 1 Depart_Date FROM #TEMP)), 
						DATEADD(DAY, -@j, (SELECT TOP 1 Return_Date FROM #TEMP))) < (SELECT TOP 1 Min_Trip_Length FROM #TEMP) 
				BEGIN
					-- Blanket Do Nothing Statement 
					IF NULL = NULL PRINT NULL 
				END
				ELSE 
				BEGIN
					INSERT INTO Custom_URL_LIST
					SELECT TOP 1 A.IATA_FROM, A.IATA_TO, DATEADD(day, @i,(SELECT TOP 1 Depart_Date FROM #TEMP)) AS Depart_Date,
						DATEADD(day,-@j,(SELECT TOP 1 Return_Date FROM #TEMP)) AS Return_Date,
						'https:/www.kayak.com/flights/' + A.IATA_FROM + '-'+ A.IATA_TO + '/' + 
						CONVERT(VARCHAR,DATEADD(day, @i,(SELECT TOP 1 Depart_Date FROM #TEMP)))
						+ '/' + CONVERT(VARCHAR,DATEADD(day,-@j,(SELECT TOP 1 Return_Date FROM #TEMP))) +'?sort=bestflight_a'
						AS Kayak_Link, 
						'https:/www.google.com/flights?hl=en#flt=' +
						CASE WHEN B.GOOGLE_CODE = '' THEN A.IATA_FROM ELSE '/m/' + B.GOOGLE_CODE END + '.' +
						CASE WHEN C.GOOGLE_CODE = '' THEN A.IATA_TO ELSE '/m/' + C.GOOGLE_CODE END + '.' +
						CONVERT(VARCHAR,DATEADD(day, @i,(SELECT TOP 1 Depart_Date FROM #TEMP))) + '*' +
						CASE WHEN C.GOOGLE_CODE = '' THEN A.IATA_TO ELSE '/m/' + C.GOOGLE_CODE END + '.' +
						CASE WHEN B.GOOGLE_CODE = '' THEN A.IATA_FROM ELSE '/m/' + B.GOOGLE_CODE END + '.' +
						CONVERT(VARCHAR,DATEADD(day,-@j,(SELECT TOP 1 Return_Date FROM #TEMP))) + ';c:USD;e:1;sd:1;t:f'
						AS Google_Link, (SELECT [value]  FROM #Expedia_Parts WHERE rowid = 5)
						+ 'departure%3A' + CONVERT(VARCHAR,MONTH(DATEADD(day, @i,(SELECT TOP 1 Depart_Date FROM #TEMP)))) +
						'%2F' +  CONVERT(VARCHAR,DAY(DATEADD(day, @i,(SELECT TOP 1 Depart_Date FROM #TEMP)))) + '%2F' +
						 CONVERT(VARCHAR,YEAR(DATEADD(day, @i,(SELECT TOP 1 Depart_Date FROM #TEMP)))) + 'TANYT' +
						 (SELECT [value] FROM #Expedia_Parts WHERE rowid = 3) + 'departure%3A' + 
						 CONVERT(VARCHAR,MONTH(DATEADD(day, -@j,(SELECT TOP 1 Return_Date FROM #TEMP)))) +
						'%2F' +  CONVERT(VARCHAR,DAY(DATEADD(day, -@j,(SELECT TOP 1 Return_Date FROM #TEMP)))) + '%2F' +
						 CONVERT(VARCHAR,YEAR(DATEADD(day, -@j,(SELECT TOP 1 Return_Date FROM #TEMP)))) + 'TANYT' +
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
	UPDATE X 
	SET X.[Update] = 0
	-- SELECT * 
	FROM UpdatesNeeded X 
END

EXEC PRECLEANING_PROCEDURE_STANDARD