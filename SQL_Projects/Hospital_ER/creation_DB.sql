IF EXISTS (
    SELECT name
    FROM sys.databases
    WHERE name = N'Hospital_Managment_Service_DB'
)
DROP DATABASE Hospital_Managment_Service_DB;
GO

CREATE DATABASE Hospital_Managment_Service_DB;
GO

USE Hospital_Managment_Service_DB;
GO


CREATE TABLE Address (
    addressID INT IDENTITY(1,1) PRIMARY KEY,
    streetNumber VARCHAR(10) NOT NULL,
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    region VARCHAR(100) NOT NULL
);


CREATE TABLE HospitalDepartment (
    departmentID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phoneNumber VARCHAR(15),
    email VARCHAR(255),
    addressID INT NOT NULL,
    FOREIGN KEY (addressID) REFERENCES Address(addressID) ON DELETE CASCADE
);


CREATE TABLE Position (
    positionID INT IDENTITY(1,1) PRIMARY KEY,
    positionName VARCHAR(100) NOT NULL,
    salary DECIMAL(10,2) CHECK (salary >= 0),
    experience INT CHECK (experience >= 0)
);


CREATE TABLE Doctor (
    doctorID INT IDENTITY(1,1) PRIMARY KEY,
    surname VARCHAR(100) NOT NULL,
    firstname VARCHAR(100) NOT NULL,
    specialization VARCHAR(100),
    phoneNumber VARCHAR(15),
    email VARCHAR(255),
    positionID INT NOT NULL,
    departmentID INT NOT NULL,
    FOREIGN KEY (positionID) REFERENCES Position(positionID) ON DELETE CASCADE,
    FOREIGN KEY (departmentID) REFERENCES HospitalDepartment(departmentID) ON DELETE NO ACTION
);


CREATE TABLE Staff (
    staffID INT IDENTITY PRIMARY KEY,
    firstname NVARCHAR(50) NOT NULL,
    surname NVARCHAR(50) NOT NULL,
    role NVARCHAR(50) NOT NULL,
    departmentID INT NULL,
    salary DECIMAL(10,2) NULL,
    experience INT NULL,
    phoneNumber NVARCHAR(20) NULL,
    email NVARCHAR(100) NULL,
    hireDate DATE DEFAULT GETDATE(),
    addressID INT NULL, 
    CONSTRAINT FK_Staff_Department FOREIGN KEY (departmentID) REFERENCES HospitalDepartment(departmentID)
    CONSTRAINT FK_Staff_Address FOREIGN KEY (addressID) REFERENCES Address(addressID)
);


CREATE TABLE MedCard (
    medCardID INT IDENTITY(1,1) PRIMARY KEY,
    bloodType VARCHAR(3) NOT NULL,
    allergies VARCHAR(255),
    chronicConditions VARCHAR(255),
    issueDate DATE NOT NULL,
    validUntil AS DATEADD(YEAR, 5, issueDate) PERSISTED
);


CREATE TABLE Patient (
    patientID BIGINT PRIMARY KEY,
    surname VARCHAR(100) NOT NULL,
    firstname VARCHAR(100) NOT NULL,
    dateOfBirth DATE NOT NULL,
    phoneNumber VARCHAR(15),
    email VARCHAR(255),
    medCardID INT UNIQUE,
    FOREIGN KEY (medCardID) REFERENCES MedCard(medCardID) ON DELETE CASCADE
);


CREATE TABLE Appointment (
    appointmentID INT IDENTITY(1,1) PRIMARY KEY,
    patientID BIGINT NOT NULL,
    doctorID INT NOT NULL,
    departmentID INT NOT NULL,
    dateTime DATETIME NOT NULL,
    status VARCHAR(50) CHECK (status IN ('scheduled','completed','cancelled')),
    FOREIGN KEY (patientID) REFERENCES Patient(patientID) ON DELETE CASCADE,
    FOREIGN KEY (doctorID) REFERENCES Doctor(doctorID) ON DELETE NO ACTION,
    FOREIGN KEY (departmentID) REFERENCES HospitalDepartment(departmentID) ON DELETE NO ACTION
);


CREATE TABLE Treatment (
    treatmentID INT IDENTITY(1,1) PRIMARY KEY,
    appointmentID INT NOT NULL,
    description VARCHAR(500) NOT NULL,
    result VARCHAR(255),
    FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID) ON DELETE CASCADE
);


CREATE TABLE Prescription (
    prescriptionID INT IDENTITY(1,1) PRIMARY KEY,
    patientID BIGINT NOT NULL,
    doctorID INT NOT NULL,
    medication VARCHAR(255) NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    duration VARCHAR(100),
    dateIssued DATE NOT NULL DEFAULT (CAST(GETDATE() AS DATE)),
    prescriptionExpiryDate DATE,
    FOREIGN KEY (patientID) REFERENCES Patient(patientID) ON DELETE CASCADE,
    FOREIGN KEY (doctorID) REFERENCES Doctor(doctorID) ON DELETE NO ACTION
);


CREATE TABLE MedicalTest (
    testID INT IDENTITY(1,1) PRIMARY KEY,
    patientID BIGINT NOT NULL,
    doctorID INT NOT NULL,
    type VARCHAR(100) NOT NULL,
    result VARCHAR(255),
    testDate DATE NOT NULL,
    FOREIGN KEY (patientID) REFERENCES Patient(patientID) ON DELETE CASCADE,
    FOREIGN KEY (doctorID) REFERENCES Doctor(doctorID) ON DELETE NO ACTION
);


CREATE TABLE Appointment_MedicalTest (
    appointmentID INT NOT NULL,
    testID INT NOT NULL,
    PRIMARY KEY (appointmentID, testID),
    FOREIGN KEY (appointmentID) REFERENCES Appointment(appointmentID) ON DELETE CASCADE,
    FOREIGN KEY (testID) REFERENCES MedicalTest(testID) ON DELETE CASCADE
);


CREATE TABLE InsuranceProvider (
    providerID INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255)
);


CREATE TABLE InsurancePolicy (
    policyID INT IDENTITY(1,1) PRIMARY KEY,
    providerID INT NOT NULL,
    patientID BIGINT NOT NULL,
    coverageDetails VARCHAR(500),
    expiryDate DATE,
    status VARCHAR(20) DEFAULT 'Active',
    FOREIGN KEY (providerID) REFERENCES InsuranceProvider(providerID),
    FOREIGN KEY (patientID) REFERENCES Patient(patientID)
);


CREATE TABLE OperatingRoom (
    roomID INT IDENTITY(1,1) PRIMARY KEY,
    roomNumber VARCHAR(50) NOT NULL,
    status VARCHAR(50) CHECK (status IN ('Available', 'In Use'))
);


CREATE TABLE Surgery (
    surgeryID INT IDENTITY(1,1) PRIMARY KEY,
    patientID BIGINT NOT NULL,
    doctorID INT NOT NULL,
    roomID INT,
    surgeryDate DATETIME NOT NULL,
    surgeryType VARCHAR(255) NOT NULL,
    outcome VARCHAR(255),
    FOREIGN KEY (patientID) REFERENCES Patient(patientID),
    FOREIGN KEY (doctorID) REFERENCES Doctor(doctorID),
    FOREIGN KEY (roomID) REFERENCES OperatingRoom(roomID)
);


CREATE TABLE SurgeryTeam (
    surgeryID INT NOT NULL PRIMARY KEY,
    staffIDs NVARCHAR(MAX) NOT NULL,
    roles NVARCHAR(MAX) NOT NULL,
    FOREIGN KEY (surgeryID) REFERENCES Surgery(surgeryID)
);
