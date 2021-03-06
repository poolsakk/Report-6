USE [ReportMart]
GO
/****** Object:  StoredProcedure [dbo].[R6_FIS1M]    Script Date: 7/20/2017 11:46:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		TON psk
-- Create date: 2017-07-05
-- Description:	FIS 0-1 Month

-- 2017-07-06 Update: Create Parameter Get Date
-- 2017-07-07 Update: Remove Group by data
-- =============================================
ALTER PROCEDURE [dbo].[R6_FIS1M]
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
SET @Source = 'FIS'
SET @TimeBand = '0-1 เดือน'

DECLARE @R6_GROUP_DATA TABLE
	(  
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,PRINCIPALOUTSTANDING FLOAT NULL 
		--,REPRICING_DATE DATE
	);
DECLARE @R6_FILL_TIMEBAND TABLE
	(   
		MAPPING_ID INT NOT NULL
		,BALACNESHEETNAME VARCHAR(MAX) NULL
		,GL_ACCOUNT INT NOT NULL
		,PLANNING_ACCOUNT VARCHAR(MAX) NULL
		,PRINCIPALOUTSTANDING FLOAT NULL
		,M0_1 FLOAT NULL
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

--#############################################
--############ 1 #Fis1MTemp1 #################
--#############################################
SELECT DISTINCT
	a.MappingID
	,a.GLAccount
INTO #Fis1MTemp1
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [ReportMart].[dbo].[HistoryFIS] b
ON a.GLAccount = b.GLAccount
WHERE a.[Source] IN (@Source) AND a.Timeband IN (@TimeBand) AND b.AsofDate = @ReferenceDate
--#############################################
--############ 2 R6_GROUP_DATA ################
--#############################################
INSERT INTO @R6_GROUP_DATA
SELECT 
	a.MappingID
	,a.BalanceSheetName
	,a.GLAccount
	,a.PlanningAccount
	,b.PrincipalOutstanding
FROM [ReportMart].[dbo].[DimBsReport6] a
INNER JOIN [ReportMart].[dbo].[HistoryFIS] b
ON a.GLAccount = b.GLAccount
WHERE a.[Source] IN (@Source) 
	AND a.Timeband IN (@TimeBand)
	AND a.MappingID IN (SELECT DISTINCT MappingID FROM #Fis1MTemp1)
	AND a.GLAccount IN (SELECT DISTINCT GLAccount FROM #Fis1MTemp1)
	AND b.AsofDate = @ReferenceDate
--GROUP BY a.MappingID
--		,a.BalanceSheetName
--		,a.GLAccount
--		,a.PlanningAccount
--		,b.PrincipalOutstanding

--SELECT * FROM @R6_GROUP_DATA
--#############################################
--############# 3 R6_FILL_TIMEBAND ############
--#############################################
INSERT INTO @R6_FILL_TIMEBAND
SELECT
	MAPPING_ID 
	,BALACNESHEETNAME 
	,GL_ACCOUNT
	,PLANNING_ACCOUNT
	,PRINCIPALOUTSTANDING
	,PRINCIPALOUTSTANDING AS M0_1
FROM @R6_GROUP_DATA

--SELECT * FROM @R6_GROUP_DATA
--#############################################
--############# 4 R6_SUMMARY ##################
--#############################################
INSERT INTO @R6_SUMMARY
SELECT
	MAPPING_ID 
	,BALACNESHEETNAME
	, 0, SUM(M0_1), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
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
WHERE ID IN (OBJECT_ID(N'tempdb..#Fis1MTemp1'))
)
BEGIN
DROP TABLE #Fis1MTemp1
END

END
