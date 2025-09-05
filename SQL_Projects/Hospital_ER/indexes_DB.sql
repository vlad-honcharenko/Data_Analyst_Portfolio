USE Hospital_Managment_Service_DB;
GO

-- Indexes for search by surname.
CREATE NONCLUSTERED INDEX IX_Patient_Surname 
    ON Patient(surname);


-- Optimize lookups by patient
CREATE NONCLUSTERED INDEX IX_InsurancePolicy_Patient 
    ON InsurancePolicy(patientID);


-- Frequent queries: find appointments by patient, doctor, and datetime
CREATE NONCLUSTERED INDEX IX_Appointment_Patient_Doctor_DateTime 
    ON Appointment(patientID, doctorID, dateTime);


-- Optimizing by patient and surgery date
CREATE NONCLUSTERED INDEX IX_Surgery_Patient_Date 
    ON Surgery(patientID, surgeryDate);


-- Indexing SurgeryID for fast team lookup
CREATE NONCLUSTERED INDEX IX_SurgeryTeam_Surgery 
    ON SurgeryTeam(surgeryID);


-- Optimizing by patient and doctor.
CREATE NONCLUSTERED INDEX IX_Prescription_Patient_Doctor
    ON Prescription(patientID, doctorID);


-- Optimizing by patient and test date
CREATE NONCLUSTERED INDEX IX_MedicalTest_Patient_Date 
    ON MedicalTest(patientID, testDate);