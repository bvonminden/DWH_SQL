USE [DataWarehouse]
GO
/****** Object:  StoredProcedure [dbo].[exemption]    Script Date: 11/16/2017 10:44:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[exemption]
as
SELECT  
dbo.Clients.Site_ID as SiteID, 
dbo.Clients.Client_Id as ClientID, 
dbo.Clients.DOB as ClientDOB, 
dbo.Infant_Birth_Survey.INFANT_BIRTH_0_DOB as InfantDOB
FROM     dbo.Clients RIGHT OUTER JOIN
               dbo.Infant_Birth_Survey ON dbo.Clients.Client_Id = dbo.Infant_Birth_Survey.CL_EN_GEN_ID
WHERE  (dbo.Clients.DOB > dbo.Infant_Birth_Survey.INFANT_BIRTH_0_DOB) AND (dbo.Infant_Birth_Survey.SiteID NOT IN (74, 78, 285, 291, 294))



SELECT  
dbo.Clients.Site_ID as SiteID, 
dbo.Clients.Client_Id as ClientID, 
dbo.Clients.DOB as ClientDOB, 
dbo.Infant_Birth_Survey.INFANT_BIRTH_0_DOB as InfantDOB
FROM     dbo.Clients RIGHT OUTER JOIN
               dbo.Infant_Birth_Survey ON dbo.Clients.Client_Id = dbo.Infant_Birth_Survey.CL_EN_GEN_ID
WHERE  (dbo.Clients.DOB > dbo.Infant_Birth_Survey.INFANT_BIRTH_0_DOB) AND (dbo.Infant_Birth_Survey.SiteID NOT IN (74, 78, 285, 291, 294))
execute exemption
GO
