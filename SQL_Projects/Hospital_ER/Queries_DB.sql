-- 1. Find top 5 doctors with the most appointments
WITH DoctorAppointments AS (
    SELECT doctorID, COUNT(*) AS totalAppointments
    FROM Appointment
    GROUP BY doctorID
)
SELECT TOP 5 
    D.firstname, D.surname, DA.totalAppointments
FROM Doctor D
JOIN DoctorAppointments DA ON D.doctorID = DA.doctorID
ORDER BY DA.totalAppointments DESC;


-- 2. List patients with upcoming surgeries in the next 30 days
SELECT 
    P.firstname, P.surname, S.surgeryDate, S.surgeryType
FROM Patient P
JOIN Surgery S ON P.patientID = S.patientID
WHERE S.surgeryDate BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE());


-- 3. Find departments with the highest number of doctors
SELECT 
    HD.name AS Department,
    COUNT(D.doctorID) AS TotalDoctors
FROM HospitalDepartment HD
LEFT JOIN Doctor D ON HD.departmentID = D.departmentID
GROUP BY HD.name
ORDER BY COUNT(D.doctorID) DESC;


-- 4. Show patients who had more than 3 appointments in the past 6 months
SELECT 
    P.firstname, P.surname, COUNT(A.appointmentID) AS totalAppointments
FROM Patient P
JOIN Appointment A ON P.patientID = A.patientID
WHERE A.dateTime >= DATEADD(MONTH, -6, GETDATE())
GROUP BY P.firstname, P.surname
HAVING COUNT(A.appointmentID) > 3;


-- 5. Average salary per position and how each doctor compares
SELECT 
    P.positionName,
    D.firstname, D.surname,
    Pos.salary,
    AVG(Pos.salary) OVER (PARTITION BY P.positionName) AS AvgSalaryForRole
FROM Doctor D
JOIN Position Pos ON D.positionID = Pos.positionID
JOIN Position P ON D.positionID = P.positionID;


-- 6. Find patients whose insurance expires within 60 days
SELECT 
    P.firstname, P.surname, I.expiryDate, Pr.name AS Provider
FROM Patient P
JOIN InsurancePolicy I ON P.patientID = I.patientID
JOIN InsuranceProvider Pr ON I.providerID = Pr.providerID
WHERE I.expiryDate BETWEEN GETDATE() AND DATEADD(DAY, 60, GETDATE());


-- 7. List the most common medical tests ordered
SELECT TOP 5 
    MT.type, COUNT(*) AS TestCount
FROM MedicalTest MT
GROUP BY MT.type
ORDER BY COUNT(*) DESC;


-- 8. Find doctors who performed surgeries but have no appointments
SELECT 
    D.firstname, D.surname
FROM Doctor D
WHERE D.doctorID IN (SELECT doctorID FROM Surgery)
  AND D.doctorID NOT IN (SELECT doctorID FROM Appointment);


-- 9. Ranking patients by number of prescriptions received
SELECT 
    P.firstname, P.surname,
    COUNT(Pr.prescriptionID) AS TotalPrescriptions,
    RANK() OVER (ORDER BY COUNT(Pr.prescriptionID) DESC) AS RankByPrescriptions
FROM Patient P
JOIN Prescription Pr ON P.patientID = Pr.patientID
GROUP BY P.firstname, P.surname;


-- 10. Doctors supervising multiple departments
SELECT 
    D.firstname, D.surname, COUNT(DISTINCT D.departmentID) AS DeptCount
FROM Doctor D
GROUP BY D.firstname, D.surname
HAVING COUNT(DISTINCT D.departmentID) > 1;


-- 11. Showing surgeries that did not have a recorded outcome
SELECT 
    S.surgeryID, P.firstname, P.surname, S.surgeryDate, S.surgeryType
FROM Surgery S
JOIN Patient P ON S.patientID = P.patientID
WHERE S.outcome IS NULL;


-- 12. Patients with both chronic conditions and allergies
SELECT 
    P.firstname, P.surname, MC.chronicConditions, MC.allergies
FROM Patient P
JOIN MedCard MC ON P.medCardID = MC.medCardID
WHERE MC.chronicConditions IS NOT NULL
  AND MC.allergies IS NOT NULL;


-- 13. Average number of appointments per patient
SELECT 
    AVG(AppointmentCount) AS AvgAppointmentsPerPatient
FROM (
    SELECT COUNT(*) AS AppointmentCount
    FROM Appointment
    GROUP BY patientID
) t;


-- 14. For each department, listing top doctor by appointment count
WITH DeptDoctor AS (
    SELECT 
        departmentID, doctorID,
        COUNT(*) AS TotalAppointments
    FROM Appointment
    GROUP BY departmentID, doctorID
)
SELECT 
    HD.name AS Department,
    D.firstname, D.surname,
    DD.TotalAppointments
FROM DeptDoctor DD
JOIN Doctor D ON DD.doctorID = D.doctorID
JOIN HospitalDepartment HD ON DD.departmentID = HD.departmentID
WHERE DD.TotalAppointments = (
    SELECT MAX(TotalAppointments)
    FROM DeptDoctor d2
    WHERE d2.departmentID = DD.departmentID
);


-- 15. Patients without insurance policies
SELECT 
    P.firstname, P.surname
FROM Patient P
WHERE NOT EXISTS (
    SELECT 1 FROM InsurancePolicy IP WHERE IP.patientID = P.patientID
);


-- 16. Surgeries per operating room ranked
SELECT 
    O.roomNumber,
    COUNT(S.surgeryID) AS TotalSurgeries,
    DENSE_RANK() OVER (ORDER BY COUNT(S.surgeryID) DESC) AS RankByUsage
FROM OperatingRoom O
LEFT JOIN Surgery S ON O.roomID = S.roomID
GROUP BY O.roomNumber;


-- 17. List patients who had both a medical test and a surgery
SELECT DISTINCT 
    P.firstname, P.surname, MT.type, MT.result
FROM Patient P
JOIN MedicalTest MT ON MT.patientID = P.patientID
WHERE P.patientID IN (SELECT patientID FROM MedicalTest)
  AND P.patientID IN (SELECT patientID FROM Surgery);


-- 18. Average outcome success rate per doctor
SELECT 
    D.firstname, D.surname,
    SUM(CASE WHEN S.outcome LIKE '%Success%' THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS SuccessRate
FROM Doctor D
JOIN Surgery S ON D.doctorID = S.doctorID
GROUP BY D.firstname, D.surname;


-- 19. Latest prescription per patient
SELECT 
    P.firstname, P.surname,
    Pr.medication, Pr.dosage, Pr.duration
FROM Patient P
JOIN Prescription Pr ON P.patientID = Pr.patientID
WHERE Pr.prescriptionID = (
    SELECT TOP 1 prescriptionID
    FROM Prescription
    WHERE patientID = P.patientID
    ORDER BY prescriptionID DESC
);


-- 20. Patients with the most diverse doctors
SELECT 
    P.firstname, P.surname,
    COUNT(DISTINCT D.specialization) AS UniqueSpecializations
FROM Patient P
JOIN Appointment A ON P.patientID = A.patientID
JOIN Doctor D ON A.doctorID = D.doctorID
GROUP BY P.firstname, P.surname
ORDER BY COUNT(DISTINCT D.specialization) DESC;