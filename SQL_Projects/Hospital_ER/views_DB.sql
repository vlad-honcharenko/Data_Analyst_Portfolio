USE Hospital_Managment_Service_DB;
GO


CREATE OR ALTER VIEW StaffDetails AS
SELECT 
    s.staffID,
    CONCAT_WS(' ', s.surname, s.firstname) AS FullName,
    s.role,
    d.name,
    s.salary,
    s.experience,
    a.city AS centerCity,
    a.region AS centerRegion
FROM Staff s
LEFT JOIN Address a ON s.addressID = a.addressID
LEFT JOIN HospitalDepartment d ON d.departmentID = s.departmentID;

-- SELECT * FROM StaffDetails;


CREATE OR ALTER VIEW AppointmentsWithDoctors AS
SELECT
    a.appointmentID,
    a.dateTime AS appointmentDate,
    p.patientID,
    CONCAT_WS(' ', p.surname, p.firstname) AS PatientName,
    p.phoneNumber AS PatientPhone,
    d.doctorID AS DoctorID,
    CONCAT_WS(' ', d.surname, d.firstname) AS DoctorName,
    hd.name AS DoctorDepartment
FROM Appointment a
JOIN Patient p ON a.patientID = p.patientID
JOIN Doctor d ON a.doctorID = d.doctorID
JOIN HospitalDepartment hd ON hd.departmentID = d.departmentID;

-- SELECT * FROM AppointmentsWithDoctors;


CREATE OR ALTER VIEW PatientInsuranceDetails AS
SELECT
    ip.policyID,
    p.patientID,
    CONCAT_WS(' ', p.surname, p.firstname) AS PatientName,
    i.name,
    ip.coverageDetails,
    CASE WHEN ip.expiryDate >= CAST(GETDATE() AS DATE) THEN 'Active'
         ELSE 'Expired'
    END AS PolicyStatus
FROM InsurancePolicy ip
JOIN Patient p ON ip.patientID = p.patientID
JOIN InsuranceProvider i ON ip.providerID = i.providerID;

-- SELECT * FROM PatientInsuranceDetails;


CREATE OR ALTER VIEW SurgeryOverview AS
SELECT
    s.surgeryID,
    s.surgeryDate,
    s.surgeryType,
    s.outcome,
    p.patientID,
    CONCAT_WS(' ', p.surname, p.firstname) AS PatientName,
    st.staffIDs,
    st.roles
FROM Surgery s
JOIN Patient p ON s.patientID = p.patientID
LEFT JOIN SurgeryTeam st ON s.surgeryID = st.surgeryID;

-- SELECT * FROM SurgeryOverview;


CREATE OR ALTER VIEW LabTestDetails AS
SELECT
    mt.testID,
    mt.patientID,
    CONCAT_WS(' ', p.surname, p.firstname) AS PatientName,
    mt.testDate,
    mt.type,
    mt.result,
    s.staffID AS SpecialistID,
    CONCAT_WS(' ', s.surname, s.firstname) AS LabSpecialist
FROM MedicalTest mt
JOIN Patient p ON mt.patientID = p.patientID
LEFT JOIN Staff s ON mt.doctorID = s.staffID;

-- SELECT * FROM LabTestDetails;


USE Hospital_Managment_Service_DB;
GO


CREATE OR ALTER VIEW UpcomingAppointments AS
SELECT 
    a.appointmentID,
    a.dateTime AS appointmentDate,
    p.patientID,
    p.firstname + ' ' + p.surname AS patientName,
    p.phoneNumber AS patientPhone,
    s.staffID AS doctorID,
    s.firstname + ' ' + s.surname AS doctorName,
    s.department
FROM Appointment a
JOIN Patient p ON a.patientID = p.patientID
JOIN Staff s ON a.doctorID = s.staffID
WHERE a.dateTime >= GETDATE();

-- SELECT * FROM UpcomingAppointments;


CREATE OR ALTER VIEW PatientMedicalHistory AS
SELECT 
    p.patientID,
    p.firstname + ' ' + p.surname AS patientName,
    a.dateTime AS appointmentDate,
    pr.dateIssued AS prescriptionDate,
    pr.medication,
    pr.dosage,
    srg.surgeryDate,
    srg.surgeryType,
    mt.testDate,
    mt.type,
    mt.result
FROM Patient p
LEFT JOIN Appointment a ON p.patientID = a.patientID
LEFT JOIN Prescription pr ON p.patientID = pr.patientID
LEFT JOIN Surgery srg ON p.patientID = srg.patientID
LEFT JOIN MedicalTest mt ON p.patientID = mt.patientID;

-- SELECT * FROM PatientMedicalHistory WHERE patientID = 10;


CREATE OR ALTER VIEW ActiveInsurancePolicies AS
SELECT 
    i.policyID,
    i.patientID,
    p.firstname + ' ' + p.surname AS patientName,
    ip.name,
    i.coverageDetails,
    CASE 
        WHEN i.expiryDate >= CAST(GETDATE() AS DATE) THEN 'Active'
        ELSE 'Expired'
    END AS policyStatus
FROM InsurancePolicy i
JOIN Patient p ON i.patientID = p.patientID
JOIN InsuranceProvider ip ON ip.providerID = i.providerID;

-- SELECT * FROM ActiveInsurancePolicies;


CREATE OR ALTER VIEW StaffWorkload AS
SELECT 
    s.staffID,
    s.firstname + ' ' + s.surname AS staffName,
    s.role,
    s.department,
    COUNT(DISTINCT a.appointmentID) AS totalAppointments,
    COUNT(DISTINCT sr.surgeryID) AS totalSurgeries
FROM Staff s
LEFT JOIN Appointment a ON s.staffID = a.doctorID
LEFT JOIN SurgeryTeam st ON JSON_VALUE(st.staffIDs, '$[0]') = CAST(s.staffID AS NVARCHAR) 
                          OR st.staffIDs LIKE '%"' + CAST(s.staffID AS NVARCHAR) + '"%'
LEFT JOIN Surgery sr ON st.surgeryID = sr.surgeryID
GROUP BY s.staffID, s.firstname, s.surname, s.role, s.department;

-- SELECT * FROM StaffWorkload;