USE [ReportMart]
GO
/****** Object:  StoredProcedure [dbo].[CspPopulateFact6]    Script Date: 7/20/2017 11:46:36 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		TON psk
-- Create date: 2017-07-05
-- Description:	Report6 All Logic

--Update 2017-07-05: FIX NPI Duplicate
-- =============================================
ALTER PROCEDURE [dbo].[CspPopulateFact6]
AS
BEGIN
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @MaxDate DATE
SELECT @MaxDate = MAX(AsOfDate) FROM [ReportMart].[dbo].[HistoryFis]

BEGIN TRY
	--EXEC [ReportMart].[dbo].[R6_DerivedBonanzaDIFF] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_DerivedBonanza] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_DerivedFIS] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_FIS1M] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_FISNonRate] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_AmbitNPI20Y] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_AmbitNPLNonRate] @MaxDateHistoryFis = @MaxDate
	--EXEC [ReportMart].[dbo].[R6_AmbitContract] @MaxDateHistoryFis = @MaxDate

--########## NPI Update Duplicate ##########
	UPDATE [FactReport6]
	SET AtCall =	(CASE WHEN a.AtCall > b.AtCall THEN a.AtCall + b.AtCall ELSE b.AtCall + a.AtCall END)
		,M0_1 =		(CASE WHEN a.M0_1 > b.M0_1 THEN a.M0_1 + b.M0_1 ELSE b.M0_1 + a.M0_1 END)
		,M1_3 =		(CASE WHEN a.M1_3 > b.M1_3 THEN a.M1_3 + b.M1_3 ELSE b.M1_3 + a.M1_3 END)
		,M3_6 =		(CASE WHEN a.M3_6 > b.M3_6 THEN a.M3_6 + b.M3_6 ELSE b.M3_6 + a.M3_6 END)
		,M6_9 =		(CASE WHEN a.M6_9 > b.M6_9 THEN a.M6_9 + b.M6_9 ELSE b.M6_9 + a.M6_9 END)
		,M9_12 =	(CASE WHEN a.M9_12 > b.M9_12 THEN a.M9_12 + b.M9_12 ELSE b.M9_12 + a.M9_12 END)
		,Y1_2 =		(CASE WHEN a.Y1_2 > b.Y1_2 THEN a.Y1_2 + b.Y1_2 ELSE b.Y1_2 + a.Y1_2 END)
		,Y2_3 =		(CASE WHEN a.Y2_3 > b.Y2_3 THEN a.Y2_3 + b.Y2_3 ELSE b.Y2_3 + a.Y2_3 END)
		,Y3_4 =		(CASE WHEN a.Y3_4 > b.Y3_4 THEN a.Y3_4 + b.Y3_4 ELSE b.Y3_4 + a.Y3_4 END)
		,Y4_5 =		(CASE WHEN a.Y4_5 > b.Y4_5 THEN a.Y4_5 + b.Y4_5 ELSE b.Y4_5 + a.Y4_5 END)
		,Y5_7 =		(CASE WHEN a.Y5_7 > b.Y5_7 THEN a.Y5_7 + b.Y5_7 ELSE b.Y5_7 + a.Y5_7 END)
		,Y7_10 =	(CASE WHEN a.Y7_10 > b.Y7_10 THEN a.Y7_10 + b.Y7_10 ELSE b.Y7_10 + a.Y7_10 END)
		,Y10_15 =	(CASE WHEN a.Y10_15 > b.Y10_15 THEN a.Y10_15 + b.Y10_15 ELSE b.Y10_15 + a.Y10_15 END)
		,Y15_20 =	(CASE WHEN a.Y15_20 > b.Y15_20 THEN a.Y15_20 + b.Y15_20 ELSE b.Y15_20 + a.Y15_20 END)
		,Y20 =		(CASE WHEN a.Y20 > b.Y20 THEN a.Y20 + b.Y20 ELSE b.Y20 + a.Y20 END)
		,Summary =	(CASE WHEN a.Summary > b.Summary THEN a.Summary + b.Summary ELSE b.Summary + a.Summary END)
	FROM [FactReport6] a
	LEFT JOIN 
	(
		SELECT * FROM [dbo].[FactReport6] 
		WHERE [Source] = 'Ambit Repricing'
			AND TimeBand NOT IN ('>20 ปี')
			AND MappingID IN 
			(
				SELECT DISTINCT MappingID 
				FROM [FactReport6] 
				GROUP BY MappingID 
				HAVING COUNT(MappingID) > 1
			)
	) b
	ON a.MappingID = b.MappingID
	WHERE a.MappingID IN 
		(
			SELECT DISTINCT MappingID 
			FROM [FactReport6] 
			GROUP BY MappingID 
			HAVING COUNT(MappingID) > 1
		)
		AND a.[Source] = 'Ambit Repricing'
		AND a.TimeBand = '>20 ปี';

--########## NPI Delete Duplicate ##########
	DELETE FROM [ReportMart].[dbo].[FactReport6] 
	WHERE MappingID IN 
		(
			SELECT DISTINCT MappingID 
			FROM [FactReport6] 
			GROUP BY MappingID 
			HAVING COUNT(MappingID) > 1
		)
		AND [Source] = 'Ambit Repricing'
		AND TimeBand NOT IN ('>20 ปี');

--###########################################
--########### Sum MappingIDHeader ###########
--###########################################
INSERT INTO [ReportMart].[dbo].[FactReport6]
SELECT
	@MaxDate AS AsOfDate
	,@MaxDate AS TimeFrame
	,NULL
	,NULL
	,a.HeaderMappingID, a.BalanceSheetName
	,SUM(a.[AtCall]), SUM(a.[M0_1]), SUM(a.[M1_3]), SUM(a.[M3_6]), SUM(a.[M6_9]), SUM(a.[M9_12])
	,SUM(a.[Y1_2]), SUM(a.[Y2_3]), SUM(a.[Y3_4]), SUM(a.[Y4_5]), SUM(a.[Y5_7]), SUM(a.[Y7_10])
	,SUM(a.[Y10_15]), SUM(a.[Y15_20]), SUM(a.[Y20]), SUM(a.[Non-Rate])
	,(
		SUM(a.[AtCall]) + SUM(a.[M0_1]) + SUM(a.[M1_3]) + SUM(a.[M3_6]) + SUM(a.[M6_9]) + SUM(a.[M9_12])
		+ SUM(a.[Y1_2]) + SUM(a.[Y2_3])	+ SUM(a.[Y3_4]) + SUM(a.[Y4_5])	+ SUM(a.[Y5_7]) + SUM(a.[Y7_10])
		+ SUM(a.[Y10_15]) + SUM(a.[Y15_20])	+ SUM(a.[Y20]) + SUM(a.[Non-Rate])
	) AS SUMMARY
FROM
(	
	SELECT 
		b.HeaderMappingID, c.BalanceSheetName
		,a.[AtCall], a.[M0_1]
		,a.[M1_3], a.[M3_6]
		,a.[M6_9], a.[M9_12]
		,a.[Y1_2], a.[Y2_3]
		,a.[Y3_4], a.[Y4_5]
		,a.[Y5_7], a.[Y7_10]
		,a.[Y10_15], a.[Y15_20]
		,a.[Y20], a.[Non-Rate]
	FROM FactReport6 a
	INNER JOIN getHeaderMappingID() b
	ON a.MappingID = b.MappingID
	INNER JOIN DimBsReport6 c
	ON b.HeaderMappingID = c.MappingID
	GROUP BY b.HeaderMappingID, c.BalanceSheetName, a.[AtCall], a.[M0_1], a.[M1_3], a.[M3_6]
			,a.[M6_9], a.[M9_12], a.[Y1_2], a.[Y2_3], a.[Y3_4], a.[Y4_5], a.[Y5_7], a.[Y7_10]
			,a.[Y10_15], a.[Y15_20], a.[Y20], a.[Non-Rate]
) a 
GROUP BY a.HeaderMappingID, a.BalanceSheetName
	COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ErrorNumber  
        ,ERROR_SEVERITY() AS ErrorSeverity  
        ,ERROR_STATE() AS ErrorState  
        ,ERROR_PROCEDURE() AS ErrorProcedure  
        ,ERROR_LINE() AS ErrorLine  
        ,ERROR_MESSAGE() AS ErrorMessage;
	ROLLBACK TRANSACTION;
END CATCH

END
