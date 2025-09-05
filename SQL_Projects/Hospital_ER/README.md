# Hospital Management Service Database (ER Project)



This database implements a **Hospital Management System** database in Microsoft SQL Server.  
It covers hospital departments, staff, patients, appointments, treatments, insurance policies, surgeries, prescriptions, and more.  
  

The database is designed to:
- Store **patient records** and their medical history.
- Manage **doctors, nurses, and staff** with their roles & departments.
- Track **appointments, treatments, prescriptions, surgeries, and lab tests**.
- Manage **insurance policies** and validate expiration automatically.
- Provide **views, triggers, procedures, and indexes** for real-world hospital workflow support.
---

# Database Structure

## ER-model

![ER-model](.\image\Diagram_DB.png)

---

### Tables

#### Address
Stores information about addresses, including street number, street, city, and region.

#### HospitalDepartment
Contains details about hospital departments, including department name, phone number, email, and a foreign key referencing the Address table.

#### Department
Defines standard departments (Cardiology, Neurology, Surgery, etc.) used to assign staff.

#### Position
Holds information about positions within the hospital, such as position name, salary, and required experience.

#### Staff
Represents hospital staff members (doctors, nurses, specialists), including personal details, foreign keys linking to Position, Department, and Address.

#### MedCard
Stores medical card details, including blood type, allergies, chronic conditions, issue date, and calculated validity period.

#### Patient
Contains information about patients, including name, date of birth, contact details, and a foreign key referencing MedCard.

#### Appointment
Manages appointments between patients and doctors, including date, time, department, and status.

#### Treatment
Stores treatments linked to appointments, including description and results.

#### Prescription
Manages prescribed medications, including dosage, duration, and issue date.

#### MedicalTest
Contains information about medical tests, including type, result, test date, and references to patient and doctor.

#### Appointment_MedicalTest
Establishes a many-to-many relationship between appointments and medical tests.

#### InsuranceProvider
Stores insurance provider details, including name, phone, and email.

#### InsurancePolicy
Manages patient insurance policies, including coverage details, expiry date, and references to InsuranceProvider and Patient.

#### OperatingRoom
Contains operating room details, including room number and current status.

#### Surgery
Stores details about surgeries, including patient, doctor, room, surgery type, outcome, and date.

#### SurgeryTeam
Links staff to a surgery in JSON-like arrays (staffIDs and roles) to represent surgeons, nurses, and anesthesiologists working in the same operation.

---

## Constraints and Relationships

- **Foreign key constraints** ensure data integrity across patients, doctors, staff, and departments.  
- **Check constraints** validate business rules such as valid salary amounts, appointment status, and room availability.  
- **Cascading rules** manage deletion behavior for related records (e.g., patient deletions cascade to appointments and prescriptions).  
