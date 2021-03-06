USE [ReportMart]
GO
/****** Object:  StoredProcedure [dbo].[R6_DerivedFIS]    Script Date: 7/20/2017 11:46:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		TON psk
-- Create date: 2017-07-05
-- Description:	DerivedFIS

-- 2017-07-06 Update: Create Parameter Get Date
-- =============================================
ALTER PROCEDURE [dbo].[R6_DerivedFIS]
(
	@MaxDateHistoryFis Date
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @ReferenceDate VARCHAR(10)
DECLARE @Source1 VARCHAR(50), @Source2 VARCHAR(50)
DECLARE @TimeBand1 VARCHAR(50), @TimeBand2 VARCHAR(50), @TimeBand3 VARCHAR(50)
SET @ReferenceDate = @MaxDateHistoryFis
SET @Source1 = 'Ambit Repricing'
SET @Source2 = 'FIS'
SET @TimeBand1 = 'DerivedBonanza'
SET @TimeBand2 = 'Non-rate sensitive'
SET @TimeBand3 = 'DerivedFIS'

DECLARE @R6_GROUP_DATA TABLE
	(  
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,AMORTIZEDCOSTS FLOAT NULL
		,REPRICING_DATE DATE NULL
	);  
DECLARE @R6_FILL_TIMEBAND TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
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
	,AMORTIZEDCOSTS FLOAT NULL
	,PRINCIPALOUTSTANDING FLOAT NULL
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
DECLARE @R6_CAL_WEIGHT TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,AMORTIZEDCOSTS FLOAT NULL
		,PRINCIPALOUTSTANDING FLOAT NULL
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
DECLARE @R6_CAL_PRINCIPAL TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,AMORTIZEDCOSTS FLOAT NULL
		,PRINCIPALOUTSTANDING FLOAT NULL
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

--##############################################################
--#################### 1 #DerivedBonanzaTemp ###################
--##############################################################
SELECT DISTINCT
	a.Parent_GlAccount
	,a.TimeBand
INTO #DerivedBonanzaTemp
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GlAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
WHERE a.[Source] IN (@Source1, @Source2)
	AND a.Timeband IN (@TimeBand1, @TimeBand2)
	AND a.Parent_GlAccount IS NOT NULL
--#############################################################
--##################### 2 #DerivedFisTemp #####################
--#############################################################
SELECT DISTINCT
		a.GlAccount
INTO #DerivedFisTemp
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.Parent_GlAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
WHERE a.[Source] IN (@Source2)
	AND a.Timeband IN (@TimeBand3)
	AND a.Parent_GlAccount IN (SELECT DISTINCT Parent_GlAccount FROM #DerivedBonanzaTemp)
--###########################################################################
--####################### 3 #DerivedBonanzaDataTemp #########################
--###########################################################################
SELECT 
	a.MappingID
	,a.BalanceSheetName
	,a.Parent_GlAccount
	,a.PlanningAccount
	,b.InternalPositionId
	,d.AmortizedCosts
	,c.RepricingDate
INTO #DerivedBonanzaDataTemp
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.Parent_GlAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
AND a.PlanningAccount = b.PlanningAccount COLLATE Latin1_General_CS_AS
INNER JOIN [FocusResultDB201311].[dbo].[PUB_RepricingPrincipalNominal_Latest] c
ON b.InternalPositionId = c.InternalPositionId
INNER JOIN [FocusResultDB201311].[dbo].[PUB_TimeResults_Latest] d
ON c.InternalPositionId = d.InternalPositionId
WHERE a.[Source] IN (@Source1)
	AND a.Timeband IN (@TimeBand1)
	AND a.Parent_GlAccount IN (SELECT DISTINCT Parent_GlAccount FROM #DerivedBonanzaTemp WHERE Timeband = @TimeBand1)
GROUP BY a.MappingID
	,a.BalanceSheetName
	,a.Parent_GlAccount
	,a.PlanningAccount
	,b.InternalPositionId
	,d.AmortizedCosts
	,c.RepricingDate
--##################################################################
--################# 4 insert NonRateFisDataTemp ####################
--##################################################################
INSERT INTO @R6_RESULT
SELECT
	a.MappingID
	,a.BalanceSheetName
	,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	,SUM(a.PrincipalOutstanding) AS NON_RATE
	,SUM(a.PrincipalOutstanding) AS SUMMARY
FROM 
(
	SELECT
		a.MappingID
		,a.BalanceSheetName
		,a.Parent_GlAccount
		,a.PlanningAccount
		,b.PrincipalOutstanding
	FROM [ReportMart].[dbo].[DimBsReport6] a
	INNER JOIN [ReportMart].[dbo].[HistoryFIS] b
	ON a.GlAccount = b.GLAccount
	WHERE b.AsOfDate = @ReferenceDate
		AND a.Parent_GlAccount IN (SELECT DISTINCT Parent_GlAccount FROM #DerivedBonanzaTemp WHERE TimeBand = @TimeBand2)
		AND a.TimeBand = @TimeBand3
	GROUP BY a.MappingID
			,a.BalanceSheetName
			,a.Parent_GlAccount
			,a.PlanningAccount
			,b.PrincipalOutstanding
) a
GROUP BY a.MappingID, a.BalanceSheetName
--##################################################################
--##################### 5 #DerivedFisDataTemp ######################
--##################################################################
SELECT
	a.MappingID
	,a.BalanceSheetName
	,a.Parent_GlAccount
	,SUM(a.PrincipalOutstanding) PrincipalOutstanding
INTO #DerivedFisDataTemp
FROM
(
	SELECT
		a.MappingID
		,a.BalanceSheetName
		,a.Parent_GlAccount
		,a.GlAccount
		,b.PrincipalOutstanding
	FROM [ReportMart].[dbo].[DimBsReport6] a
	INNER JOIN [ReportMart].[dbo].[HistoryFIS] b
	ON a.GlAccount = b.GLAccount
	WHERE b.AsOfDate = @ReferenceDate
		AND a.GlAccount IN (SELECT GlAccount FROM #DerivedFisTemp)
	GROUP BY 
			a.MappingID
			,a.BalanceSheetName
			,a.Parent_GlAccount
			,a.GlAccount
			,b.PrincipalOutstanding
) a
GROUP BY a.MappingID, a.BalanceSheetName, a.Parent_GlAccount

--SELECT * FROM  #DerivedFisDataTemp
--#############################################
--############## 6 R6_GROUP_DATA ##############
--#############################################
INSERT INTO @R6_GROUP_DATA
SELECT
	MappingID
	,BalanceSheetName
	,Parent_GlAccount
	,PlanningAccount
	,AmortizedCosts
	,RepricingDate
FROM #DerivedBonanzaDataTemp 
--WHERE MappingID IN 
--(
--	SELECT DISTINCT MappingID FROM #DerivedFisTemp3
--)

--SELECT * FROM @R6_GROUP_DATA
--#################################################################################
--############################## 7 R6_FILL_TIMEBAND ###############################
--################################################################################# --FUNC [ReportMart].[dbo].[getTimeBand]
INSERT INTO @R6_FILL_TIMEBAND
SELECT
	MAPPING_ID 
	,BALACNESHEETNAME 
	,GL_ACCOUNT
	,PLANNING_ACCOUNT
	,AMORTIZEDCOSTS
	,REPRICING_DATE
	,[ReportMart].[dbo].[getTimeBand] ('ATCALL', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)	--ทันที
	,[ReportMart].[dbo].[getTimeBand] ('M01', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--0-1 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M13', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 1-3 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M36', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 3-6 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M69', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 6-9 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('M912', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 9-12 เดือน
	,[ReportMart].[dbo].[getTimeBand] ('Y12', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 1-2 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y23', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 2-3 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y34', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 3-4 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y45', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 4-5 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y57', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 5-7 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y710', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 7-10 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y1015', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 10-15 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y1520', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 15-20 ปี
	,[ReportMart].[dbo].[getTimeBand] ('Y20', AMORTIZEDCOSTS, @ReferenceDate, REPRICING_DATE)		--มากกว่า 20 ปีขึ้นไป
FROM @R6_GROUP_DATA

--SELECT * FROM @R6_FILL_TIMEBAND
--###############################################
--############### 8 R6_SUM_BUDGET ###############
--###############################################
INSERT INTO @R6_SUM_BUDGET
SELECT
	b.MappingID
	,b.BalanceSheetName
	,SUM(a.AMORTIZEDCOSTS) AS AMORTIZEDCOSTS
	,b.PrincipalOutstanding AS PRINCIPALOUTSTANDING
	,SUM(a.ATCALL) AS ATCALL
	,SUM(a.M0_1) AS M0_1
	,SUM(a.M1_3) AS M1_3
	,SUM(a.M3_6) AS M3_6
	,SUM(a.M6_9) AS M6_9
	,SUM(a.M9_12) AS M9_12
	,SUM(a.Y1_2) AS Y1_2
	,SUM(a.Y2_3) AS Y2_3
	,SUM(a.Y3_4) AS Y3_4
	,SUM(a.Y4_5) AS Y4_5
	,SUM(a.Y5_7) AS Y5_7
	,SUM(a.Y7_10) AS Y7_10
	,SUM(a.Y10_15) AS Y10_15
	,SUM(a.Y15_20) AS Y15_20
	,SUM(a.Y20) AS Y20
FROM @R6_FILL_TIMEBAND a
INNER JOIN #DerivedFisDataTemp b
ON a.GL_ACCOUNT = b.Parent_GlAccount
GROUP BY b.MappingID, b.BalanceSheetName, b.PrincipalOutstanding

--SELECT * FROM @R6_SUM_BUDGET
--###############################################
--############### 9 R6_CAL_WEIGHT ###############
--############################################### --FUNC [ReportMart].[dbo].[getWeightAmount] 
INSERT INTO @R6_CAL_WEIGHT
SELECT 
	MAPPING_ID
	,BALACNESHEETNAME
	,AMORTIZEDCOSTS
	,PRINCIPALOUTSTANDING
	,[ReportMart].[dbo].[getWeightAmount] (ATCALL, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (M0_1, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (M1_3, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (M3_6, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (M6_9, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (M9_12, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y1_2, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y2_3, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y3_4, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y4_5, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y5_7, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y7_10, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y10_15, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y15_20, AMORTIZEDCOSTS)		--WEIGHT
	,[ReportMart].[dbo].[getWeightAmount] (Y20, AMORTIZEDCOSTS)			--WEIGHT
FROM @R6_SUM_BUDGET

--SELECT * FROM @R6_CAL_WEIGHT
--#################################################
--############## 10 R6_CAL_PRINCIPAL ##############
--#################################################
INSERT INTO @R6_CAL_PRINCIPAL
SELECT 
	MAPPING_ID
	,BALACNESHEETNAME
	,AMORTIZEDCOSTS
	,PRINCIPALOUTSTANDING
	,(PRINCIPALOUTSTANDING * ATCALL)
	,(PRINCIPALOUTSTANDING * M0_1)
	,(PRINCIPALOUTSTANDING * M1_3)
	,(PRINCIPALOUTSTANDING * M3_6)
	,(PRINCIPALOUTSTANDING * M6_9) 
	,(PRINCIPALOUTSTANDING * M9_12)
	,(PRINCIPALOUTSTANDING * Y1_2)
	,(PRINCIPALOUTSTANDING * Y2_3)
	,(PRINCIPALOUTSTANDING * Y3_4)
	,(PRINCIPALOUTSTANDING * Y4_5)
	,(PRINCIPALOUTSTANDING * Y5_7)
	,(PRINCIPALOUTSTANDING * Y7_10)
	,(PRINCIPALOUTSTANDING * Y10_15)
	,(PRINCIPALOUTSTANDING * Y15_20)
	,(PRINCIPALOUTSTANDING * Y20)
FROM @R6_CAL_WEIGHT a

--SELECT * FROM @R6_CAL_PRINCIPAL
--###############################################
--################# 11 R6_RESULT ################
--###############################################
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
FROM @R6_CAL_PRINCIPAL

--SELECT * FROM @R6_RESULT
--################################################
--############# INSERT TO FactReport6 ############
--################################################
INSERT INTO [ReportMart].[dbo].[FactReport6]
SELECT 
	@ReferenceDate AS AsOfDate
	,@ReferenceDate AS TimeFrame
	,'FIS'
	,'DerivedFIS'
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
--#########################################################
--##################### CLEAR TEMP ########################
--#########################################################
IF EXISTS
(
	SELECT *
	FROM tempdb.dbo.sysobjects
	WHERE ID IN (OBJECT_ID(N'tempdb..#DerivedBonanzaTemp')
		,OBJECT_ID(N'tempdb..#DerivedFisTemp')
		,OBJECT_ID(N'tempdb..#DerivedBonanzaDataTemp')
		,OBJECT_ID(N'tempdb..#DerivedFisDataTemp'))
)
BEGIN
	DROP TABLE #DerivedBonanzaTemp
	DROP TABLE #DerivedFisTemp
	DROP TABLE #DerivedBonanzaDataTemp
	DROP TABLE #DerivedFisDataTemp
END
 
END
