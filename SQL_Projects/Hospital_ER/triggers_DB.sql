-- Auto-cancel past appointments
CREATE OR ALTER TRIGGER trg_AutoCancelPastAppointments
ON Appointment
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE Appointment
    SET status = 'missed'
    WHERE dateTime < GETDATE() AND status = 'scheduled';
END;


-- Prevent overlapping surgeries in the same room
CREATE OR ALTER TRIGGER trg_PreventOverlappingSurgeries
ON Surgery
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Surgery S
        JOIN inserted I ON S.roomID = I.roomID
        WHERE CAST(S.surgeryDate AS DATE) = CAST(I.surgeryDate AS DATE)
    )
    BEGIN
        RAISERROR ('This operating room is already booked for that date!', 16, 1);
        ROLLBACK TRANSACTION;
    END
    ELSE
    BEGIN
        INSERT INTO Surgery (patientID, doctorID, surgeryDate, surgeryType, roomID)
        SELECT patientID, doctorID, surgeryDate, surgeryType, roomID
        FROM inserted;
    END
END;


-- Auto-update insurance status after expiry
CREATE OR ALTER TRIGGER trg_UpdateInsuranceStatus
ON InsurancePolicy
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE InsurancePolicy
    SET status = 'expired'
    WHERE expiryDate < GETDATE() AND status != 'expired';
END;


-- Auto-calculate expiryDate for prescriptions

CREATE OR ALTER TRIGGER trg_SetPrescriptionExpiry
ON Prescription
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE p
    SET prescriptionExpiryDate = DATEADD(DAY, TRY_CAST(i.duration AS INT), i.dateIssued)
    FROM Prescription p
    JOIN inserted i ON p.prescriptionID = i.prescriptionID
    WHERE ISNUMERIC(i.duration) = 1; -- only if duration is numeric
END;


-- Prevent overlapping appointments for the same doctor
CREATE OR ALTER TRIGGER PreventDoctorDoubleBooking
ON Appointment
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Appointment A
        JOIN inserted i ON A.doctorID = i.doctorID
        WHERE A.appointmentID <> i.appointmentID
          AND ABS(DATEDIFF(MINUTE, A.dateTime, i.dateTime)) < 30
    )
    BEGIN
        RAISERROR ('Doctor already has an appointment in this time slot!', 16, 1);
        ROLLBACK;
    END
END;


-- Enforce that each surgery has at least one assigned team member

CREATE OR ALTER TRIGGER CheckSurgeryTeam
ON Surgery
AFTER INSERT
AS
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM SurgeryTeam ST
        JOIN inserted i ON ST.surgeryID = i.surgeryID
    )
    BEGIN
        RAISERROR('Surgery must have at least one team member assigned!', 16, 1);
        ROLLBACK;
    END
END;


-- Prevent assigning a patient to two surgeries at the same time
CREATE OR ALTER TRIGGER PreventPatientDoubleSurgery
ON Surgery
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Surgery S1
        JOIN Surgery S2 ON S1.patientID = S2.patientID 
                       AND S1.surgeryID <> S2.surgeryID
        JOIN inserted i ON S1.surgeryID = i.surgeryID
        WHERE ABS(DATEDIFF(HOUR, S1.surgeryDate, S2.surgeryDate)) < 2
    )
    BEGIN
        RAISERROR('Patient cannot have overlapping surgeries!', 16, 1);
        ROLLBACK;
    END
END;


-- Automatically set default dosage in prescriptions if missing

CREATE OR ALTER TRIGGER DefaultPrescriptionDosage
ON Prescription
AFTER INSERT
AS
BEGIN
    UPDATE P
    SET dosage = '1 tablet twice daily'
    FROM Prescription P
    JOIN inserted i ON P.prescriptionID = i.prescriptionID
    WHERE i.dosage IS NULL;
END;


-- Prevent lab tests being assigned to patients without appointments

CREATE OR ALTER TRIGGER ValidateMedicalTest
ON MedicalTest
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            SELECT 1 
            FROM Appointment A 
            WHERE A.patientID = i.patientID
        )
    )
    BEGIN
        RAISERROR('Patient must have an appointment before taking a medical test!', 16, 1);
        ROLLBACK;
    END
END;



-- Number of surgeries per doctor per day (audit table)
CREATE OR ALTER TRIGGER LogDoctorSurgeries
ON Surgery
AFTER INSERT
AS
BEGIN
    INSERT INTO Audit_DoctorSurgeries (doctorID, surgeryDate, surgeryCount)
    SELECT i.doctorID, CAST(i.surgeryDate AS DATE), COUNT(*)
    FROM inserted i
    GROUP BY i.doctorID, CAST(i.surgeryDate AS DATE);
END;