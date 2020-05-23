/**************************
Procedure to create final SQL Table 

Only runs if there is new data to add to avoid accidentally truncating final table 
************************/
CREATE OR ALTER PROCEDURE CREATE_FINAL_TABLE
AS

IF (SELECT COUNT(*) FROM Python_Preds) > 0 and (SELECT COUNT(*) FROM Python_Preds_Standard) > 0 
BEGIN
TRUNCATE TABLE Flight_Data_Final 

INSERT INTO Flight_Data_Final 
SELECT * 
FROM
(
SELECT 'Actual' as [Type], 'Standard' as [Standard_Or_Custom], A.* 
FROM Python_Cleaned_Standard A  
UNION
SELECT 'Prediction' as [Type], 'Standard' as [Standard_Or_Custom], B.Pred_Date, '1900-01-01', '1900-01-01', 
'', B.Price, '','','','','', B.Return_Airport, '', '','','',''
FROM Python_Preds_Standard B 
UNION
SELECT 'Actual' as [Type], 'Custom' as [Standard_Or_Custom], A.* 
FROM Python_Cleaned A  
UNION
SELECT 'Prediction' as [Type], 'Custom' as [Standard_Or_Custom], B.Pred_Date, '1900-01-01', '1900-01-01', 
'', B.Price, '','','','','', B.Return_Airport, '', '','','',''
FROM Python_Preds B 
) A 

TRUNCATE TABLE Python_Preds
TRUNCATE TABLE Python_Preds_Standard 
END 