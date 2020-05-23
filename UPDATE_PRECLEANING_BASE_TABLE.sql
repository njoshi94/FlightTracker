/*************************************
Procedure to update Precleaning Base Table

Ensures that Precleaning only runs as needed, instead of daily 
*************************************/
CREATE OR ALTER PROCEDURE UPDATE_PRECLEANING_BASE_TABLE 
@IATA_FROM VARCHAR(3),
@IATA_TO VARCHAR(3),
@Depart_Date DATE,
@Return_Date DATE,
@Min_Trip_Length INT,
@Expedia_Link VARCHAR(500),
@Delete VARCHAR(10) = ''
AS
	IF @Delete <> 'Delete'
	BEGIN
		INSERT INTO PRECLEANING_BASE_TABLE
		VALUES
		(@IATA_FROM, @IATA_TO, @Depart_Date, @Return_Date, @Min_Trip_Length, @Expedia_Link)

		UPDATE X 
		SET [Update] = 1 
		-- SELECT *
		FROM UpdatesNeeded X 
	END
	ELSE 
	BEGIN
		DELETE FROM PRECLEANING_BASE_TABLE 
		WHERE IATA_FROM = @IATA_FROM AND IATA_TO = @IATA_TO

		UPDATE X 
		SET [Update] = 1 
		-- SELECT *
		FROM UpdatesNeeded X 
	END
GO