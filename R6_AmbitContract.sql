USE [ReportMart]
GO
/****** Object:  StoredProcedure [dbo].[R6_AmbitContract]    Script Date: 7/20/2017 11:39:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		TON psk
-- Create date: 2017-07-13
-- Description:	AmbitContract
-- =============================================
ALTER PROCEDURE [dbo].[R6_AmbitContract]
(
	@MaxDateHistoryFis Date
)
AS
BEGIN
	SET NOCOUNT ON;
DECLARE @ReferenceDate VARCHAR(10)
DECLARE @Source VARCHAR(50)
DECLARE @TimeBand VARCHAR(50)
SET @ReferenceDate = @MaxDateHistoryFis
SET @Source = 'Ambit Repricing'
SET @TimeBand = 'contract'

DECLARE @R6_GROUP_DATA TABLE
	(  
		INTERNALPOSITIONID INT NOT NULL
		,REPRICEING FLOAT NULL
		,REPRICING_DATE DATE
	); 
DECLARE @R6_FILL_TIMEBAND TABLE
	(   
		INTERNALPOSITIONID INT NOT NULL
		,REPRICEING FLOAT NULL
		,REPRICING_DATE DATE
		,ATCALL FLOAT NULL
		,M0_1 FLOAT NULL
		,M1_3 FLOAT NULL
		,M3_6 FLOAT NULL
		,M6_9 FLOAT NULL
		,M9_12 FLOAT NULL
		,Y1_2 FLOAT NULL
		,Y2_3 FLOAT NULL
		,Y3_4 FLOAT NULL
		,Y4_5 FLOAT NULL
		,Y5_7 FLOAT NULL
		,Y7_10 FLOAT NULL
		,Y10_15 FLOAT NULL
		,Y15_20 FLOAT NULL
		,Y20 FLOAT NULL
	);  
DECLARE @R6_SUMMARY TABLE
	(
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,ATCALL FLOAT NULL
		,M0_1 FLOAT NULL
		,M1_3 FLOAT NULL
		,M3_6 FLOAT NULL
		,M6_9 FLOAT NULL
		,M9_12 FLOAT NULL
		,Y1_2 FLOAT NULL
		,Y2_3 FLOAT NULL
		,Y3_4 FLOAT NULL
		,Y4_5 FLOAT NULL
		,Y5_7 FLOAT NULL
		,Y7_10 FLOAT NULL
		,Y10_15 FLOAT NULL
		,Y15_20 FLOAT NULL
		,Y20 FLOAT NULL
	);
DECLARE @R6_RESULT TABLE
(   
	MAPPING_ID INT NOT NULL
	,BALACNESHEETNAME VARCHAR(MAX) NULL
	,ATCALL FLOAT NULL
	,M0_1 FLOAT NULL
	,M1_3 FLOAT NULL
	,M3_6 FLOAT NULL
	,M6_9 FLOAT NULL
	,M9_12 FLOAT NULL
	,Y1_2 FLOAT NULL
	,Y2_3 FLOAT NULL
	,Y3_4 FLOAT NULL
	,Y4_5 FLOAT NULL
	,Y5_7 FLOAT NULL
	,Y7_10 FLOAT NULL
	,Y10_15 FLOAT NULL
	,Y15_20 FLOAT NULL
	,Y20 FLOAT NULL
	,NON_RATE FLOAT NULL
	,SUMMARY FLOAT NULL
);


--################################################################################ --107010400
--########################### 1 #AmbitContractTemp1 ##############################
--################################################################################
SELECT
	a.MappingID
	,b.InternalPositionId
INTO #AmbitContractTemp1
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GLAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
AND a.PlanningAccount = b.PlanningAccount COLLATE Latin1_General_CS_AS
INNER JOIN [FocusResultDB201311].[dbo].[PUB_RepricingPrincipalNominal_Latest] c
ON b.InternalPositionId = c.InternalPositionId
WHERE a.[Source] IN (@Source)
	AND a.Timeband IN (@TimeBand)
GROUP BY a.MappingID
		,b.InternalPositionId

--SELECT * FROM #AmbitContractTemp1
--################################################################################
--############################ 2 #AmbitContractTemp2 #############################
--################################################################################
SELECT
	c.InternalPositionId
	,c.Repricing
	,c.RepricingDate
INTO #AmbitContractTemp2
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GLAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
AND a.PlanningAccount = b.PlanningAccount COLLATE Latin1_General_CS_AS
INNER JOIN [FocusResultDB201311].[dbo].[PUB_RepricingPrincipalNominal_Latest] c
ON b.InternalPositionId = c.InternalPositionId
WHERE a.[Source] IN (@Source)														
	AND a.Timeband IN (@TimeBand)
	AND a.MappingID IN (SELECT DISTINCT MappingID FROM #AmbitContractTemp1)
GROUP BY 
	a.MappingID
	,a.BalanceSheetName
	,a.GLAccount
	,a.PlanningAccount
	,c.InternalPositionId
	,c.Repricing
	,c.RepricingDate

--SELECT * FROM #AmbitContractTemp2
--#################################################################################
--############################## 4 R6_FILL_TIMEBAND ###############################
--################################################################################# --FUNC [ReportMart].[dbo].[getTimeBand]
INSERT INTO @R6_FILL_TIMEBAND
SELECT
	InternalPositionId
	,Repricing
	,RepricingDate
	,[ReportMart].[dbo].[getTimeBand] ('ATCALL', Repricing, @ReferenceDate, RepricingDate)	--ทันที
	,[ReportMart].[dbo].[getTimeBand] ('M01', Repricing, @ReferenceDate, RepricingDate)		--0-1 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M13', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 1-3 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M36', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 3-6 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M69', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 6-9 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M912', Repricing, @ReferenceDate, RepricingDate)	--มากกว่า 9-12 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('Y12', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 1-2 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y23', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 2-3 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y34', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 3-4 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y45', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 4-5 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y57', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 5-7 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y710', Repricing, @ReferenceDate, RepricingDate)	--มากกว่า 7-10 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y1015', Repricing, @ReferenceDate, RepricingDate)	--มากกว่า 10-15 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y1520', Repricing, @ReferenceDate, RepricingDate)	--มากกว่า 15-20 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y20', Repricing, @ReferenceDate, RepricingDate)		--มากกว่า 20 ปีขึ้นไป
FROM #AmbitContractTemp2

--SELECT * FROM @R6_FILL_TIMEBAND
--#################################################################################
--############################## 5 R6_SUMMARY #####################################
--#################################################################################
INSERT INTO @R6_SUMMARY
SELECT
	b.MappingID
	,c.BalanceSheetName
	,SUM(ATCALL) AS ATCALL
	,SUM(M0_1) AS M0_1
	,SUM(M1_3) AS M1_3
	,SUM(M3_6) AS M3_6
	,SUM(M6_9) AS M6_9
	,SUM(M9_12) AS M9_12
	,SUM(Y1_2) AS Y1_2
	,SUM(Y2_3) AS Y2_3
	,SUM(Y3_4) AS Y3_4
	,SUM(Y4_5) AS Y4_5
	,SUM(Y5_7) AS Y5_7
	,SUM(Y7_10) AS Y7_10
	,SUM(Y10_15) AS Y10_15
	,SUM(Y15_20) AS Y15_20
	,SUM(Y20) AS Y20
FROM @R6_FILL_TIMEBAND a
INNER JOIN #AmbitContractTemp1 b
ON a.INTERNALPOSITIONID = b.InternalPositionId
INNER JOIN [ReportMart].[dbo].[DimBsReport6] c
ON b.MappingID = c.MappingID
GROUP BY b.MappingID, c.BalanceSheetName

--SELECT * FROM @R6_SUMMARY
----#################################################################################
----################################ 6 R6_RESULT ####################################
----#################################################################################
INSERT INTO @R6_RESULT
SELECT 
	MAPPING_ID
	,BALACNESHEETNAME
	,ATCALL
	,M0_1
	,M1_3
	,M3_6
	,M6_9
	,M9_12
	,Y1_2
	,Y2_3
	,Y3_4
	,Y4_5
	,Y5_7
	,Y7_10
	,Y10_15
	,Y15_20
	,Y20
	,0
	,
	(
		ATCALL + M0_1 + M1_3 + M3_6 + M6_9 + M9_12
		+ Y1_2 + Y2_3 + Y3_4 + Y4_5 + Y5_7 + Y7_10
		+ Y10_15 + Y15_20 + Y20
	)
FROM @R6_SUMMARY

--SELECT * FROM @R6_RESULT
--#################################################################################
--########################## INSERT TO FactReport6 ################################
--#################################################################################
INSERT INTO [ReportMart].[dbo].[FactReport6]
SELECT 
	@ReferenceDate AS AsOfDate
	,@ReferenceDate AS TimeFrame
	,@Source
	,@TimeBand
	,MAPPING_ID
	,BALACNESHEETNAME
	,ATCALL
	,M0_1
	,M1_3
	,M3_6
	,M6_9
	,M9_12
	,Y1_2
	,Y2_3
	,Y3_4
	,Y4_5
	,Y5_7
	,Y7_10
	,Y10_15
	,Y15_20
	,Y20
	,NON_RATE
	,SUMMARY
FROM @R6_RESULT
--################################################################################
--################################ CLEAR TEMP ####################################
--################################################################################
IF EXISTS
(
	SELECT * FROM tempdb.dbo.sysobjects
	WHERE ID IN (OBJECT_ID(N'tempdb..#AmbitContractTemp1')
		,OBJECT_ID(N'tempdb..#AmbitContractTemp2'))
)
BEGIN
DROP TABLE #AmbitContractTemp1
DROP TABLE #AmbitContractTemp2
END
END
