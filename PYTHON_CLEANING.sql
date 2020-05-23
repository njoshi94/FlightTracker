/***********************************
Procedure to create the cleaned tables after scraping websites

Not the final table 
**********************************/
CREATE OR ALTER PROCEDURE PYTHON_CLEANING 
AS
INSERT INTO Python_Cleaned
SELECT DISTINCT CONVERT(DATE, A.[date]) AS [Date], CONVERT(DATE, A.depart_date) AS Depart_Date, CONVERT(DATE, A.Return_date) AS Return_Date, A.Website,
CASE WHEN A.price = '' THEN 0 ELSE CONVERT(INT,REPLACE(RIGHT(A.price, LEN(A.Price)-1), ',', '')) END AS Price,
A.Depart_Airport, A.Depart_Airline, B.Output AS Depart_Stops, A.Depart_Total_Time, 
CAST(A.depart_time AS TIME(0)) AS Depart_Time,
A.Return_Airport, A.Return_Airline, C.Output AS Return_Stops, A.Return_Total_Time, 
CAST(A.return_time AS TIME(0)) AS Return_Time, A.URL 
-- SELECT * 
FROM Python_Precleaning A 
LEFT JOIN Stops_Conversion B 
ON A.Depart_Stops = B.Input
LEFT JOIN Stops_Conversion C 
ON A.Return_Stops = C.Input
WHERE A.Price <> '+ $0'
AND A.Price <> ''
AND A.Depart_Airport NOT IN (SELECT DISTINCT IATA_TO FROM Precleaning_base_table)
AND A.Return_Airport IN (SELECT DISTINCT IATA_TO FROM Precleaning_base_table)

--Create a historical repository if needed
INSERT INTO Python_precleaning_Hist
SELECT *
FROM Python_Precleaning 

TRUNCATE TABLE Python_Precleaning

INSERT INTO Python_Cleaned_Standard
SELECT DISTINCT CONVERT(DATE, A.[date]) AS [Date], CONVERT(DATE, A.depart_date) AS Depart_Date, CONVERT(DATE, A.Return_date) AS Return_Date, A.Website,
CASE WHEN A.price = '' THEN 0 ELSE CONVERT(INT,REPLACE(RIGHT(A.price, LEN(A.Price)-1), ',', '')) END AS Price, 
A.Depart_Airport, A.Depart_Airline, B.Output AS Depart_Stops, A.Depart_Total_Time, 
CAST(A.depart_time AS TIME(0)) AS Depart_Time,
A.Return_Airport, A.Return_Airline, C.Output AS Return_Stops, A.Return_Total_Time, 
CAST(A.return_time AS TIME(0)) AS Return_Time, A.URL 
FROM Python_Precleaning_Standard A 
LEFT JOIN Stops_Conversion B 
ON A.Depart_Stops = B.Input
LEFT JOIN Stops_Conversion C 
ON A.Return_Stops = C.Input
WHERE A.Price <> '+ $0'
AND A.Price <> ''
AND A.Depart_Airport NOT IN (SELECT DISTINCT IATA_TO FROM Precleaning_standard_table)
AND A.Return_Airport IN (SELECT DISTINCT IATA_TO FROM Precleaning_standard_table)

INSERT INTO Python_precleaning_standard_Hist
SELECT * 
FROM Python_Precleaning_standard 

TRUNCATE TABLE Python_Precleaning_Standard 