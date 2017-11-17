USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_InfantChar]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_OE_InfantChar]
(    
    @StartDate          date 
    ,@EndDate           date 
    ,@ParentEntity      varchar(4000)
    ,@REName            varchar(50) 
    ,@ReportType        varchar(50) 
)

AS
DECLARE 
    @rptStartDate       date 
    ,@rptEndDate        date 
    ,@rptParentEntity   varchar(4000)
    ,@rptREName         varchar(50) 
    ,@rptReportType     varchar(50) 
SET @rptStartDate       = @StartDate
SET @rptEndDate         = @EndDate
SET @rptParentEntity    = @ParentEntity
SET @rptREName          = @REName
SET @rptReportType      = @ReportType
/************ FOR TESTING **************/
--DECLARE 
--    @rptStartDate     DATE            = '20140101'
--    ,@rptEndDate      DATE            = '20170316' --*/CAST( CURRENT_TIMESTAMP AS DATE )
--    ,@rptParentEntity Varchar(50)     = 139
--    ,@rptREName       Varchar(50)     = Null
--    ,@rptReportType   Varchar(50)     = 3 -- 1==National, 2==State, 3==Site, 4==Program
/****************************************/
;WITH ProgramSite AS
(
    SELECT
          [SiteID]
          ,[ProgramID]
          ,[Program_ID_NHV]
          ,[StateID]
          ,[AGENCY_INFO_0_NAME]                 AS AgencyName
          ,[US State]                           AS USState
          ,[Abbreviation]                       AS StateAbbreviation
          ,dbo.udf_fn_GetCleanProg( ProgramID ) AS ProgramName
    FROM [dbo].[UV_PAS]
) -- SELECT * FROM ProgramSite -- for testing
, Client AS
(
    SELECT 
          [Client_Id]
          ,[CaseNumber]
          ,[Site_ID]
          ,CAST( [DOB]                 AS DATE ) AS ClientDOB
          ,CAST( CL.INFANT_BIRTH_0_DOB AS DATE ) AS InfantDOB
    FROM [dbo].[Clients] CL 
    WHERE Site_ID IN ( SELECT SiteID FROM [dbo].[UV_PAS] ) 
/******************* For Testing *****************************/
      --AND ( Client_ID  In ( 592886, 604876, 605677 )
      --      OR CaseNumber In ( 592886, 604876, 605677  )
      --    )
/*************************************************************/
) -- SELECT * FROM Client -- for testing
, HomeVisitProgram AS 
(
    SELECT ED.CLID
           ,ED.CaseNumber 
           ,COUNT(     RecID            ) OVER( Partition By ED.CaseNumber )           AS NumPrograms
           ,CAST( MIN( ProgramStartDate ) OVER( Partition By ED.CaseNumber ) AS DATE ) AS FirstStartDate
           ,CAST(      ProgramStartDate                                      AS DATE ) AS ProgramStartDate 
           ,CAST( MAX( ProgramStartDate ) OVER( Partition By ED.CaseNumber ) AS DATE ) AS LastStartDate
           ,CAST( MIN( EndDate          ) OVER( Partition By ED.CaseNumber ) AS DATE ) AS FirstEndDate
           ,CAST(      EndDate                                               AS DATE ) AS ProgramEndDate 
           ,CAST( CASE WHEN EXISTS( SELECT * 
                                    FROM EnrollmentAndDismissal AS HasNull 
                                      INNER JOIN UV_PAS AS PS ON PS.Program_ID_NHV = HasNull.ProgramID 
                                    WHERE HasNull.CLID = ED.CLID 
                                      AND HasNull.ProgramStartDate = ED.ProgramStartDate 
                                        AND HasNull.EndDate Is Null 
                                  ) THEN Null 
                       ELSE MAX( EndDate    ) OVER( Partition By ED.CaseNumber ) 
                  END AS DATE 
            ) AS LastEndDate
           ,ED.SiteID
           ,ED.ProgramID
    FROM EnrollmentAndDismissal AS ED
      INNER JOIN UV_PAS PS ON PS.Program_ID_NHV = ED.ProgramID
        INNER JOIN Clients CL ON CL.Client_Id = ED.CLID 
        --AND CL.Site_ID = ED.SiteID
) -- SELECT * FROM HomeVisitProgram -- for testing
, LastHomeOrAltEnc AS
(
    SELECT Visit.CL_EN_GEN_ID
           ,MAX( Visit.SurveyDate ) AS LastVisit
    FROM 
    (
        SELECT CAST( [SurveyDate] AS DATE ) AS SurveyDate
               ,[CL_EN_GEN_ID]
        FROM [Alternative_Encounter_Survey] AS AE 
          INNER JOIN Clients AS CL ON CL.Client_Id = AE.CL_EN_GEN_ID
              INNER JOIN  EnrollmentAndDismissal AS ED ON AE.CL_EN_GEN_ID = ED.CLID /*mbrown, 2017-03-29*/--AND CL.Site_ID = ED.SiteID
                AND ( SurveyDate Between ProgramStartDate And EndDate OR ( SurveyDate >= ProgramStartDate AND EndDate Is Null ) )
                  INNER JOIN UV_PAS PS ON PS.Program_ID_NHV = ED.ProgramID 
        WHERE CLIENT_TALKED_0_WITH_ALT LIKE 'CLIENT;%' OR CLIENT_TALKED_0_WITH_ALT = 'CLIENT'
    UNION
        SELECT CAST( [SurveyDate] AS DATE ) AS SurveyDate
               ,[CL_EN_GEN_ID]
        FROM [Home_Visit_Encounter_Survey] AS HE
          INNER JOIN Clients AS CL ON CL.Client_Id = HE.CL_EN_GEN_ID
              INNER JOIN  EnrollmentAndDismissal AS ED ON HE.CL_EN_GEN_ID = ED.CLID /*mbrown, 2017-03-29*/--AND CL.Site_ID = ED.SiteID
                AND ( SurveyDate Between ProgramStartDate And EndDate OR ( SurveyDate >= ProgramStartDate AND EndDate Is Null ) )
                  INNER JOIN UV_PAS PS ON PS.Program_ID_NHV = ED.ProgramID 
        WHERE CLIENT_COMPLETE_0_VISIT = 'Completed'
    ) AS Visit
    GROUP BY Visit.CL_EN_GEN_ID
/************ mbrown, 2017-03-29 ************
 Removed logic to include Site and Program
 ProgramID for last encounter. RTemoved from
 expressions above, leaving here as comment.
 ********************************************
            --,Visit.SiteID
            --,Visit.ProgramID
 ********************************************/    
) -- SELECT * FROM LastHomeOrAltEnc -- for testing
, MaternalHealth AS
(
    SELECT DISTINCT
           CAST( [SurveyDate] AS DATE ) AS SurveyDate
           ,[CL_EN_GEN_ID]
           ,MH.[SiteID]
           ,MH.[ProgramID]
           ,CAST( [CLIENT_HEALTH_PREGNANCY_0_EDD] AS DATE ) AS DueDate
    FROM [dbo].[Maternal_Health_Survey] AS MH
      INNER JOIN EnrollmentAndDismissal AS ED ON  MH.CL_EN_GEN_ID = ED.CaseNumber
        INNER JOIN Clients AS CL ON MH.CL_EN_GEN_ID = CL.CaseNumber
) -- SELECT * FROM MaternalHealth -- for testing

SELECT DISTINCT
    @rptStartDate AS ReportStartDate
    ,@rptEndDate  AS ReportEndDate
    ,Exc.StateAbbreviation
    ,Exc.USState
    ,Exc.StateID
    ,Exc.SiteID
    ,Exc.AgencyName
    ,Exc.ProgramID
    ,Exc.ProgramName
    ,Exc.ReportingEntity
    --,Exc.CLID             -- mbrown, this one is for debugging 
    ,Exc.CaseNumber AS CLID -- this one is the "Client ID" for this report
    ,Exc.FirstStartDate
    --,Exc.ProgramStartDate
    ,Exc.LastStartDate
    --,Exc.FirstEndDate
    --,Exc.ProgramEndDate
    ,Exc.LastEndDate
    ,Exc.InfantDOB
    ,Exc.DueDate
    ,Exc.ClientDOB
    ,Exc.LastVisit
    ,CONVERT(VARCHAR(50),Category) Category
    ,Error
FROM
(
    SELECT 
        RtExpr.StateAbbreviation
        ,RtExpr.USState
        ,RtExpr.StateID
        ,RtExpr.SiteID
        ,RtExpr.AgencyName
        ,RtExpr.ProgramID
        ,RtExpr.ProgramName
        ,RtExpr.ReportingEntity
        ,RtExpr.CLID
        ,RtExpr.CaseNumber
        ,RtExpr.FirstStartDate
        ,RtExpr.ProgramStartDate
        ,RtExpr.LastStartDate
        ,RtExpr.FirstEndDate
        ,RtExpr.ProgramEndDate 
        ,RtExpr.LastEndDate
        ,RtExpr.InfantDOB
        ,RtExpr.DueDate
        ,RtExpr.ClientDOB
        ,RtExpr.LastVisit
/******* Infant date of birth compared to client's program start date ********/
        ,CASE WHEN DATEDIFF( Day, RtExpr.InfantDOB, RtExpr.FirstStartDate ) Between   0 And 17 
                THEN 1--N'Yellow - First Program Start Date is 0 to 2 & 1/2 weeks after infant DOB as recorded'
              WHEN DATEDIFF( Day, RtExpr.InfantDOB, RtExpr.FirstStartDate ) Between  18 And 34 
                THEN 2--N'Orange - First Program Start Date is 2 & 1/2 to 5 weeks after infant DOB as recorded'
              WHEN DATEDIFF( Day, RtExpr.InfantDOB, RtExpr.FirstStartDate ) >=       35 
                THEN 3--   N'Red – First Program Start Date is 5 or more weeks after infant DOB as recorded'
              WHEN DATEDIFF( Day, RtExpr.FirstStartDate, RtExpr.InfantDOB ) Between 240 And 259 
                THEN 4--N'Yellow - First Program Start Date is 240 to 259 days before infant DOB as recorded'
              WHEN DATEDIFF( Day, RtExpr.FirstStartDate, RtExpr.InfantDOB ) Between 260 And 279 
                THEN 5--N'Orange - First Program Start Date is 260 to 279 days before infant DOB as recorded'
              WHEN DATEDIFF( Day, RtExpr.FirstStartDate, RtExpr.InfantDOB ) >=      280 
                THEN 6--   N'Red – First Program Start Date is 280 or more days before infant DOB as recorded'
              ELSE Null
           END AS IDOB_ProgramStartDate
/******* Infant date of birth is missing but child should have been born ******/
        ,CASE WHEN RtExpr.InfantDOB IS NULL AND RtExpr.DueDate < COALESCE( RtExpr.ProgramEndDate, @rptEndDate )
               AND DATEDIFF( Day, RtExpr.FirstStartDate, @rptEndDate ) Between 240 And 259 
                THEN 1--N'Yellow - Missing Infant DOB and first Program Start Date is 240 to 259 days before reporting period end date'
              WHEN RtExpr.InfantDOB IS NULL AND RtExpr.DueDate < COALESCE( RtExpr.ProgramEndDate, @rptEndDate )
               AND DATEDIFF( Day, RtExpr.FirstStartDate, @rptEndDate ) Between 260 And 279 
                THEN 2--N'Orange - Missing Infant DOB and first Program Start Date 260 to 279 days before reporting period end date'
              WHEN RtExpr.InfantDOB IS NULL AND RtExpr.DueDate < COALESCE( RtExpr.ProgramEndDate, @rptEndDate ) 
               AND DATEDIFF( Day, RtExpr.FirstStartDate, @rptEndDate ) >= 280 
                THEN 3--   N'Red – Missing Infant DOB, and first Program Start Date is 280 or more days before reporting period end date'    
              ELSE Null
         END AS ProgramStartDate_ReportEnd
/******** Infant date of birth compared to estimated due date ********/
        /* Updated on 2017-02-14 to include logic for estimated due date > program end date, mbrown 2017-02-14 */
        /* *** Old logic was as below ***/
        --CASE 
        --     WHEN ROOT.InfantDOB IS NULL AND DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) BETWEEN 240 AND 259 THEN 1
        --     WHEN ROOT.InfantDOB IS NULL AND DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) BETWEEN 260 AND 279 THEN 2
        --     WHEN ROOT.InfantDOB IS NULL AND DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) >= 280 THEN 3
        --END ProgramStartDate_ReportEnd
        ,CASE WHEN DATEDIFF( Day, RtExpr.DueDate, RtExpr.InfantDOB ) Between 28 And 34 
                THEN 1--N'Yellow - Infant DOB is recorded as 4 weeks after Estimated Due Date'
              WHEN DATEDIFF( Day, RtExpr.DueDate, RtExpr.InfantDOB ) Between 35 And 47 
                THEN 2--N'Orange – Infant DOB is recorded as 5 or 6 weeks after Estimated Due Date'
              WHEN DATEDIFF( Day, RtExpr.DueDate, RtExpr.InfantDOB ) >= 48 
                THEN 3--   N'Red – Infant DOB is recorded as 7 or more weeks after Estimated Due Date'
              WHEN DATEDIFF( Day, RtExpr.InfantDOB, RtExpr.DueDate ) Between 112 And 125 
                THEN 4--N'Yellow - Infant DOB is recorded as 16 or 17 weeks before Estimated Due Date'
              WHEN DATEDIFF( Day, RtExpr.InfantDOB, RtExpr.DueDate ) Between 126 And 153 
                THEN 5--N'Orange - Infant DOB is recorded as 18 or 21 weeks before Estimated Due Date'
              WHEN DATEDIFF( Day, RtExpr.InfantDOB, RtExpr.DueDate ) >= 154 
                THEN 6--   N'Red – Infant DOB is recorded as 22 or more weeks before Estimated Due Date'
              ELSE NULL
           END AS IDOB_EDD
/******* Reliability of infant's date of birth *******/
        ,CASE WHEN RtExpr.ClientDOB >= RtExpr.InfantDOB 
                THEN 1--   N'Red – Client DOB recorded as after Infant DOB'
              ELSE Null 
         END AS IDOB_DOB       
        ,CASE WHEN RtExpr.InfantDOB >= CURRENT_TIMESTAMP
                THEN 1--   N'Red – Infant DOB recorded as in the future from the date report was run'
              ELSE Null 
         END AS IDOB_ReportRun 
        ,CASE WHEN RtExpr.InfantDOB >= RtExpr.LastEndDate
                THEN 1--   N'Red – Infant DOB recorded as after Program End Date of current program'
              ELSE Null 
         END AS IDOB_Discharge 
        ,CASE WHEN RtExpr.InfantDOB >= RtExpr.LastVisit   
                THEN 1--   N'Red – Infant DOB recorded as after last home visit or alternate encounter'
              ELSE Null 
         END AS IDOB_LastVisit 
/******* Reliability of estimated due date (EDD) *******/
        ,CASE WHEN DATEDIFF( Day, RtExpr.FirstStartDate, RtExpr.DueDate ) Between 240 And 259 
                THEN 1--N'Yellow - Estimated Due Date is 240 to 259 days after first Program Start Date'
              WHEN DATEDIFF( Day, RtExpr.FirstStartDate, RtExpr.DueDate ) Between 260 And 279 
                THEN 2--N'Orange - Estimated Due Date is 260 to 279 days after first Program Start Date'
              WHEN DATEDIFF( Day, RtExpr.FirstStartDate, RtExpr.DueDate ) >= 280 
                THEN 3--   N'Red – Estimated Due Date is 280 or more days after first Program Start Date'
              WHEN RtExpr.DueDate <= RtExpr.FirstStartDate
                THEN 4--N'Orange - Estimated Due Date occurs before first Program Start Date'
              WHEN RtExpr.DueDate Is Null
                THEN 5--   N'Red – Estimated Due Date is missing'
              WHEN RtExpr.DueDate <= RtExpr.ClientDOB
                THEN 6--   N'Red – Estimated Due Date recorded as occurring before client DOB'
              ELSE NULL
         END AS EDD
    FROM
    (
        SELECT 
            CL.ClientDOB
            ,CL.InfantDOB
            ,PS.StateAbbreviation
            ,PS.[USState]
            ,PS.StateID
            ,PS.[SiteID]
            ,PS.AgencyName
            ,PS.ProgramID
            ,PS.ProgramName
            ,CASE WHEN PS.SiteID  IN ( SELECT * FROM dbo.udf_ParseMultiParam( @rptParentEntity ) ) THEN @rptREName 
                  WHEN PS.StateID IN ( SELECT * FROM dbo.udf_ParseMultiParam( @rptParentEntity ) ) THEN @rptREName 
             END AS ReportingEntity
            ,HVP.CLID
            ,HVP.CaseNumber
            ,HVP.FirstStartDate
            ,HVP.ProgramStartDate
            ,HVP.LastStartDate
            ,HVP.FirstEndDate
            ,HVP.ProgramEndDate 
            ,HVP.LastEndDate
            ,MH.DueDate            
            ,LE.LastVisit

        FROM Client CL
          INNER JOIN HomeVisitProgram HVP ON HVP.CLID = CL.Client_Id
            INNER JOIN ProgramSite PS ON HVP.ProgramID = PS.ProgramID
              LEFT OUTER JOIN MaternalHealth MH ON HVP.CaseNumber = MH.CL_EN_GEN_ID
                LEFT OUTER JOIN LastHomeOrAltEnc LE ON HVP.CLID = LE.CL_EN_GEN_ID /*mbrown, 2017-03-29*/--AND HVP.ProgramID = LE.ProgramID

        WHERE CASE @rptReportType 
                    WHEN 1 THEN 1
                    WHEN 2 THEN PS.StateID
                    WHEN 3 THEN PS.SiteID
                    WHEN 4 THEN PS.ProgramID
              END IN ( SELECT * FROM dbo.udf_ParseMultiParam( @rptParentEntity ) ) 

    ) RtExpr
    WHERE ProgramStartDate =  LastStartDate 
      AND ProgramStartDate <= @rptEndDate 
      AND ( ProgramEndDate Is Null Or ProgramEndDate >= @rptStartDate )  
) ExcPivot

UNPIVOT
(
    Error FOR Category IN
    (
        ExcPivot.IDOB_ProgramStartDate
        ,ExcPivot.ProgramStartDate_ReportEnd
        ,ExcPivot.IDOB_EDD
        ,ExcPivot.IDOB_DOB
        ,ExcPivot.IDOB_ReportRun
        ,ExcPivot.IDOB_Discharge
        ,ExcPivot.IDOB_LastVisit
        ,ExcPivot.EDD
    )
) Exc

-- ################################################################################## --
-- ---------------------------------- Previous Version ------------------------------ --
-- ################################################################################## --
------------USE [DataWarehouse]
------------GO
------------/****** Object:  StoredProcedure [dbo].[usp_OE_InfantChar]    Script Date: 2017-03-06 15:08:21 ******/
------------SET ANSI_NULLS ON
------------GO
------------SET QUOTED_IDENTIFIER ON
------------GO

------------ALTER PROCEDURE [dbo].[usp_OE_InfantChar]
------------(    @StartDate        Date 
------------    ,@EndDate        Date 
------------    ,@ParentEntity VARCHAR(4000)
------------    ,@REName VARCHAR(50) 
------------    ,@ReportType VARCHAR(50) )

------------AS
------------/*** 
------------ *** This procedure was altered on 2017-02-14 to include logic which excludes clients who were 
------------ *** who were discharged before estimated due date. mbrown, 20170214
------------ ***/ 
------------DECLARE 
------------    @rptStartDate        Date 
------------    ,@rptEndDate        Date 
------------    ,@rptParentEntity Varchar(4000)
------------    ,@rptREName VARCHAR(50) 
------------    ,@rptReportType VARCHAR(50) 
------------SET @rptStartDate         = @StartDate
------------SET @rptEndDate         = @EndDate
------------SET @rptParentEntity     = @ParentEntity
------------SET @rptREName         = @REName
------------SET @rptReportType     = @ReportType

--------------DECLARE @StartDate DATE, @EndDate DATE
--------------SET @StartDate = CAST('11/1/2010' AS DATE)
--------------SET @EndDate = CAST(GetDate() AS DATE);


------------;WITH LastVisit AS
------------(SELECT 
------------    final.CL_EN_GEN_ID
------------    ,final.ProgramID
------------    ,ISNULL(MAX(final.SurveyDateHVE),MAX(final.SurveyDateAHVE)) LastVisit
------------    --,final.VisitType
------------FROM 
------------    (SELECT  
------------        visits.CL_EN_GEN_ID
------------        ,visits.ProgramID
------------        ,CASE WHEN visits.VisitType = 'HVE' THEN visits.SurveyDate END SurveyDateHVE
------------        ,CASE WHEN visits.VisitType = 'AHVE' THEN visits.SurveyDate END SurveyDateAHVE
------------        --,RANK() OVER(Partition By visits.CL_EN_GEN_ID,visits.ProgramID Order By visits.SurveyDate DESC,visits.VisitType) rank
------------    FROM 
------------        (SELECT 
------------            H.CL_EN_GEN_ID
------------            ,H.ProgramID
------------            ,MAX(H.SurveyDate) SurveyDate
------------            ,'HVE' VisitType
------------        FROM Home_Visit_Encounter_Survey H
------------            INNER JOIN UV_PAS P
------------                ON P.ProgramID = H.ProgramID
------------        WHERE H.CLIENT_COMPLETE_0_VISIT = 'Completed'
------------            AND H.SurveyDate BETWEEN @rptStartDate AND @rptEndDate
------------        GROUP BY 
------------            H.CL_EN_GEN_ID
------------            ,H.ProgramID      

------------        UNION ALL

------------        SELECT 
------------            H.CL_EN_GEN_ID
------------            ,H.ProgramID
------------            ,MAX(H.SurveyDate) SurveyDate
------------            ,'AHVE' VisitType 
------------        FROM Alternative_Encounter_Survey H
------------            INNER JOIN UV_PAS P
------------                ON P.ProgramID = H.ProgramID
------------        WHERE (H.CLIENT_TALKED_0_WITH_ALT LIKE 'CLIENT;%' OR H.CLIENT_TALKED_0_WITH_ALT = 'CLIENT')
------------            AND H.SurveyDate BETWEEN @rptStartDate AND @rptEndDate
------------        GROUP BY 
------------            H.CL_EN_GEN_ID
------------            ,H.ProgramID) visits
------------    ) final
--------------WHERE final.rank = 1
------------GROUP BY 
------------    final.CL_EN_GEN_ID
------------    ,final.ProgramID
------------)


------------SELECT 
------------    unpvt.[State]
------------    ,unpvt.[US State]
------------    ,unpvt.StateID
------------    ,unpvt.[SiteID]
------------    ,unpvt.AGENCY_INFO_0_NAME
------------    ,unpvt.ProgramID
------------    ,unpvt.ProgramName
------------    ,unpvt.ReportingEntity
------------    ,unpvt.CaseNumber CLID
------------    --,unpvt.ProgramID
------------    ,unpvt.ProgramStartDate
------------    ,unpvt.INFANT_BIRTH_0_DOB
------------    ,unpvt.CLIENT_HEALTH_PREGNANCY_0_EDD
------------    ,unpvt.DOB
------------    ,unpvt.CLIENT_DISCHARGE_1_DATE
------------    ,unpvt.LastVisit
------------    ,unpvt.INFANT_BIRTH_0_DOB_6
------------    ,unpvt.INFANT_BIRTH_0_DOB_12
------------    ,unpvt.INFANT_BIRTH_0_DOB_18
------------    ,unpvt.INFANT_BIRTH_0_DOB_24
------------    ,unpvt.INFANT_BIRTH_1_GEST_AGE
------------    ,unpvt.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS
------------    ,unpvt.INFANT_HEALTH_WEIGHT_1_OZ_6
------------    ,unpvt.INFANT_HEALTH_WEIGHT_1_OZ_12
------------    ,unpvt.INFANT_HEALTH_WEIGHT_1_OZ_18
------------    ,unpvt.INFANT_HEALTH_WEIGHT_1_OZ_24
------------    ,unpvt.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6
------------    ,unpvt.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12
------------    ,unpvt.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18
------------    ,unpvt.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24
------------    ,unpvt.INFANT_HEALTH_HEIGHT_0_INCHES_6
------------    ,unpvt.INFANT_HEALTH_HEIGHT_0_INCHES_12
------------    ,unpvt.INFANT_HEALTH_HEIGHT_0_INCHES_18
------------    ,unpvt.INFANT_HEALTH_HEIGHT_0_INCHES_24
------------    ,CONVERT(VARCHAR(50),Category) Category
------------    ,Error
------------FROM
------------(SELECT 
------------    ROOT.[State]
------------    ,ROOT.[US State]
------------    ,ROOT.StateID
------------    ,ROOT.[SiteID]
------------    ,ROOT.AGENCY_INFO_0_NAME
------------    ,ROOT.ProgramID
------------    ,ROOT.ProgramName
------------    ,ROOT.ReportingEntity
------------    ,ROOT.CLID
------------    ,ROOT.CaseNumber
------------    --,ROOT.ProgramID
------------    ,ROOT.ProgramStartDate
------------    ,ROOT.INFANT_BIRTH_0_DOB
------------    ,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD
------------    ,ROOT.DOB
------------    ,ROOT.CLIENT_DISCHARGE_1_DATE
------------    ,ROOT.LastVisit
------------    ,ROOT.INFANT_BIRTH_0_DOB_6
------------    ,ROOT.INFANT_BIRTH_0_DOB_12
------------    ,ROOT.INFANT_BIRTH_0_DOB_18
------------    ,ROOT.INFANT_BIRTH_0_DOB_24
------------    ,ROOT.INFANT_BIRTH_1_GEST_AGE
------------    ,ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS
------------    ,ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6
------------    ,ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12
------------    ,ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18
------------    ,ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24
------------    ,ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6
------------    ,ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12
------------    ,ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18
------------    ,ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24
------------    ,ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6
------------    ,ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12
------------    ,ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18
------------    ,ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24
------------    ,CASE 
------------        WHEN DATEDIFF(DAY,ROOT.INFANT_BIRTH_0_DOB,ROOT.ProgramStartDate) BETWEEN 0 AND 17 THEN 1 -- 0 AND 2.49 WEEKS
------------        WHEN DATEDIFF(DAY,ROOT.INFANT_BIRTH_0_DOB,ROOT.ProgramStartDate) BETWEEN 18 AND 34 THEN 2 -- 2.5 AND 4.9
------------        WHEN DATEDIFF(DAY,ROOT.INFANT_BIRTH_0_DOB,ROOT.ProgramStartDate) >= 5 THEN 3 -- 5 +
------------        WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,ROOT.INFANT_BIRTH_0_DOB) BETWEEN 240 AND 259 THEN 4
------------        WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,ROOT.INFANT_BIRTH_0_DOB) BETWEEN 260 AND 279 THEN 5
------------        WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,ROOT.INFANT_BIRTH_0_DOB) >= 280 THEN 6
------------    END IDOB_ProgramStartDate
------------    ,CASE WHEN ROOT.INFANT_BIRTH_0_DOB IS NULL AND ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD < COALESCE(ROOT.ProgramEndDate,CURRENT_TIMESTAMP)
------------               THEN CASE WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) BETWEEN 240 AND 259 THEN 1
------------                         WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) BETWEEN 260 AND 279 THEN 2
------------                         WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) >= 280 THEN 3
------------                         ELSE NULL
------------                    END
------------          ELSE NULL
------------     END ProgramStartDate_ReportEnd
------------    /* Updated on 2017-02-14 to include logic for estimated due date > program end date, mbrown 2017-02-14 */
------------    /* *** Old logic was as below ***/
------------    --CASE 
------------    --     WHEN ROOT.INFANT_BIRTH_0_DOB IS NULL AND DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) BETWEEN 240 AND 259 THEN 1
------------    --     WHEN ROOT.INFANT_BIRTH_0_DOB IS NULL AND DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) BETWEEN 260 AND 279 THEN 2
------------    --     WHEN ROOT.INFANT_BIRTH_0_DOB IS NULL AND DATEDIFF(DAY,ROOT.ProgramStartDate,@rptEndDate) >= 280 THEN 3
------------    --END ProgramStartDate_ReportEnd
------------    ,CASE
------------        WHEN DATEDIFF(DAY,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD,ROOT.INFANT_BIRTH_0_DOB) BETWEEN 28 AND 34 THEN 1 --4
------------        WHEN DATEDIFF(DAY,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD,ROOT.INFANT_BIRTH_0_DOB) BETWEEN 35 AND 47 THEN 2 --5-6
------------        WHEN DATEDIFF(DAY,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD,ROOT.INFANT_BIRTH_0_DOB) >= 48 THEN 3 --7+
------------        WHEN DATEDIFF(DAY,ROOT.INFANT_BIRTH_0_DOB,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD) BETWEEN 112 AND 125 THEN 4 --16 to 17
------------        WHEN DATEDIFF(DAY,ROOT.INFANT_BIRTH_0_DOB,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD) BETWEEN 126 AND 153 THEN 5 --18 to 21
------------        WHEN DATEDIFF(DAY,ROOT.INFANT_BIRTH_0_DOB,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD) >= 154 THEN 6 --16 to 17
------------    END IDOB_EDD
------------    ,CASE
------------        WHEN ROOT.DOB >= ROOT.INFANT_BIRTH_0_DOB THEN 1
------------    END IDOB_DOB
------------    ,CASE
------------        WHEN ROOT.INFANT_BIRTH_0_DOB >= ROOT.CLIENT_DISCHARGE_1_DATE THEN 1
------------    END IDOB_Discharge
------------    ,CASE
------------        WHEN ROOT.INFANT_BIRTH_0_DOB >= GETDATE() THEN 1
------------    END IDOB_ReportRun
------------    ,CASE
------------        WHEN ROOT.INFANT_BIRTH_0_DOB >= ROOT.LastVisit THEN 1
------------    END IDOB_LastVisit
------------    ,CASE
------------        WHEN (ROOT.INFANT_BIRTH_0_DOB_6 IS NOT NULL 
------------           OR ROOT.INFANT_BIRTH_0_DOB_12 IS NOT NULL 
------------           OR ROOT.INFANT_BIRTH_0_DOB_18 IS NOT NULL 
------------           OR ROOT.INFANT_BIRTH_0_DOB_24 IS NOT NULL) AND ROOT.INFANT_BIRTH_0_DOB IS NULL THEN 1
------------    END IDOB_Match
------------    ,CASE 
------------        WHEN (ROOT.CL_EN_GEN_ID_IBS IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_6 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_12 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_18 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_24 IS NOT NULL)
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_6
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_12
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_18
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_24
------------            AND ROOT.INFANT_BIRTH_0_DOB_6 = ROOT.INFANT_BIRTH_0_DOB_12
------------            AND ROOT.INFANT_BIRTH_0_DOB_6 = ROOT.INFANT_BIRTH_0_DOB_18
------------            AND ROOT.INFANT_BIRTH_0_DOB_6 = ROOT.INFANT_BIRTH_0_DOB_24
------------            AND ROOT.INFANT_BIRTH_0_DOB_12 = ROOT.INFANT_BIRTH_0_DOB_18
------------            AND ROOT.INFANT_BIRTH_0_DOB_12 = ROOT.INFANT_BIRTH_0_DOB_24
------------            AND ROOT.INFANT_BIRTH_0_DOB_18 = ROOT.INFANT_BIRTH_0_DOB_24
------------        THEN NULL
------------        WHEN (ROOT.CL_EN_GEN_ID_IBS IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_6 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_12 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_18 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_24 IS NULL)
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_6
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_12
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_18
------------            AND ROOT.INFANT_BIRTH_0_DOB_6 = ROOT.INFANT_BIRTH_0_DOB_12
------------            AND ROOT.INFANT_BIRTH_0_DOB_6 = ROOT.INFANT_BIRTH_0_DOB_18
------------            AND ROOT.INFANT_BIRTH_0_DOB_12 = ROOT.INFANT_BIRTH_0_DOB_18
------------        THEN NULL
------------        WHEN (ROOT.CL_EN_GEN_ID_IBS IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_6 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_12 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_18 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_24 IS NULL)
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_6
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_12
------------            AND ROOT.INFANT_BIRTH_0_DOB_6 = ROOT.INFANT_BIRTH_0_DOB_12
------------        THEN NULL
------------        WHEN (ROOT.CL_EN_GEN_ID_IBS IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_6 IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_12 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_18 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_24 IS NULL)
------------            AND ROOT.INFANT_BIRTH_0_DOB = ROOT.INFANT_BIRTH_0_DOB_6
------------        THEN NULL
------------        WHEN (ROOT.CL_EN_GEN_ID_IBS IS NOT NULL
------------            AND ROOT.CL_EN_GEN_ID_6 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_12 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_18 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_24 IS NULL)
------------            AND ROOT.INFANT_BIRTH_0_DOB IS NOT NULL
------------        THEN NULL
------------        WHEN (ROOT.CL_EN_GEN_ID_IBS IS NULL
------------            AND ROOT.CL_EN_GEN_ID_6 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_12 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_18 IS NULL
------------            AND ROOT.CL_EN_GEN_ID_24 IS NULL)
------------            AND ROOT.INFANT_BIRTH_0_DOB IS NULL
------------        THEN NULL
------------        ELSE 1
------------    END IDOB_Match2
------------    ,CASE
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE BETWEEN 23 AND 24 THEN 1
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE BETWEEN 19 AND 22 THEN 2
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE <= 18 THEN 3
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE = 44 THEN 4
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE BETWEEN 45 AND 46 THEN 5
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE >= 47 THEN 6
------------        WHEN ROOT.INFANT_BIRTH_1_GEST_AGE IS NULL THEN 7
------------    END GestAge_Birth
------------    ,CASE
------------        WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD) BETWEEN 240 AND 259 THEN 1
------------        WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD) BETWEEN 260 AND 279 THEN 2
------------        WHEN DATEDIFF(DAY,ROOT.ProgramStartDate,ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD) >= 280 THEN 3
------------        WHEN ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD <= ROOT.ProgramStartDate THEN 4
------------        WHEN ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD IS NULL THEN 5
------------        WHEN ROOT.CLIENT_HEALTH_PREGNANCY_0_EDD <= ROOT.DOB THEN 6
------------    END EDD
------------    ,CASE 
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS BETWEEN 801 AND 1200 THEN 1
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS BETWEEN 431 AND 800 THEN 2
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS <= 460 THEN 3
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS BETWEEN 4500 AND 6249 THEN 4
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS BETWEEN 6250 AND 7999 THEN 5
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS >= 8000 THEN 6
------------        WHEN ROOT.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS IS NULL THEN 7
------------    END Weight_Birth
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6 BETWEEN 5784 AND 6024 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6 BETWEEN 5543 AND 5783 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6 <= 5542 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6 BETWEEN 10362 AND 10602 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6 BETWEEN 10603 AND 10843 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_6 >= 10844 THEN 6
------------    END Weight_6
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12 BETWEEN 7230 AND 7470 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12 BETWEEN 6989 AND 7229 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12 <= 6988 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12 BETWEEN 12771 AND 13252 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12 BETWEEN 13253 AND 13734 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_12 >= 13735 THEN 6
------------    END Weight_12
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18 BETWEEN 8194 AND 8434 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18 BETWEEN 7953 AND 8193 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18 <= 7952 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18 BETWEEN 14458 AND 14939 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18 BETWEEN 14940 AND 15421 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_18 >= 15422 THEN 6
------------    END Weight_18
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24 BETWEEN 9158 AND 9639 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24 BETWEEN 8676 AND 9157 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24 <= 8675 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24 BETWEEN 16386 AND 16867 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24 BETWEEN 16868 AND 17349 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_WEIGHT_1_OZ_24 >= 17350 THEN 6
------------    END Weight_24
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6 BETWEEN 39.30 AND 39.60 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6 BETWEEN 38.81 AND 39.29 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6 <= 38.80 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6 BETWEEN 45.80 AND 46.19 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6 BETWEEN 46.2 AND 46.59 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_6 >= 46.6 THEN 6
------------    END Head_6
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12 BETWEEN 41.9 AND 42.2 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12 BETWEEN 41.41 AND 41.89 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12 <= 41.4 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12 BETWEEN 48.6 AND 48.99 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12 BETWEEN 49 AND 49.39 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_12 >= 49.4 THEN 6
------------    END Head_12
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18 BETWEEN 43.1 AND 43.5 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18 BETWEEN 42.51 AND 43.09 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18 <= 42.5 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18 BETWEEN 50 AND 50.49 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18 BETWEEN 50.5 AND 50.99 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_18 >= 51 THEN 6
------------    END Head_18
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24 BETWEEN 42 AND 44.4 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24 BETWEEN 39.41 AND 41.99 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24 <= 39.4 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24 BETWEEN 51 AND 51.49 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24 BETWEEN 51.5 AND 51.99 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEAD_0_CIRC_INCHES_24 >= 52 THEN 6
------------    END Head_24
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6 BETWEEN 23.6 AND 24 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6 BETWEEN 23.01 AND 23.59 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6 <= 23 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6 BETWEEN 28.5 AND 28.99 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6 BETWEEN 29 AND 29.49 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_6 >= 29.5 THEN 6
------------    END Height_6
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12 BETWEEN 26.6 AND 27 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12 BETWEEN 26.01 AND 26.59 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12 <= 26 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12 BETWEEN 31.5 AND 31.99 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12 BETWEEN 32 AND 32.49 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_12 >= 32.5 THEN 6
------------    END Height_12
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18 BETWEEN 29.1 AND 29.5 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18 BETWEEN 28.51 AND 29.09 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18 <= 28.5 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18 BETWEEN 34.5 AND 34.99 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18 BETWEEN 35 AND 35.49 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_18 >= 35.5 THEN 6
------------    END Height_18
------------    ,CASE 
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24 BETWEEN 31.1 AND 31.5 THEN 1
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24 BETWEEN 30.51 AND 31.09 THEN 2
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24 <= 30.5 THEN 3
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24 BETWEEN 37 AND 37.49 THEN 4
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24 BETWEEN 37.5 AND 37.99 THEN 5
------------        WHEN ROOT.INFANT_HEALTH_HEIGHT_0_INCHES_24 >= 38 THEN 6
------------    END Height_24
------------    ,CASE
------------        WHEN ROOT.INFANT_PERSONAL_0_RACE IS NULL THEN 1
------------    END Race_Missing
------------    ,CASE
------------        WHEN ROOT.INFANT_PERSONAL_0_ETHNICITY IS NULL THEN 1
------------    END Eth_Missing

------------FROM(

------------SELECT 
------------    dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
------------    ,P.[US State]
------------    ,P.StateID
------------    ,P.[SiteID]
------------    ,P.AGENCY_INFO_0_NAME
------------    ,P.ProgramID
------------    ,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
------------    ,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rptParentEntity)) THEN @rptREName 
------------        WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rptParentEntity)) THEN @rptREName END ReportingEntity
------------    ,EAD.CLID
------------    ,EAD.CaseNumber
------------    --,EAD.ProgramID
------------    ,EAD.ProgramStartDate
------------    ,EAD.ProgramEndDate -- mbrown, added 2017-02-14
------------    ,IBS.CL_EN_GEN_ID CL_EN_GEN_ID_IBS
------------    ,IBS.INFANT_BIRTH_0_DOB
------------    ,IBS.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS
------------    ,IBS.INFANT_BIRTH_1_GEST_AGE
------------    ,IBS.INFANT_PERSONAL_0_RACE
------------    ,IBS.INFANT_PERSONAL_0_ETHNICITY
------------    ,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD
------------    ,C.DOB
------------    ,CD.CLIENT_DISCHARGE_1_DATE
------------    ,LV.LastVisit
------------    ,IHS6.CL_EN_GEN_ID CL_EN_GEN_ID_6
------------    ,IHS6.INFANT_HEALTH_WEIGHT_1_OZ INFANT_HEALTH_WEIGHT_1_OZ_6
------------    ,IHS6.INFANT_BIRTH_0_DOB INFANT_BIRTH_0_DOB_6
------------    ,IHS6.INFANT_HEALTH_HEAD_0_CIRC_INCHES INFANT_HEALTH_HEAD_0_CIRC_INCHES_6
------------    ,IHS6.INFANT_HEALTH_HEIGHT_0_INCHES INFANT_HEALTH_HEIGHT_0_INCHES_6
------------    ,IHS12.CL_EN_GEN_ID CL_EN_GEN_ID_12
------------    ,IHS12.INFANT_HEALTH_WEIGHT_1_OZ INFANT_HEALTH_WEIGHT_1_OZ_12
------------    ,IHS12.INFANT_BIRTH_0_DOB INFANT_BIRTH_0_DOB_12
------------    ,IHS12.INFANT_HEALTH_HEAD_0_CIRC_INCHES INFANT_HEALTH_HEAD_0_CIRC_INCHES_12
------------    ,IHS12.INFANT_HEALTH_HEIGHT_0_INCHES INFANT_HEALTH_HEIGHT_0_INCHES_12
------------    ,IHS18.CL_EN_GEN_ID CL_EN_GEN_ID_18
------------    ,IHS18.INFANT_HEALTH_WEIGHT_1_OZ INFANT_HEALTH_WEIGHT_1_OZ_18
------------    ,IHS18.INFANT_BIRTH_0_DOB INFANT_BIRTH_0_DOB_18
------------    ,IHS18.INFANT_HEALTH_HEAD_0_CIRC_INCHES INFANT_HEALTH_HEAD_0_CIRC_INCHES_18
------------    ,IHS18.INFANT_HEALTH_HEIGHT_0_INCHES INFANT_HEALTH_HEIGHT_0_INCHES_18
------------    ,IHS24.CL_EN_GEN_ID CL_EN_GEN_ID_24
------------    ,IHS24.INFANT_HEALTH_WEIGHT_1_OZ INFANT_HEALTH_WEIGHT_1_OZ_24
------------    ,IHS24.INFANT_BIRTH_0_DOB INFANT_BIRTH_0_DOB_24
------------    ,IHS24.INFANT_HEALTH_HEAD_0_CIRC_INCHES INFANT_HEALTH_HEAD_0_CIRC_INCHES_24
------------    ,IHS24.INFANT_HEALTH_HEIGHT_0_INCHES INFANT_HEALTH_HEIGHT_0_INCHES_24
------------FROM
------------    (SELECT 
------------        EAD.CLID
------------        ,EAD.CaseNumber
------------        ,EAD.ProgramID
------------        ,EAD.ProgramStartDate
------------        ,EAD.EndDate AS ProgramEndDate -- mbrown, added 2017-02-14
------------    FROM UV_EADT EAD
------------    WHERE EAD.ProgramStartDate BETWEEN @rptStartDate AND @rptEndDate) EAD

------------INNER JOIN UV_PAS P
------------    ON EAD.ProgramID = P.ProgramID

------------LEFT OUTER JOIN
------------    (SELECT 
------------        IBS.ProgramID
------------        ,IBS.CL_EN_GEN_ID
------------        ,IBS.INFANT_BIRTH_0_DOB
------------        ,IBS.INFANT_BIRTH_1_GEST_AGE
------------        ,IBS.INFANT_BIRTH_1_WEIGHT_CONVERT_GRAMS
------------        ,IBS.INFANT_PERSONAL_0_RACE
------------        ,IBS.INFANT_PERSONAL_0_ETHNICITY
------------    FROM Infant_Birth_Survey IBS
------------    WHERE IBS.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) IBS
------------        ON EAD.CLID = IBS.CL_EN_GEN_ID
------------        AND EAD.ProgramID = IBS.ProgramID

------------LEFT OUTER JOIN 
------------    (SELECT 
------------        MHS.CL_EN_GEN_ID
------------        ,MHS.ProgramID 
------------        ,MHS.CLIENT_HEALTH_PREGNANCY_0_EDD
------------    FROM Maternal_Health_Survey MHS
------------    WHERE MHS.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) MHS
------------        ON EAD.CLID = MHS.CL_EN_GEN_ID
------------        AND EAD.ProgramID = MHS.ProgramID -- mbrown 2017-02-27: questionning ProgramID for this join
    
------------LEFT OUTER JOIN 
------------    (SELECT
------------        C.Client_Id
------------        ,C.DOB
------------    FROM Clients C) C
------------        ON EAD.CLID = C.Client_Id

------------LEFT OUTER JOIN    
------------    (SELECT 
------------        CD.CL_EN_GEN_ID
------------        ,CD.ProgramID
------------        ,CD.CLIENT_DISCHARGE_1_DATE
------------    FROM Client_Discharge_Survey CD
------------    WHERE CD.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) CD
------------        ON EAD.CLID = CD.CL_EN_GEN_ID
------------        AND EAD.ProgramID = CD.ProgramID

------------LEFT OUTER JOIN    
------------    (SELECT 
------------        LV.CL_EN_GEN_ID
------------        ,LV.ProgramID
------------        ,LV.LastVisit
------------    FROM LastVisit LV) LV
------------        ON EAD.CLID = LV.CL_EN_GEN_ID
------------        AND EAD.ProgramID = LV.ProgramID

------------LEFT OUTER JOIN 
------------    (SELECT 
------------        IHS.CL_EN_GEN_ID
------------        ,IHS.ProgramID
------------        ,IHS.INFANT_HEALTH_WEIGHT_1_OZ
------------        ,IHS.INFANT_BIRTH_0_DOB
------------        ,IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
------------        ,IHS.INFANT_HEALTH_HEIGHT_0_INCHES
------------    FROM Infant_Health_Survey IHS
------------    WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care-Infancy 6 Months'
------------        AND IHS.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) IHS6
------------        ON EAD.CLID = IHS6.CL_EN_GEN_ID
------------        AND EAD.ProgramID = IHS6.ProgramID

------------LEFT OUTER JOIN 
------------    (SELECT 
------------        IHS.CL_EN_GEN_ID
------------        ,IHS.ProgramID
------------        ,IHS.INFANT_HEALTH_WEIGHT_1_OZ
------------        ,IHS.INFANT_BIRTH_0_DOB
------------        ,IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
------------        ,IHS.INFANT_HEALTH_HEIGHT_0_INCHES
------------    FROM Infant_Health_Survey IHS
------------    WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Infancy 12 Months'
------------        AND IHS.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) IHS12
------------        ON EAD.CLID = IHS12.CL_EN_GEN_ID
------------        AND EAD.ProgramID = IHS12.ProgramID

------------LEFT OUTER JOIN
------------    (SELECT 
------------        IHS.CL_EN_GEN_ID
------------        ,IHS.ProgramID
------------        ,IHS.INFANT_HEALTH_WEIGHT_1_OZ
------------        ,IHS.INFANT_BIRTH_0_DOB
------------        ,IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
------------        ,IHS.INFANT_HEALTH_HEIGHT_0_INCHES
------------    FROM Infant_Health_Survey IHS
------------    WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 18 Months'
------------        AND IHS.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) IHS18
------------        ON EAD.CLID = IHS18.CL_EN_GEN_ID
------------        AND EAD.ProgramID = IHS18.ProgramID
        
------------LEFT OUTER JOIN
------------    (SELECT 
------------        IHS.CL_EN_GEN_ID
------------        ,IHS.ProgramID
------------        ,IHS.INFANT_HEALTH_WEIGHT_1_OZ
------------        ,IHS.INFANT_BIRTH_0_DOB
------------        ,IHS.INFANT_HEALTH_HEAD_0_CIRC_INCHES
------------        ,IHS.INFANT_HEALTH_HEIGHT_0_INCHES
------------    FROM Infant_Health_Survey IHS
------------    WHERE dbo.fnGetFormName(IHS.SurveyID) = 'Infant Health Care: Toddler 24 Months'
------------        AND IHS.SurveyDate BETWEEN @rptStartDate AND @rptEndDate) IHS24
------------        ON EAD.CLID = IHS24.CL_EN_GEN_ID
------------        AND EAD.ProgramID = IHS24.ProgramID 

------------WHERE 
------------    CASE
------------        WHEN @rptReportType = 1 THEN 1
------------        WHEN @rptReportType = 2 THEN P.StateID
------------        WHEN @rptReportType = 3 THEN P.SiteID
------------        WHEN @rptReportType = 4 THEN P.ProgramID
------------      END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rptParentEntity)) 

------------) ROOT      

------------) p

------------UNPIVOT
------------(Error FOR Category IN
------------    (p.IDOB_ProgramStartDate
------------    ,p.ProgramStartDate_ReportEnd
------------    ,p.IDOB_EDD
------------    ,p.IDOB_DOB
------------    ,p.IDOB_Discharge
------------    ,p.IDOB_ReportRun
------------    ,p.IDOB_LastVisit
------------    ,p.IDOB_Match
------------    ,p.IDOB_Match2
------------    ,p.GestAge_Birth
------------    ,p.EDD
------------    ,p.Weight_Birth
------------    ,p.Weight_6
------------    ,p.Weight_12
------------    ,p.Weight_18
------------    ,p.Weight_24
------------    ,p.Head_6
------------    ,p.Head_12
------------    ,p.Head_18
------------    ,p.Head_24
------------    ,p.Height_6
------------    ,p.Height_12
------------    ,p.Height_18
------------    ,p.Height_24
------------    ,p.Race_Missing
------------    ,p.Eth_Missing)
------------) unpvt
GO
