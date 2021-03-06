USE [ReportMart]
GO
/****** Object:  StoredProcedure [dbo].[R6_DerivedBonanzaDIFF]    Script Date: 7/20/2017 11:46:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		TON psk
-- Create date: 2017-07-05
-- Description:	DerivedBonanzaDIFF

-- 2017-07-06 Update: Create Parameter Get Date
-- 2017-07-07 Update: Join Planning Account table A&B
-- =============================================
ALTER PROCEDURE [dbo].[R6_DerivedBonanzaDIFF]
(
	@MaxDateHistoryFis Date
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;
DECLARE @ReferenceDate VARCHAR(10)
DECLARE @Source VARCHAR(50)
DECLARE @TimeBand VARCHAR(50)
SET @ReferenceDate = @MaxDateHistoryFis
SET @Source = 'Ambit Repricing'
SET @TimeBand = 'DerivedBonanza'

DECLARE @R6_GROUP_DATA TABLE
	(  
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,REPRICEING FLOAT NULL
		,AMORTIZEDCOSTS FLOAT NULL
		,REPRICING_DATE DATE NULL
	);  
DECLARE @R6_FILL_TIMEBAND TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,REPRICEING FLOAT NULL
		,AMORTIZEDCOSTS FLOAT NULL
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
DECLARE @R6_SUM_BUDGET TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,REPRICEING FLOAT NULL
		,AMORTIZEDCOSTS FLOAT NULL
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
DECLARE @R6_CAL_DIFF_WEIGHT TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,REPRICEING FLOAT NULL
		,AMORTIZEDCOSTS FLOAT NULL
		,DIFF FLOAT NULL
		,ATCALL FLOAT NULL
		,ATCALL_W FLOAT NULL
		,M0_1 FLOAT NULL
		,M0_1_W FLOAT NULL
		,M1_3 FLOAT NULL
		,M1_3_W FLOAT NULL
		,M3_6 FLOAT NULL
		,M3_6_W FLOAT NULL
		,M6_9 FLOAT NULL
		,M6_9_W FLOAT NULL
		,M9_12 FLOAT NULL
		,M9_12_W FLOAT NULL
		,Y1_2 FLOAT NULL
		,Y1_2_W FLOAT NULL
		,Y2_3 FLOAT NULL
		,Y2_3_W FLOAT NULL
		,Y3_4 FLOAT NULL
		,Y3_4_W FLOAT NULL
		,Y4_5 FLOAT NULL
		,Y4_5_W FLOAT NULL
		,Y5_7 FLOAT NULL
		,Y5_7_W FLOAT NULL
		,Y7_10 FLOAT NULL
		,Y7_10_W FLOAT NULL
		,Y10_15 FLOAT NULL
		,Y10_15_W FLOAT NULL
		,Y15_20 FLOAT NULL
		,Y15_20_W FLOAT NULL
		,Y20 FLOAT NULL
		,Y20_W FLOAT NULL
	);
DECLARE @R6_SUM_DIFF TABLE
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

--###################################################
--############## 1 #DerivedBzDiffTemp1 ##############
--###################################################
SELECT DISTINCT
	a.MappingID
	,a.GLAccount
INTO #DerivedBzDiffTemp1
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GLAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
WHERE a.[Source] IN (@Source) AND a.Timeband IN (@TimeBand)
--###################################################
--############# 2 #DerivedBzDiffTemp2 ###############
--###################################################
SELECT
	a.MappingID
	,a.BalanceSheetName
	,a.GLAccount
	,a.PlanningAccount
	,b.InternalPositionId
	,c.Repricing
	,d.AmortizedCosts
	,c.RepricingDate
INTO #DerivedBzDiffTemp2
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GLAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
AND a.PlanningAccount = b.PlanningAccount COLLATE Latin1_General_CS_AS
INNER JOIN [FocusResultDB201311].[dbo].[PUB_RepricingPrincipalNominal_Latest] c
ON b.InternalPositionId = c.InternalPositionId
INNER JOIN [FocusResultDB201311].[dbo].[PUB_TimeResults_Latest] d
ON c.InternalPositionId = d.InternalPositionId
WHERE a.[Source] IN (@Source)														
	AND a.Timeband IN (@TimeBand)
	AND a.MappingID IN (SELECT DISTINCT MappingID FROM #DerivedBzDiffTemp1)
	AND a.GLAccount IN (SELECT DISTINCT GLAccount FROM #DerivedBzDiffTemp1)
GROUP BY 
	a.MappingID
	,a.BalanceSheetName
	,a.GLAccount
	,a.PlanningAccount
	,b.InternalPositionId
	,c.Repricing
	,d.AmortizedCosts
	,c.RepricingDate
--###################################################
--############ 3 #DerivedBzDiffTemp3 ################
--################################################### --เอาค่า (DIFF)
SELECT 
	a.MappingID
	,SUM(a.Repricing) Repricing
	,SUM(a.AmortizedCosts) AmortizedCosts
INTO #DerivedBzDiffTemp3
FROM
	(
		SELECT * FROM #DerivedBzDiffTemp2
	) a 
GROUP BY a.MappingID
HAVING SUM(a.Repricing) > SUM(a.AmortizedCosts) OR SUM(a.Repricing) < SUM(a.AmortizedCosts)
--############################################
--########### 4 R6_GROUP_DATA ################
--############################################
INSERT INTO @R6_GROUP_DATA
SELECT
	MappingID
	,BalanceSheetName
	,GLAccount
	,PlanningAccount
	,Repricing
	,AmortizedCosts
	,RepricingDate
FROM #DerivedBzDiffTemp2 
WHERE MappingID IN 
(
	SELECT DISTINCT MappingID FROM #DerivedBzDiffTemp3
)

--SELECT * FROM @R6_GROUP_DATA
--############################################
--########### 5 R6_FILL_TIMEBAND #############
--############################################ --FUNC [ReportMart].[dbo].[getTimeBand]
INSERT INTO @R6_FILL_TIMEBAND
SELECT
	MAPPING_ID 
	,BALACNESHEETNAME 
	,GL_ACCOUNT
	,PLANNING_ACCOUNT
	,REPRICEING
	,AMORTIZEDCOSTS
	,REPRICING_DATE
	,[ReportMart].[dbo].[getTimeBand] ('ATCALL', REPRICEING, @ReferenceDate, REPRICING_DATE)	--ทันที
	,[ReportMart].[dbo].[getTimeBand] ('M01', REPRICEING, @ReferenceDate, REPRICING_DATE)		--0-1 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M13', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 1-3 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M36', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 3-6 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M69', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 6-9 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M912', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 9-12 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('Y12', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 1-2 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y23', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 2-3 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y34', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 3-4 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y45', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 4-5 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y57', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 5-7 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y710', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 7-10 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y1015', REPRICEING, @ReferenceDate, REPRICING_DATE)	--มากกว่า 10-15 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y1520', REPRICEING, @ReferenceDate, REPRICING_DATE)	--มากกว่า 15-20 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y20', REPRICEING, @ReferenceDate, REPRICING_DATE)		--มากกว่า 20 ปีขึ้นไป
FROM @R6_GROUP_DATA

--SELECT * FROM @R6_GROUP_TIMEBAND
--############################################
--########### 6 R6_SUM_BUDGET ################
--############################################
INSERT INTO @R6_SUM_BUDGET
SELECT
	MAPPING_ID
	,BALACNESHEETNAME
	,SUM(REPRICEING) AS REPRICEING
	,SUM(AMORTIZEDCOSTS) AS AMORTIZEDCOSTS
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
FROM @R6_FILL_TIMEBAND
GROUP BY MAPPING_ID, BALACNESHEETNAME

--SELECT * FROM @R6_GROUP_SUM
--############################################
--########### 7 R6_CAL_DIFF_WEIGHT ########### --FUNC [ReportMart].[dbo].[getDiffAmount]
--############################################ --FUNC [ReportMart].[dbo].[getWeightAmount]
INSERT INTO @R6_CAL_DIFF_WEIGHT
SELECT 
	MAPPING_ID
	,BALACNESHEETNAME
	,REPRICEING
	,AMORTIZEDCOSTS
	,[ReportMart].[dbo].[getDiffAmount] (REPRICEING, AMORTIZEDCOSTS)		--DIFFAMOUNT
	,ATCALL,	[ReportMart].[dbo].[getWeightAmount] (ATCALL, REPRICEING)	--WEIGHT
	,M0_1,		[ReportMart].[dbo].[getWeightAmount] (M0_1, REPRICEING)		--WEIGHT
	,M1_3,		[ReportMart].[dbo].[getWeightAmount] (M1_3, REPRICEING)		--WEIGHT
	,M3_6,		[ReportMart].[dbo].[getWeightAmount] (M3_6, REPRICEING)		--WEIGHT
	,M6_9,		[ReportMart].[dbo].[getWeightAmount] (M6_9, REPRICEING)		--WEIGHT
	,M9_12,		[ReportMart].[dbo].[getWeightAmount] (M9_12, REPRICEING)	--WEIGHT
	,Y1_2,		[ReportMart].[dbo].[getWeightAmount] (Y1_2, REPRICEING)		--WEIGHT
	,Y2_3,		[ReportMart].[dbo].[getWeightAmount] (Y2_3, REPRICEING)		--WEIGHT
	,Y3_4,		[ReportMart].[dbo].[getWeightAmount] (Y3_4, REPRICEING)		--WEIGHT
	,Y4_5,		[ReportMart].[dbo].[getWeightAmount] (Y4_5, REPRICEING)		--WEIGHT
	,Y5_7,		[ReportMart].[dbo].[getWeightAmount] (Y5_7, REPRICEING)		--WEIGHT
	,Y7_10,		[ReportMart].[dbo].[getWeightAmount] (Y7_10, REPRICEING)	--WEIGHT
	,Y10_15,	[ReportMart].[dbo].[getWeightAmount] (Y10_15, REPRICEING)	--WEIGHT
	,Y15_20,	[ReportMart].[dbo].[getWeightAmount] (Y15_20, REPRICEING)	--WEIGHT
	,Y20,		[ReportMart].[dbo].[getWeightAmount] (Y20, REPRICEING)		--WEIGHT
FROM @R6_SUM_BUDGET

--SELECT * FROM @R6_CAL_DIFF_WEIGHT
--############################################
--########### 8 R6_SUM_DIFF ##################
--############################################ --FUNC [ReportMart].[dbo].[getSummary]
INSERT INTO @R6_SUM_DIFF
SELECT
	MAPPING_ID
	,BALACNESHEETNAME
	,[ReportMart].[dbo].[getSummary] (ATCALL, DIFF, ATCALL_W)	--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (M0_1, DIFF, M0_1_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (M1_3, DIFF, M1_3_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (M3_6, DIFF, M3_6_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (M6_9, DIFF, M6_9_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (M9_12, DIFF, M9_12_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y1_2, DIFF, Y1_2_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y2_3, DIFF, Y2_3_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y3_4, DIFF, Y3_4_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y4_5, DIFF, Y4_5_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y5_7, DIFF, Y5_7_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y7_10, DIFF, Y7_10_W)		--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y10_15, DIFF, Y10_15_W)	--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y15_20, DIFF, Y15_20_W)	--SUM_DIFF
	,[ReportMart].[dbo].[getSummary] (Y20, DIFF, Y20_W)			--SUM_DIFF
FROM @R6_CAL_DIFF_WEIGHT

--SELECT * FROM @R6_CAL_SUM_DIFF ORDER BY MAPPING_ID ASC
--############################################
--########### 9 R6_RESULT ####################
--############################################
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
FROM @R6_SUM_DIFF
--############################################
--########### INSERT TO FactReport6 ##########
--############################################
INSERT INTO [ReportMart].[dbo].[FactReport6]
SELECT 
	@ReferenceDate AS AsOfDate
	,@ReferenceDate AS TimeFrame
	,@Source
	,@TimeBand+'(DIFF)'
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
--############################################
--########### CLEAR TEMP #####################
--############################################
IF EXISTS
(
SELECT *
FROM tempdb.dbo.sysobjects
WHERE ID IN (OBJECT_ID(N'tempdb..#DerivedBzDiffTemp1')
	,OBJECT_ID(N'tempdb..#DerivedBzDiffTemp2')
	,OBJECT_ID(N'tempdb..#DerivedBzDiffTemp3'))
)
BEGIN
DROP TABLE #DerivedBzDiffTemp1
DROP TABLE #DerivedBzDiffTemp2
DROP TABLE #DerivedBzDiffTemp3
END

END
