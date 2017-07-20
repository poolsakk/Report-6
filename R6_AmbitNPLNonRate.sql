USE [ReportMart]
GO
/****** Object:  StoredProcedure [dbo].[R6_AmbitNPLNonRate]    Script Date: 7/20/2017 11:45:48 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		TON psk
-- Create date: 2017-07-05
-- Description:	Ambit Reprice NPL NonRate-Sensitive

-- 2017-07-06 Update: Create Parameter Get Date
-- =============================================
ALTER PROCEDURE [dbo].[R6_AmbitNPLNonRate]
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
DECLARE @PlanningAccount VARCHAR(50)
DECLARE @TimeBand VARCHAR(50)
SET @ReferenceDate = @MaxDateHistoryFis
SET @Source = 'Ambit Repricing'
SET @PlanningAccount = 'NPL'
SET @TimeBand = 'Non-rate sensitive'

DECLARE @R6_GROUP_DATA TABLE
	(  
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,AMORTIZEDCOSTS FLOAT NULL
		--,REPRICING_DATE DATE
	);
DECLARE @R6_FILL_TIMEBAND TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,AMORTIZEDCOSTS FLOAT NULL
		,NON_RATE FLOAT NULL
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
		,NON_RATE FLOAT NULL
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

--#################################################
--############ 1 #AmbitNPLNonRateTemp1 ############
--#################################################
SELECT DISTINCT
	a.MappingID
	,a.GLAccount
INTO #AmbitNPLNonRateTemp1
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GLAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
WHERE a.[Source] IN (@Source) AND a.Timeband IN (@TimeBand) AND a.PlanningAccount IN (@PlanningAccount)
--###################################################
--############ 2 #AmbitNPLNonRateTemp2 ##############
--###################################################
SELECT 
	a.MappingID
	,a.BalanceSheetName
	,a.GLAccount
	,a.PlanningAccount
	,b.InternalPositionId
	,c.AmortizedCosts
INTO #AmbitNPLNonRateTemp2
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [FocusResultDB201311].[dbo].[PUB_Positions] b
ON a.GLAccount = b.RA_GLAccountID COLLATE Latin1_General_CS_AS
AND a.PlanningAccount = b.PlanningAccount COLLATE Latin1_General_CS_AS 
INNER JOIN [FocusResultDB201311].[dbo].[PUB_TimeResults_Latest] c
ON b.InternalPositionId = c.InternalPositionId
WHERE a.[Source] IN (@Source) 
	AND a.Timeband IN (@TimeBand)
	AND a.PlanningAccount IN (@PlanningAccount)
	AND a.MappingID IN (SELECT DISTINCT MappingID FROM #AmbitNPLNonRateTemp1)
	AND a.GLAccount IN (SELECT DISTINCT GLAccount FROM #AmbitNPLNonRateTemp1)
GROUP BY a.MappingID
		,a.BalanceSheetName
		,a.GLAccount
		,a.PlanningAccount
		,b.InternalPositionId
		,c.AmortizedCosts
--############################################
--############# 3 R6_GROUP_DATA ##############
--############################################
INSERT INTO @R6_GROUP_DATA
SELECT
	MappingID
	,BalanceSheetName
	,GLAccount
	,PlanningAccount
	,AmortizedCosts
FROM #AmbitNPLNonRateTemp2 
WHERE PlanningAccount IN (@PlanningAccount)

--SELECT * FROM @R6_GROUP_DATA
--#############################################
--############# 4 R6_FILL_TIMEBAND ############
--#############################################
INSERT INTO @R6_FILL_TIMEBAND
SELECT
	MAPPING_ID 
	,BALACNESHEETNAME 
	,GL_ACCOUNT
	,PLANNING_ACCOUNT
	,AMORTIZEDCOSTS
	,AMORTIZEDCOSTS AS NON_RATE
FROM @R6_GROUP_DATA

--SELECT * FROM @R6_GROUP_DATA
--#############################################
--############# 4 R6_SUMMARY ##################
--#############################################
INSERT INTO @R6_SUMMARY
SELECT
	MAPPING_ID 
	,BALACNESHEETNAME
	, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, SUM(NON_RATE)
FROM @R6_FILL_TIMEBAND
GROUP BY MAPPING_ID, BALACNESHEETNAME

--SELECT * FROM @R6_SUMMARY
--#############################################
--############# 5 R6_RESULT ###################
--#############################################
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
	,NON_RATE
	,
	(
		ATCALL + M0_1 + M1_3 + M3_6 + M6_9 + M9_12
		+ Y1_2 + Y2_3 + Y3_4 + Y4_5 + Y5_7 + Y7_10
		+ Y10_15 + Y15_20 + Y20 + NON_RATE
	)
FROM @R6_SUMMARY

--SELECT * FROM @R6_RESULT
--#############################################
--########### INSERT TO FactReport6 ###########
--#############################################
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
--#############################################
--############### CLEAR TEMP ##################
--#############################################
IF EXISTS
(
SELECT *
FROM tempdb.dbo.sysobjects
WHERE ID IN (OBJECT_ID(N'tempdb..#AmbitNPLNonRateTemp1'), 
OBJECT_ID(N'tempdb..#AmbitNPLNonRateTemp2'))
)
BEGIN
DROP TABLE #AmbitNPLNonRateTemp1
DROP TABLE #AmbitNPLNonRateTemp2
END

END
