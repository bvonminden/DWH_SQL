USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_ClientProgStartDate_v3]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_OE_ClientProgStartDate_v3]
(    
     @StartDate     date 
    ,@EndDate       date 
    ,@ParentEntity  varchar(4000)
    ,@REName        varchar(50) 
    ,@ReportType    varchar(50) 
)
AS

/*****************************************************************
 * Matthew Brown, newest version of USP_OE_ClientProgStartDate.  *
 * This is a stored procedure for the Data Exception             *
 * Report: Client Program Start Dates.                           *
 *****************************************************************/
 
--DECLARE /********* for testing *************/
--     @StartDate     date 
--    ,@EndDate       date 
--    ,@ParentEntity  varchar(4000)
--    ,@REName        varchar(50) 
--    ,@ReportType    varchar(50) 
--SET @StartDate      = '20150401' 
--SET @EndDate        = CURRENT_TIMESTAMP
--SET @ParentEntity   = '1' --'6'
--SET @REName         = NULL
--SET @ReportType     = '1' --'2'

DECLARE 
     @rStartDate    date 
    ,@rEndDate      date 
    ,@rParentEntity varchar(4000)
    ,@rREName       varchar(50) 
    ,@rReportType   varchar(50) 
SET @rStartDate     = @StartDate
SET @rEndDate       = @EndDate
SET @rParentEntity  = @ParentEntity
SET @rREName        = @REName
SET @rReportType    = @ReportType;

/********************************************************************************************************
 * common table expressions for referal and intake program (REF) and nurse home visiting programs (nhv) *
 ********************************************************************************************************/

WITH 
REF(ref_RecID, ref_CaseNumber, ref_ProgramID, ref_EndDate, ref_ReasonForDismissal, ref_Count) 
AS                      /*** Referral and Intake Program only ***/
    (Select EAD.RecID
           ,EAD.[CaseNumber]
           ,PAS.ProgramID
           ,EndDate
           ,ReasonForDismissal
           ,Count(RecID) Over(Partition By CaseNumber) -- for multiple referal programs
     From EnrollmentAndDismissal EAD 
         Inner Join UV_PAS PAS 
           On PAS.Program_ID_Referrals = EAD.ProgramID 
           And CaseNumber Is Not Null)
,
NHV(nhv_RecID, nhv_CaseNumber, nhv_ProgramID, nhv_ProgramStartDate) 
AS                      /*** Nurse Home Visiting Program only ***/
    (Select EAD.RecID
           ,EAD.[CaseNumber]
           ,PAS.ProgramID
           ,ProgramStartDate
     From EnrollmentAndDismissal EAD 
        Inner Join UV_PAS PAS 
          On PAS.Program_ID_NHV = EAD.ProgramID
          And CaseNumber Is Not Null)


SELECT unpvt.State
      ,unpvt.[US State]
      ,unpvt.StateID
      ,unpvt.AGENCY_INFO_0_NAME
      ,unpvt.ProgramID
      ,unpvt.ProgramName
      ,unpvt.ReportingEntity
      ,unpvt.CaseNumber /******* mbrown, 2017-05-22; this is the client id for reporting purposes ***********/
      ,unpvt.ProgramStartDate
      --,unpvt.CLID /* commented out, as this is not a client id that end users utilize */
      ,unpvt.DemoSDate
      ,unpvt.MatSDate
      ,unpvt.HHSDate
      ,unpvt.FirstVisit
      ,unpvt.SecondVisit
      ,unpvt.nhv_ProgramStartDate
      ,unpvt.ref_EndDate
      ,unpvt.ref_ReasonForDismissal
      ,CONVERT(VARCHAR(50),Category) AS Category
      ,Error
      /*
       * mbrown, 2017-05-18; added "Accuracy" field to make embeded report code less cumbersome.
       */
      ,(CASE Category 
             WHEN 'FirstVisitErr' THEN 
                  (case Error 
                        when 1 then N'Red - Program start date occurs after first completed home visit'
                        when 2 then N'Yellow - Program start date is less than 30 days before first completed home visit'
                        when 3 then N'Orange - Program start date is 31 to 60 days before the first completed home visit' 
                        when 4 then N'Red - Program start date is 61 or more days before the first completed home visit'
                   end)
             WHEN 'SecondVisitErr' THEN N'Orange - First completed home visit is 61 or more days before second completed home visit'
                  
             --WHEN 'FVB1996' THEN N'Red - First completed home visit occurs prior to 1/1/1996'
             --WHEN 'FVAToday' THEN N'Red - First completed home visit date is reported as a future date' 
             WHEN 'SurveyBFirstVisit' THEN N'Red - Survey date on intake forms occurs prior to client’s first completed home visit date'
             WHEN 'MultiRefErr' THEN N'Red – Client has more than one Referral and Intake record' 
             WHEN 'MissRefEndErr' THEN 
                  (case Error
                        when 1 then N'Red – Missing Referral and Intake record but has NHV program record' 
                        when 2 then N'Red – Missing Referral and Intake end date but has NHV program start date'
                   end)
             WHEN 'RefEndAfterNHVStartErr' THEN N'Red- Referral and Intake end date occurs after NHV program start date'
             WHEN 'RefReasonErr' then N'Red - Referral and Intake dismissal reason is not "Enrolled in NFP" but client has NHV program start date'
        END) AS Accuracy
FROM
(  
    SELECT dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) AS [State]
          ,P.[US State]
          ,P.StateID
          ,P.[SiteID]
          ,P.AGENCY_INFO_0_NAME
          ,P.ProgramID
          ,dbo.udf_fn_GetCleanProg(P.ProgramID) AS ProgramName
          ,CASE 
                WHEN P.SiteID IN  (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
                WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
           END AS ReportingEntity
          ,DATA.CaseNumber
          ,DATA.ProgramStartDate
          ,NHV.nhv_ProgramStartDate
          ,REF.ref_EndDate
          ,REF.ref_ReasonForDismissal
          ,DATA.CLID
          --,DATA.ProgramID
          ,DATA.DemoSDate
          ,DATA.MatSDate
          ,DATA.HHSDate
          ,DATA.FirstVisit
          ,DATA.SecondVisit
          /*
           * NARRATIVE OBJECTIVE 1) Reliability of client's program start date
           */
          ,(CASE WHEN DATA.ProgramStartDate > DATA.FirstVisit THEN 1 -- Red - Program start date occurs after first completed home visit
                 WHEN DATEDIFF(DAY,DATA.ProgramStartDate,DATA.FirstVisit) BETWEEN 1 AND 30 THEN 2  -- Yellow - 30 days or less
                 WHEN DATEDIFF(DAY,DATA.ProgramStartDate,DATA.FirstVisit) BETWEEN 31 AND 60 THEN 3 -- Orange – 31 to 60 days
                 WHEN DATEDIFF(DAY,DATA.ProgramStartDate,DATA.FirstVisit) >= 90 THEN 4  --  Red – 61 or more days  
            END) AS FirstVisitErr
          /*
           * NARRATIVE OBJECTIVE 2) Length of time between first completed home visit or alternate 
           * encounter with client and second completed home first or alternate encounter with client
           */
           ,(CASE WHEN DATEDIFF(DAY,DATA.FirstVisit,DATA.SecondVisit) > 60 THEN 1 END) AS SecondVisitErr -- Orange – 61 or more days 
          /*
           *  NARRATIVE OBJECTIVE 3) Reliability of client's first completed home visit date
           */ 
          --,(CASE WHEN YEAR(DATA.FirstVisit) < 1996 THEN 1 END) AS FVB1996 -- Red – First completed home visit occurs prior to 1/1/1996
          --,(CASE WHEN DATA.FirstVisit > GETDATE() THEN 1 END) AS FVAToday -- Red – First completed home visit date is reported as a future date
          /*
           * NARRATIVE OBJECTIVE 4) Survey date occurs prior to client’s first completed home date
           */
          ,(CASE WHEN ((DATA.DemoSDate<DATA.FirstVisit) 
                       OR (DATA.MatSDate<DATA.FirstVisit) 
                       OR (DATA.HHSDate<DATA.FirstVisit)) THEN 1 
            END) AS SurveyBFirstVisit -- Red - A survey date occurs prior to client’s first completed home date
          /*
           *  NARRATIVE OBJECTIVE 5) Reliability of client's referral and intake program end date
           */
          ,CASE WHEN ref_Count > 1 THEN 1 END AS MultiRefErr -- Red – Client has more than one Referral and Intake record
          ,CASE WHEN ref_EndDate Is Null THEN  
                (case when ref_RecID is null then 1 -- Red - Missing referral and intake record but has NHV program record
                      when nhv_ProgramStartDate is not null then 2 -- Red - Missing referral and intake end date but has NHV program start date
                 end)
           END AS MissRefEndErr
          ,CASE WHEN ref_EndDate > nhv_ProgramStartDate THEN 1 END AS RefEndAfterNHVStartErr -- Red- Referral and Intake end date occurs after NHV program start date 
          ,CASE WHEN ref_ReasonForDismissal <> 'Enrolled In NFP' AND nhv_ProgramStartDate Is Not Null THEN 1 
           END AS RefReasonErr -- Red – Referral and Intake  dismissal reason was not "Enrolled in NFP" but client has NHV program start date
    FROM 
    (
        SELECT ROOT.CaseNumber
              ,ROOT.ProgramStartDate
              ,ROOT.CLID
              ,ROOT.ProgramID
              ,MIN(ROOT.DemoSDate) AS DemoSDate
              ,MIN(ROOT.MatSDate) AS MatSDate
              ,MIN(ROOT.HHSDate) AS HHSDate
              ,MAX(case when ROOT.VisitOrder = 1 then SurveyDate end) AS FirstVisit
              ,MAX(case when ROOT.VisitOrder = 2 then SurveyDate end) AS SecondVisit
        FROM 
        (
            SELECT EAD.CaseNumber
                  ,EAD.ProgramStartDate 
                  ,EAD.CLID
                  ,EAD.ProgramID
                  ,DS.SurveyDate AS DemoSDate
                  ,MS.SurveyDate AS MatSDate
                  ,HHS.SurveyDate AS HHSDate
                  ,v.SurveyDate
                  ,Row_Number() OVER(Partition By EAD.CaseNumber, EAD.ProgramStartDate, EAD.CLID, EAD.ProgramID 
                                     Order By v.SurveyDate) AS VisitOrder
            FROM Clients AS C 
                INNER JOIN UV_EADT AS EAD 
                    ON C.CaseNumber = EAD.CaseNumber
                LEFT OUTER JOIN UC_Fidelity_aHVES AS v
                    ON EAD.CLID = v.CL_EN_GEN_ID
                    AND EAD.ProgramID = v.ProgramID
                    AND v.CLIENT_COMPLETE_0_VISIT = 'Completed'
                LEFT OUTER JOIN Demographics_Survey AS DS
                    ON DS.SurveyID IN (select SurveyID 
                                       from Mstr_surveys 
                                       where SurveyName = 'Demographics: Pregnancy Intake')
                       /*******************************************************
                        * mbrown 2017-05-18; joining on this subquery returns *
                        * the same dataset as joining on the scalar function  *
                        * dbo.fnGetFormName(), but takes about half the time. *
                        *******************************************************/
                       -- dbo.fnGetFormName(DS.SurveyID) = 'Demographics: Pregnancy Intake'
                    AND DS.CL_EN_GEN_ID = EAD.CLID
                    AND DS.ProgramID = EAD.ProgramID
                LEFT OUTER JOIN Maternal_Health_Survey AS MS
                    ON MS.CL_EN_GEN_ID = EAD.CLID
                    AND MS.ProgramID = EAD.ProgramID
                LEFT OUTER JOIN Health_Habits_Survey AS HHS
                    ON HHS.SurveyID IN (select SurveyID 
                                        from Mstr_surveys 
                                        where SurveyName = 'Health Habits: Pregnancy-Intake')
                       /* mbrown 2017-05-18; like above, this is faster than the function. */
                       -- dbo.fnGetFormName(HHS.SurveyID) = 'Health Habits: Pregnancy-Intake'
                    AND HHS.CL_EN_GEN_ID = EAD.CLID
                    AND HHS.ProgramID = EAD.ProgramID
        WHERE EAD.RankingOrig = 1 
        AND EAD.ProgramStartDate >= @rStartDate
        AND ProgramStartDate <= @rEndDate
        ) AS ROOT
    GROUP BY ROOT.CaseNumber,ROOT.ProgramStartDate,ROOT.CLID,ROOT.ProgramID
    ) AS DATA INNER JOIN UV_PAS AS P ON DATA.ProgramID = P.ProgramID
      /*************************************************************************
       * mbrown 2017-05-22, adding references to NHV and REF table expressions *
       * they were added here to ensure not obscuring in "grouped by" clause   *
       *************************************************************************/
              INNER JOIN NHV ON DATA.CaseNumber = NHV.nhv_CaseNumber
                             AND DATA.ProgramStartDate = NHV.nhv_ProgramStartDate
                             AND DATA.ProgramID = NHV.nhv_ProgramID 
              LEFT OUTER JOIN REF ON DATA.CaseNumber = REF.ref_CaseNumber
      /*************************************************************************/
    WHERE CASE @rReportType
               WHEN 1 THEN 1
               WHEN 2 THEN P.StateID
               WHEN 3 THEN P.SiteID
               WHEN 4 THEN P.ProgramID
          END IN (select * from dbo.udf_ParseMultiParam (@rParentEntity))
) AS upv

UNPIVOT
(
    Error FOR Category IN
    (
        upv.FirstVisitErr
        ,upv.SecondVisitErr
        --,upv.FVB1996
        --,upv.FVAToday
        ,upv.SurveyBFirstVisit
        ,upv.MultiRefErr
        ,upv.MissRefEndErr
        ,upv.RefEndAfterNHVStartErr
        ,upv.RefReasonErr
    ) 
) AS unpvt
GO
