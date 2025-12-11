
CREATE TABLE employee_login(
    loginInfoId INTEGER PRIMARY KEY AUTOINCREMENT,
    employeeId VARCHAR(10) NOT NULL,
    employeeUserName VARCHAR(50) NOT NULL,
    employeePassword VARCHAR(50) NOT NULL
);


INSERT INTO employee_login (employeeId, employeeUserName, employeePassword)
VALUES
('E101', 'MarySmith', 'Pass!9021'),
('E102', 'PettyRandal', 'Petty@123'),
('E103', 'SussieNg', 'p@SS789'),
('E104', 'WillLaForrest', 'Hotel@2025'),
('E105', 'KerrySmith', 'Password#55');


