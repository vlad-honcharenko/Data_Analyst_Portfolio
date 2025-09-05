-- 1.1 GetDoctorCountInDepartment
CREATE OR ALTER FUNCTION GetDoctorCountInDepartment(@departmentID INT)
RETURNS INT
AS
BEGIN
    DECLARE @doctorCount INT;
    SELECT @doctorCount = COUNT(*)
    FROM Doctor
    WHERE departmentID = @departmentID;
    RETURN @doctorCount;
END;


-- 1.2 GetAverageSalaryByPosition
CREATE OR ALTER FUNCTION GetAverageSalaryByPosition(@positionName VARCHAR(100))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @avgSalary DECIMAL(10,2);
    SELECT @avgSalary = AVG(salary)
    FROM Position
    WHERE positionName = @positionName;
    RETURN @avgSalary;
END;


-- 1.3 GetPatientAge
CREATE OR ALTER FUNCTION GetPatientAge(@patientID BIGINT)
RETURNS INT
AS
BEGIN
    DECLARE @age INT;
    SELECT @age = DATEDIFF(YEAR, dateOfBirth, GETDATE())
    FROM Patient
    WHERE patientID = @patientID;
    RETURN @age;
END;


-- 1.4 UpcomingAppointments (returns table)
CREATE OR ALTER FUNCTION UpcomingAppointments(@patientID BIGINT)
RETURNS TABLE
AS
RETURN
(
    SELECT A.appointmentID, A.dateTime, D.firstname + ' ' + D.surname AS DoctorName
    FROM Appointment A
    JOIN Doctor D ON A.doctorID = D.doctorID
    WHERE A.patientID = @patientID
      AND A.dateTime > GETDATE()
);
    

-- 1.5 CheckRoomAvailability
CREATE OR ALTER FUNCTION CheckRoomAvailability(@roomID INT, @date DATETIME)
RETURNS BIT
AS
BEGIN
    DECLARE @isAvailable BIT = 1;
    IF EXISTS (
        SELECT 1 FROM Surgery
        WHERE roomID = @roomID AND CAST(surgeryDate AS DATE) = CAST(@date AS DATE)
    )
        SET @isAvailable = 0;
    RETURN @isAvailable;
END;


-- 1.6 Number of appointments a doctor has within a period
CREATE OR ALTER FUNCTION dbo.GetDoctorWorkload(@doctorID INT, @startDate DATE, @endDate DATE)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*)
    FROM Appointment
    WHERE doctorID = @doctorID
      AND dateTime BETWEEN @startDate AND @endDate;
    RETURN @count;
END;


-- 1.7 Average value of a numeric lab test for a patient
CREATE OR ALTER FUNCTION dbo.GetAverageLabResult(@patientID INT, @testName NVARCHAR(100))
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @avg DECIMAL(10,2);
    SELECT @avg = AVG(CAST(resultValue AS DECIMAL(10,2)))
    FROM LabResult LR
    INNER JOIN LabTest LT ON LR.testID = LT.testID
    WHERE LR.patientID = @patientID AND LT.testName = @testName;
    RETURN @avg;
END;



-- 2.1 GetAppointmentsByDoctor
CREATE OR ALTER PROCEDURE GetAppointmentsByDoctor @doctorID INT
AS
BEGIN
    SELECT A.appointmentID, A.dateTime, P.firstname + ' ' + P.surname AS PatientName, A.status
    FROM Appointment A
    JOIN Patient P ON A.patientID = P.patientID
    WHERE A.doctorID = @doctorID
    ORDER BY A.dateTime;
END;


-- 2.2 GetPatientMedicalHistory
CREATE OR ALTER PROCEDURE GetPatientMedicalHistory @patientID BIGINT
AS
BEGIN
    SELECT 'Treatment' AS RecordType, T.description, T.result, A.dateTime
    FROM Treatment T
    JOIN Appointment A ON T.appointmentID = A.appointmentID
    WHERE A.patientID = @patientID

    UNION ALL

    SELECT 'Prescription', PR.medication, PR.dosage, NULL
    FROM Prescription PR
    WHERE PR.patientID = @patientID

    UNION ALL

    SELECT 'Medical Test', MT.type, MT.result, MT.testDate
    FROM MedicalTest MT
    WHERE MT.patientID = @patientID
    ORDER BY dateTime;
END;


-- 2.3 ScheduleAppointment
CREATE OR ALTER PROCEDURE ScheduleAppointment
    @patientID BIGINT,
    @doctorID INT,
    @departmentID INT,
    @dateTime DATETIME
AS
BEGIN
    INSERT INTO Appointment (patientID, doctorID, departmentID, dateTime, status)
    VALUES (@patientID, @doctorID, @departmentID, @dateTime, 'scheduled');
END;


-- 2.4 CancelAppointment
CREATE OR ALTER PROCEDURE CancelAppointment @appointmentID INT
AS
BEGIN
    UPDATE Appointment
    SET status = 'cancelled'
    WHERE appointmentID = @appointmentID;
END;


-- 2.5 GetSurgerySchedule
CREATE OR ALTER PROCEDURE GetSurgerySchedule @date DATE
AS
BEGIN
    SELECT S.surgeryID, P.firstname + ' ' + P.surname AS PatientName,
           D.firstname + ' ' + D.surname AS DoctorName, 
           O.roomNumber, S.surgeryType, S.surgeryDate
    FROM Surgery S
    JOIN Patient P ON S.patientID = P.patientID
    JOIN Doctor D ON S.doctorID = D.doctorID
    JOIN OperatingRoom O ON S.roomID = O.roomID
    WHERE CAST(S.surgeryDate AS DATE) = @date;
END;


-- 2.6 Aggregate doctor’s work within a month
CREATE OR ALTER PROCEDURE dbo.GenerateMonthlyDoctorReport
    @doctorID INT,
    @month INT,
    @year INT
AS
BEGIN
    SELECT 
        D.firstname + ' ' + D.surname AS DoctorName,
        COUNT(DISTINCT A.appointmentID) AS TotalAppointments,
        COUNT(DISTINCT S.surgeryID) AS TotalSurgeries,
        COUNT(DISTINCT P.prescriptionID) AS TotalPrescriptions
    FROM Doctor D
    LEFT JOIN Appointment A ON D.doctorID = A.doctorID 
        AND MONTH(A.dateTime) = @month 
        AND YEAR(A.dateTime) = @year
    LEFT JOIN Surgery S ON D.doctorID = S.doctorID
        AND MONTH(S.surgeryDate) = @month
        AND YEAR(S.surgeryDate) = @year
    LEFT JOIN Prescription P ON D.doctorID = P.doctorID
        AND MONTH(P.dateIssued) = @month
        AND YEAR(P.dateIssued) = @year
    WHERE D.doctorID = @doctorID
    GROUP BY D.firstname, D.surname;
END;


-- 2.7 Surgery details
CREATE OR ALTER PROCEDURE dbo.GetSurgeryDetails
    @surgeryID INT
AS
BEGIN
    SELECT 
        S.surgeryID, 
        P.firstname + ' ' + P.surname AS PatientName,
        D.firstname + ' ' + D.surname AS LeadSurgeon,
        O.roomNumber,
        S.surgeryDate, 
        S.surgeryType,
        S.outcome
    FROM Surgery S
    INNER JOIN Patient P ON S.patientID = P.patientID
    INNER JOIN Doctor D ON S.doctorID = D.doctorID
    INNER JOIN OperatingRoom O ON S.roomID = O.roomID
    WHERE S.surgeryID = @surgeryID;
END;


-- 2.8 Insert a new surgery with all basic information
CREATE OR ALTER PROCEDURE dbo.ScheduleSurgery
    @patientID BIGINT,
    @doctorID INT,
    @roomID INT,
    @surgeryDate DATETIME,
    @surgeryType VARCHAR(255)
AS
BEGIN
    INSERT INTO Surgery (patientID, doctorID, roomID, surgeryDate, surgeryType)
    VALUES (@patientID, @doctorID, @roomID, @surgeryDate, @surgeryType);

    PRINT 'Surgery scheduled successfully.';
END;


-- 2.9 Updating staff list and roles for an existing surgery
CREATE OR ALTER PROCEDURE dbo.UpdateSurgeryTeam
    @surgeryID INT,
    @staffIDs NVARCHAR(MAX),
    @roles NVARCHAR(MAX)
AS
BEGIN
    UPDATE SurgeryTeam
    SET staffIDs = @staffIDs, roles = @roles
    WHERE surgeryID = @surgeryID;

    PRINT 'Surgery team updated successfully.';
END;