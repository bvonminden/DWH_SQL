USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_DMBuildEncounter]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:        Kyla Krause
-- Create date: 11/5/2015
-- Description:   Pulling data for Dm Encounter Table.  It pulls data from HVE, AE, CAB, Weekly Supervison and Team Meetings and Case Conf.
-- =============================================
CREATE PROCEDURE [dbo].[usp_DMBuildEncounter]
      -- Add the parameters for the stored procedure here
      --<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
      --<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
      -- SET NOCOUNT ON added to prevent extra result sets from
      -- interfering with SELECT statements.
      SET NOCOUNT ON;
IF OBJECT_ID('tempdb..##Encounter') IS NOT NULL
    DROP TABLE ##Encounter

Create Table ##Encounter
(
      [SurveyResponseID] [int] ,
      [ClientID] [int] ,
      [ProgramID] [int] ,
      [SiteID] [int] ,
      [NurseID] [int] ,
      [NurseSupervisorID] [int] ,
      [SurveyDate] [date] ,
      [StartTime] [varchar](50) ,
      [EndTime] [varchar](50) ,
      [VisitDuration] [varchar](50) ,
      [Participant] [varchar](3000),
      [PersonalHealthDomain] [int] ,
      [EnvironHealthDomain] [int] ,
      [LifeCourseDomain] [int] ,
      [MaternalDomain] [int] ,
      [FriendFamilyDomain] [int] ,
      [VisitSchedule] [varchar](50) ,
      [VisitStatus] [varchar](100) ,
      [VisitLocation] [varchar](100) ,
      [Form] [varchar](50),
      [VisitInHome] [tinyint],
      [Rankdup] [tinyint] ,
      [Countdup] [tinyint],
      [MeetingDate] [date] ,
      [Type] [varchar](50) 
      )

Insert into ##Encounter
SELECT 
      HVES.SurveyResponseID
      ,HVES.CL_EN_GEN_ID      CLID
      ,HVES.ProgramID
      ,HVES.SiteID
      ,HVES.NURSE_PERSONAL_0_NAME
      ,NULL [NurseSupervisorID]
      ,HVES.SurveyDate
      ,HVES.CLIENT_TIME_0_START_VISIT     
      ,HVES.CLIENT_TIME_1_END_VISIT
      ,HVES.CLIENT_TIME_1_DURATION_VISIT
      ,HVES.CLIENT_ATTENDEES_0_AT_VISIT
      ,HVES.CLIENT_DOMAIN_0_PERSHLTH_VISIT
      ,HVES.CLIENT_DOMAIN_0_ENVIRONHLTH_VISIT
      ,HVES.CLIENT_DOMAIN_0_LIFECOURSE_VISIT
      ,HVES.CLIENT_DOMAIN_0_MATERNAL_VISIT
      ,HVES.CLIENT_DOMAIN_0_FRNDFAM_VISIT
      ,HVES.CLIENT_VISIT_SCHEDULE
      ,HVES.CLIENT_COMPLETE_0_VISIT
      ,HVES.CLIENT_LOCATION_0_VISIT --
      ,'HVES' Form
      ,CASE WHEN HVES.CLIENT_LOCATION_0_VISIT LIKE 'Client%' THEN 1 ELSE 0 END Home_Visit
      ,RANK() OVER(Partition By HVES.NURSE_PERSONAL_0_NAME,HVES.SurveyDate,HVES.CLIENT_TIME_0_START_VISIT,HVES.ProgramID,HVES.SiteID Order By HVES.CL_EN_GEN_ID,HVES.SurveyResponseID DESC) Rank_dup
      ,SUM(1) OVER(Partition By HVES.NURSE_PERSONAL_0_NAME,HVES.SurveyDate,HVES.CLIENT_TIME_0_START_VISIT,HVES.ProgramID,HVES.SiteID) Count_dup
      ,NULL [MeetingDate]
      ,NULL [Type]
FROM Home_Visit_Encounter_Survey HVES
WHERE 
HVES.NURSE_PERSONAL_0_NAME IS NOT NULL
AND HVES.ProgramID IS NOT NULL
AND HVES.CL_EN_GEN_ID IS NOT NULL

--Load Alternative_Encounter_Survey
Insert into ##Encounter
SELECT  
      AE.SurveyResponseID
      ,AE.CL_EN_GEN_ID 
      ,AE.ProgramID
      ,AE.SiteID
      ,AE.NURSE_PERSONAL_0_NAME
      ,NULL [NurseSupervisorID]
      ,AE.SurveyDate
      ,AE.CLIENT_TIME_0_START_ALT   
      ,AE.CLIENT_TIME_1_END_ALT
      ,AE.CLIENT_TIME_1_DURATION_ALT
      ,AE.CLIENT_TALKED_0_WITH_ALT
      ,AE.CLIENT_DOMAIN_0_PERSONAL_HLTH_ALT
      ,AE.CLIENT_DOMAIN_0_ENVIRONHLTH_ALT
      ,AE.CLIENT_DOMAIN_0_LIFECOURSE_ALT
      ,AE.CLIENT_DOMAIN_0_MATERNAL_ALT
      ,AE.CLIENT_DOMAIN_0_FRNDFAM_ALT
      ,AE.CLIENT_VISIT_SCHEDULE
      ,CASE 
            When (AE.CLIENT_TALKED_0_WITH_ALT LIKE 'CLIENT;%' OR AE.CLIENT_TALKED_0_WITH_ALT = 'CLIENT') then 'Completed' 
            END CLIENT_COMPLETE_0_VISIT
      ,AE.CLIENT_ALTERNATIVE_ENCOUNTER_0_TYPE_ALT
      ,'AltE' Form
      ,NULL [VisitInHome]
      ,RANK() OVER(Partition By AE.NURSE_PERSONAL_0_NAME,AE.SurveyDate,AE.CLIENT_TIME_0_START_ALT,AE.ProgramID,AE.SiteID Order By AE.CL_EN_GEN_ID,AE.SurveyResponseID DESC) Rank_dup
      ,SUM(1) OVER(Partition By AE.NURSE_PERSONAL_0_NAME,AE.SurveyDate,AE.CLIENT_TIME_0_START_ALT,AE.ProgramID,AE.SiteID) Count_dup
      ,NULL [MeetingDate]
      ,NULL [Type]
FROM Alternative_Encounter_Survey AE
WHERE AE.ProgramID IS NOT NULL
      AND CL_EN_GEN_ID IS NOT NULL

--Load Weekly_Supervision_Survey
Insert into ##Encounter
SELECT 
      WSS.SurveyResponseID
      ,NULL [ClientID]
      ,WSS.ProgramID
      ,WSS.SiteID
      ,WSS.NURSE_PERSONAL_0_NAME 
      ,WSS.NURSE_SUPERVISION_0_STAFF_SUP 
      ,WSS.SurveyDate
      ,NULL [StartTime]
      ,NULL [EndTime]
      ,NULL [VisitDuration]
      ,NULL [Participant]
      ,NULL [PersonalHealthDomain]
      ,NULL [EnvironHealthDomain]
      ,NULL [LifeCourseDomain]
      ,NULL [MaternalDomain]
      ,NULL [FriendFamilyDomain]
      ,NULL [VisitSchedule]
      ,NULL [VisitStatus]
      ,NULL [VisitLocation]
      ,'Weekly_Supervision' [Form]
      ,NUll [VisitInHome]
      ,NULL [Rankdup]
      ,NULL [Countdup]
      ,WSS.FORM_RECORD_0_COMPLETED_DATE
      ,'Weekly_Supervision' [Type]
FROM Weekly_Supervision_Survey WSS
WHERE 
      WSS.SurveyDate BETWEEN '19960101' AND '20301231'

--Load Team_Meetings_Conf_Survey
Insert into ##Encounter
SELECT 
      TMCS.SurveyResponseID
      ,NULL [ClientID]
      ,TMCS.ProgramID
      ,TMCS.SiteID
      ,NULL [NurseID]
      ,NULL [NurseSupervisorID]
      ,TMCS.SurveyDate
      ,NULL [StartTime]
      ,NULL [EndTime]
      ,NULL [VisitDuration]
      ,NULL [Participant]
      ,NULL [PersonalHealthDomain]
      ,NULL [EnvironHealthDomain]
      ,NULL [LifeCourseDomain]
      ,NULL [MaternalDomain]
      ,NULL [FriendFamilyDomain]
      ,NULL [VisitSchedule]
      ,NULL [VisitStatus]
      ,NULL [VisitLocation]
      ,'Team_Meetings_Conf_Survey' [Form]
      ,NUll [VisitInHome]
      ,NULL [Rankdup]
      ,NULL [Countdup]
      ,TMCS.SurveyDate  
      ,AGENCY_MEETING_0_TYPE [Type]
FROM Team_Meetings_Conf_Survey TMCS
WHERE 
      TMCS.SurveyDate BETWEEN '19960101' AND '20301231'

--Load CAB_MEETINGS_SURVEY
Insert into ##Encounter
SELECT 
CAB.SurveyResponseID
      ,NULL [ClientID]
      ,CAB.ProgramID
      ,CAB.SiteID
      ,NULL [NurseID]
      ,NULL [NurseSupervisorID]
      ,CAB.SurveyDate
      ,NULL [StartTime]
      ,NULL [EndTime]
      ,NULL [VisitDuration]
      ,NULL [Participant]
      ,NULL [PersonalHealthDomain]
      ,NULL [EnvironHealthDomain]
      ,NULL [LifeCourseDomain]
      ,NULL [MaternalDomain]
      ,NULL [FriendFamilyDomain]
      ,NULL [VisitSchedule]
      ,NULL [VisitStatus]
      ,NULL [VisitLocation]
      ,'CAB_MEETINGS_SURVEY' [Form]
      ,NUll [VisitInHome]
      ,NULL [Rankdup]
      ,NULL [Countdup]
      ,CAB.CAB_MTG_DATE [MeetingDate]     
      ,'CAB' [Type]
FROM CAB_MEETINGS_SURVEY CAB
WHERE 
      CAB.SurveyDate BETWEEN '19960101' AND '20301231'
      
Select 
      [SurveyResponseID]
      ,[ClientID]
      ,[ProgramID]
      ,[SiteID]
      ,[NurseID]
      ,[NurseSupervisorID]
      ,[SurveyDate] 
      ,[StartTime]
      ,[EndTime]
      ,[VisitDuration]
      ,[Participant]
      ,[PersonalHealthDomain]
      ,[EnvironHealthDomain]
      ,[LifeCourseDomain]
      ,[MaternalDomain]
      ,[FriendFamilyDomain]
      ,[VisitSchedule]
      ,[VisitStatus]
      ,[VisitLocation]
      ,[Form]
      ,[VisitInHome]
      ,[Rankdup]
      ,[Countdup]
      ,[MeetingDate]
      ,[Type]
from ##Encounter

END
GO
