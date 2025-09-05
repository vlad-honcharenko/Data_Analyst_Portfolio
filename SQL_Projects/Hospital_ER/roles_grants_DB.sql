USE Hospital_Managment_Service_DB;
GO

-- 1. Create Roles for DB
CREATE ROLE SysAdmin;
CREATE ROLE Doctor;
CREATE ROLE LabSpecialist;
GO

-- 2. Permissions

-- SysAdmin - full database control
GRANT
    BACKUP DATABASE,
    BACKUP LOG,
    CREATE DEFAULT,
    CREATE FUNCTION,
    CREATE PROCEDURE,
    CREATE RULE,
    CREATE TABLE,
    CREATE VIEW,
    DELETE,
    SELECT,
    INSERT,
    UPDATE,
    ALTER,
    REFERENCES,
    EXECUTE,
    VIEW DEFINITION,
    CONTROL,
    TAKE OWNERSHIP
ON DATABASE::Hospital_Managment_Service_DB TO SysAdmin;

-- Doctor - manage patients, appointments, surgeries, prescriptions.
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Patient TO Doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Appointment TO Doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Surgery TO Doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Prescription TO Doctor;


-- LabSpecialist - handle lab tests & results.
GRANT SELECT ON dbo.Patient TO LabSpecialist;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.Appointment_MedicalTest TO LabSpecialist;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.MedicalTest TO LabSpecialist;

GO

-- 3. Create Logins

USE master;
GO
CREATE LOGIN DavidLogin WITH PASSWORD = 'AdminHospital#1';
CREATE LOGIN RayLogin WITH PASSWORD = 'DoctorHospital#1';
CREATE LOGIN RickLogin WITH PASSWORD = 'LabHospital#1';
GO

-- 4. Create Users inside Hospital DB

USE Hospital_Managment_Service_DB;
GO
CREATE USER David FOR LOGIN DavidLogin;
CREATE USER Ray   FOR LOGIN RayLogin;
CREATE USER Rick  FOR LOGIN RickLogin;
GO

-- Add users to roles
ALTER ROLE SysAdmin ADD MEMBER David;
ALTER ROLE Doctor ADD MEMBER Ray;
ALTER ROLE LabSpecialist ADD MEMBER Rick;
GO