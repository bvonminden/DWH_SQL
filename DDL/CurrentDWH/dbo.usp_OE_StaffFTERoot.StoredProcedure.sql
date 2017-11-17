USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[usp_OE_StaffFTERoot]    Script Date: 11/16/2017 10:44:32 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_OE_StaffFTERoot]

(	@StartDate		Date 
	,@EndDate		Date 
	,@ParentEntity VARCHAR(4000)
	,@REName VARCHAR(50) 
	,@ReportType VARCHAR(50) )

AS

DECLARE 
	@rStartDate		Date 
	,@rEndDate		Date 
	,@rParentEntity Varchar(4000)
	,@rREName VARCHAR(50) 
	,@rReportType VARCHAR(50) 
SET @rStartDate		 = @StartDate
SET @rEndDate		 = @EndDate
SET @rParentEntity	 = @ParentEntity
SET @rREName		 = @REName
SET @rReportType	 = @ReportType



SELECT 
	unpvt.[State]
	,unpvt.[US State]
	,unpvt.StateID
	,unpvt.AGENCY_INFO_0_NAME
	,unpvt.ProgramID
	,unpvt.ProgramName
	,unpvt.ReportingEntity
	,unpvt.Entity_Id
	,unpvt.Full_Name
	,unpvt.HireDate
	,unpvt.EndDate
	,unpvt.LastVisit
	,unpvt.VisitType
	,unpvt.LastMeeting
	,unpvt.PrimRole
	,unpvt.SecRole
	,unpvt.O_FTE
	,unpvt.AA_FTE
	,unpvt.HV_FTE
	,unpvt.S_FTE
	,CONVERT(VARCHAR(50),Category) Category
	,Error
FROM
(SELECT 
	dbo.udf_StateVSTribal(P.Abbreviation,P.SiteID) [State]
	,P.[US State]
	,P.StateID
	,P.[SiteID]
	,P.AGENCY_INFO_0_NAME
	,P.ProgramID
	,dbo.udf_fn_GetCleanProg(P.ProgramID) ProgramName
	,CASE WHEN P.SiteID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName 
		WHEN P.StateID IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity)) THEN @rREName END ReportingEntity
	,S.Entity_Id
	,LTRIM(S.Full_Name) Full_Name
	,S.HireDate
	,S.EndDate
	,V.SurveyDate LastVisit
	,CASE WHEN V.VisitType = 'HVE' THEN 'HV'
		  WHEN V.VisitType = 'AHVE' THEN 'AE' END VisitType
	,SupSup.SurveyDate LastMeeting
	,S.PrimRole
	,S.SecRole
	,S.O_FTE
	,S.AA_FTE
	,S.HV_FTE
	,S.S_FTE
	,CASE 
		WHEN S.EndDate IS NULL AND S.PrimRole = 'Nurse Home Visitor' AND DATEDIFF(DAY,S.StartDate,@rEndDate) >= 90 AND DATEDIFF(DAY,ISNULL(V.SurveyDate,S.StartDate),@rEndDate) BETWEEN 30 AND 60 THEN 1 --'30to60' 
		WHEN S.EndDate IS NULL AND S.PrimRole = 'Nurse Home Visitor' AND DATEDIFF(DAY,S.StartDate,@rEndDate) >= 90 AND DATEDIFF(DAY,ISNULL(V.SurveyDate,S.StartDate),@rEndDate) BETWEEN 61 AND 90 THEN 2 --'60to90' 
		WHEN S.EndDate IS NULL AND S.PrimRole = 'Nurse Home Visitor' AND DATEDIFF(DAY,S.StartDate,@rEndDate) >= 90 AND DATEDIFF(DAY,ISNULL(V.SurveyDate,S.StartDate),@rEndDate) > 90 THEN 3 --'90plus' 
	END ClientContact
	,CASE 
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.HireDate IS NULL THEN 1 --'NoHire' 
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.EndDate < S.HireDate THEN 2 --'EndPriorHire' 
	END NHVhire
	,CASE 
		WHEN S.EndDate IS NULL AND S.PrimRole = 'Nurse Supervisor' AND DATEDIFF(DAY,ISNULL(SupSup.SurveyDate,S.StartDate),@rEndDate) BETWEEN 30 AND 60 THEN 1 --'30to60' 
		WHEN S.EndDate IS NULL AND S.PrimRole = 'Nurse Supervisor' AND DATEDIFF(DAY,ISNULL(SupSup.SurveyDate,S.StartDate),@rEndDate) BETWEEN 61 AND 90 THEN 2 --'60to90' 
		WHEN S.EndDate IS NULL AND S.PrimRole = 'Nurse Supervisor' AND DATEDIFF(DAY,ISNULL(SupSup.SurveyDate,S.StartDate),@rEndDate) > 90 THEN 3 --'90plus' 
	END SupervisorMeetings
	,CASE
		WHEN S.PrimRole = 'Nurse Home Visitor' AND (S.HV_FTE IS NULL OR S.HV_FTE = 0 ) THEN 1
	END NHVFTEMissing
	,CASE 
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IN ('State Nurse Consultant','State Administrator','Agency Administrator','Program Coordinator/ Manager','Other') AND (S.O_FTE IS NULL OR S.O_FTE = 0) THEN 1
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IN ('Nurse Supervisor') AND (S.S_FTE IS NULL OR S.S_FTE = 0) THEN 1
		--WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IN ('Nurse Home Visitor') AND (S.HV_FTE IS NULL OR S.HV_FTE = 0) THEN 1
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IN ('Data Entry/Administrative') AND (S.AA_FTE IS NULL OR S.AA_FTE = 0) THEN 1
	END Missing2ndFTEHas2ndRoleNHV
	,CASE 
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IS NULL AND (S.O_FTE IS NOT NULL AND S.O_FTE > 0) THEN 1
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IS NULL AND (S.S_FTE IS NOT NULL AND S.S_FTE > 0) THEN 1
		--WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IS NULL AND (S.HV_FTE IS NOT NULL AND S.HV_FTE > 0) THEN 1
		WHEN S.PrimRole = 'Nurse Home Visitor' AND S.SecRole IS NULL AND (S.AA_FTE IS NOT NULL AND S.AA_FTE > 0) THEN 1
	END Missing2ndRoleHas2ndFTENHV
	,CASE 
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.HireDate IS NULL THEN 1 --'NoHire' 
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.EndDate < S.HireDate THEN 2 --'EndPriorHire' 
	END NShire
	,CASE
		WHEN S.PrimRole = 'Nurse Supervisor' AND (S.S_FTE IS NULL OR S.S_FTE = 0) THEN 1
	END NSFTEMissing
	,CASE 
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IN ('State Nurse Consultant','State Administrator','Agency Administrator','Program Coordinator/ Manager','Other') AND (S.O_FTE IS NULL OR S.O_FTE = 0) THEN 1
		--WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IN ('Nurse Supervisor') AND (S.S_FTE IS NULL OR S.S_FTE = 0) THEN 1
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IN ('Nurse Home Visitor') AND (S.HV_FTE IS NULL OR S.HV_FTE = 0) THEN 1
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IN ('Data Entry/Administrative') AND (S.AA_FTE IS NULL OR S.AA_FTE = 0) THEN 1
	END Missing2ndFTEHas2ndRoleNS
	,CASE 
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IS NULL AND (S.O_FTE IS NOT NULL AND S.O_FTE > 0) THEN 1
		--WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IS NULL AND (S.S_FTE IS NOT NULL AND S.S_FTE > 0) THEN 1
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IS NULL AND (S.HV_FTE IS NOT NULL AND S.HV_FTE > 0) THEN 1
		WHEN S.PrimRole = 'Nurse Supervisor' AND S.SecRole IS NULL AND (S.AA_FTE IS NOT NULL AND S.AA_FTE > 0) THEN 1
	END Missing2ndRoleHas2ndFTENS
	,CASE 
		WHEN S.SecRole IN ('Nurse Supervisor') AND (S.S_FTE IS NOT NULL AND S.S_FTE > 0) AND S.PrimRole IN ('State Nurse Consultant','State Administrator','Agency Administrator','Program Coordinator/ Manager','Other') AND (S.O_FTE IS NULL OR S.O_FTE = 0) THEN 1
		WHEN S.SecRole IN ('Nurse Home Visitor') AND (S.HV_FTE IS NOT NULL AND S.HV_FTE > 0) AND S.PrimRole IN ('State Nurse Consultant','State Administrator','Agency Administrator','Program Coordinator/ Manager','Other') AND (S.O_FTE IS NULL OR S.O_FTE = 0) THEN 1
		WHEN S.SecRole IN ('Nurse Supervisor') AND (S.S_FTE IS NOT NULL AND S.S_FTE > 0) AND S.PrimRole IN ('Data Entry/Administrative') AND (S.AA_FTE IS NULL OR S.AA_FTE = 0) THEN 1
		WHEN S.SecRole IN ('Nurse Home Visitor') AND (S.HV_FTE IS NOT NULL AND S.HV_FTE > 0) AND S.PrimRole IN ('Data Entry/Administrative') AND (S.AA_FTE IS NULL OR S.AA_FTE = 0) THEN 1
	END Missing1stFTEHas2ndRole
	,CASE 
		WHEN S.PrimRole IN ('State Nurse Consultant','State Administrator','Agency Administrator','Program Coordinator/ Manager','Other','Data Entry/Administrative') AND S.SecRole = 'Nurse Supervisor' AND (S.S_FTE IS NULL OR S.S_FTE = 0) THEN 1
		WHEN S.PrimRole IN ('State Nurse Consultant','State Administrator','Agency Administrator','Program Coordinator/ Manager','Other','Data Entry/Administrative') AND S.SecRole = 'Nurse Home Visitor' AND (S.HV_FTE IS NULL OR S.HV_FTE = 0) THEN 1
	END Missing2ndFTEHas2ndRole
FROM dbo.fn_FID_Staff_list (@rStartDate,@rEndDate) S
INNER JOIN UV_PAS P
	ON S.ProgramID = P.ProgramID
LEFT OUTER JOIN dbo.udf_NureseMostRecentHVE (@rStartDate,@rEndDate,@rParentEntity,@rREName,@rReportType) V
	ON S.Entity_Id = V.NURSE_PERSONAL_0_NAME
	AND S.ProgramID = V.ProgramID
--LEFT OUTER JOIN 
--	(SELECT WSS.NURSE_PERSONAL_0_NAME,WSS.ProgramID,WSS.SurveyDate
--	FROM (SELECT *,RANK() OVER(Partition By NURSE_PERSONAL_0_NAME,ProgramID Order By SurveyDate DESC,SurveyResponseID) rank FROM Weekly_Supervision_Survey) WSS
--	WHERE WSS.rank = 1) SupSup
--	ON S.Entity_Id = SupSup.NURSE_PERSONAL_0_NAME
--	AND S.Program_ID_Staff_Supervision = SupSup.ProgramID
LEFT OUTER JOIN 
	(SELECT WSS.NURSE_SUPERVISION_0_STAFF_SUP,WSS.ProgramID,WSS.SurveyDate
	FROM (SELECT *,RANK() OVER(Partition By NURSE_SUPERVISION_0_STAFF_SUP,ProgramID Order By SurveyDate DESC,SurveyResponseID) rank FROM Weekly_Supervision_Survey) WSS
	WHERE WSS.rank = 1) SupSup
	ON S.Entity_Id = SupSup.NURSE_SUPERVISION_0_STAFF_SUP
	AND S.Program_ID_Staff_Supervision = SupSup.ProgramID
WHERE 
	CASE
		WHEN @rReportType = 1 THEN 1
		WHEN @rReportType = 2 THEN P.StateID
		WHEN @rReportType = 3 THEN P.SiteID
		WHEN @rReportType = 4 THEN P.ProgramID
	  END IN (SELECT * FROM dbo.udf_ParseMultiParam (@rParentEntity))
	--AND S.StartDate >= @rStartDate
	  ) p

UNPIVOT
(Error FOR Category IN
	(p.ClientContact
	,p.NHVHire
	,p.SupervisorMeetings
	,p.NHVFTEMissing
	,p.Missing2ndFTEHas2ndRoleNHV
	,p.Missing2ndRoleHas2ndFTENHV
	,p.NShire
	,p.NSFTEMissing
	,p.Missing2ndFTEHas2ndRoleNS
	,p.Missing2ndRoleHas2ndFTENS
	,p.Missing1stFTEHas2ndRole
	,p.Missing2ndFTEHas2ndRole)
) unpvt
GO
