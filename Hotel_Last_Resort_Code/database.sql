-- Rooms and buildings
CREATE TABLE room_kind(
    roomKindId INTEGER PRIMARY KEY AUTO_INCREMENT,
    roomKindName VARCHAR(50) NOT NULL
);

CREATE TABLE room_function(
    roomFunctionId INTEGER PRIMARY KEY AUTO_INCREMENT,
    roomFunctionName VARCHAR(50) NOT NULL
);

CREATE TABLE bed_kind(
    bedKindId INTEGER PRIMARY KEY AUTO_INCREMENT,
    bedKindName VARCHAR(50) NOT NULL
);

#### Generated Code Base 
#### 改一改加点东西进去吧

#### Building and Location structure 
CREATE TABLE building (
    buildingID INT PRIMARY KEY,
    completed BOOLEAN,
    country VARCHAR(100),
    state VARCHAR(100),
    city VARCHAR(100),
    street VARCHAR(200),
    zipcode VARCHAR(20),
    buildingName VARCHAR(100)
);

CREATE TABLE wing (
    wingID INT PRIMARY KEY,
    buildingID INT,
    wingName VARCHAR(50),
    smokingFacility BOOLEAN,
    smokingWing BOOLEAN,
    FOREIGN KEY (buildingID) REFERENCES building(buildingID)
);

CREATE TABLE floor (
    floorID INT PRIMARY KEY,
    wingID INT,
    floorNumber INT,
    smokingFacility BOOLEAN,
    smokingFloor BOOLEAN,
    FOREIGN KEY (wingID) REFERENCES wing(wingID)
);

#Room types and facilities 
CREATE TABLE room_type (
    roomTypeID INT PRIMARY KEY,
    sizeLabel VARCHAR(50)
);

CREATE TABLE room_feature_type (
    featureTypeID INT PRIMARY KEY,
    featureName VARCHAR(100)
);

CREATE TABLE room_feature_relation (
    roomTypeID INT,
    featureTypeID INT,
    PRIMARY KEY (roomTypeID, featureTypeID),
    FOREIGN KEY (roomTypeID) REFERENCES room_type(roomTypeID),
    FOREIGN KEY (featureTypeID) REFERENCES room_feature_type(featureTypeID)
);

CREATE TABLE facility (
    facilityID INT PRIMARY KEY,
    roomTypeID INT,
    buildingID INT,
    position VARCHAR(100),
    FOREIGN KEY (roomTypeID) REFERENCES room_type(roomTypeID),
    FOREIGN KEY (buildingID) REFERENCES building(buildingID)
);



#### room status 

CREATE TABLE room_status (
    statusID INT PRIMARY KEY,
    statusName VARCHAR(50)
);

CREATE TABLE room (
    roomID INT PRIMARY KEY,
    floorID INT,
    roomNumber VARCHAR(20),
    roomTypeID INT,
    capacity INT,
    smokingFacility BOOLEAN,
    smokingRoom BOOLEAN,
    FOREIGN KEY (floorID) REFERENCES floor(floorID),
    FOREIGN KEY (roomTypeID) REFERENCES room_type(roomTypeID)
);

CREATE TABLE room_availability (
    availabilityID INT PRIMARY KEY,
    roomID INT,
    date DATE,
    statusID INT,
    FOREIGN KEY (roomID) REFERENCES room(roomID),
    FOREIGN KEY (statusID) REFERENCES room_status(statusID)
);

CREATE TABLE room_assignment (
    reservationID INT,
    roomID INT,
    PRIMARY KEY (reservationID, roomID)
);

#### customers

CREATE TABLE customer_type (
    customerTypeID INT PRIMARY KEY,
    description VARCHAR(200)
);

CREATE TABLE customer (
    customerID INT PRIMARY KEY,
    customerTypeID INT,
    name VARCHAR(150),
    phone VARCHAR(50),
    email VARCHAR(150),
    gender VARCHAR(20),
    FOREIGN KEY (customerTypeID) REFERENCES customer_type(customerTypeID)
);



CREATE TABLE customer_call (
    callID INT PRIMARY KEY,
    customerID INT,
    message TEXT,
    callTime DATETIME,
    FOREIGN KEY (customerID) REFERENCES customer(customerID)
);

CREATE TABLE customer_call_outcome (
    customerID INT,
    callID INT,
    outcomeType VARCHAR(50),
    fee DECIMAL(10,2),
    PRIMARY KEY (customerID, callID),
    FOREIGN KEY (customerID) REFERENCES customer(customerID),
    FOREIGN KEY (callID) REFERENCES customer_call(callID)
);



#### reservations 

CREATE TABLE event (
    eventID INT PRIMARY KEY,
    roomNeeded BOOLEAN,
    estimatedAttendance INT,
    estimatedEndDate DATE
);

CREATE TABLE reservation (
    reservationID INT PRIMARY KEY,
    customerID INT,
    eventID INT,
    startDate DATE,
    endDate DATE,
    checkOutDate DATE,
    channel VARCHAR(50),
    status VARCHAR(50),
    FOREIGN KEY (customerID) REFERENCES customer(customerID),
    FOREIGN KEY (eventID) REFERENCES event(eventID)
);

CREATE TABLE meeting_room_reservation (
    meetingRoomReservationID INT PRIMARY KEY,
    reservationsReserved INT,
    startDate DATE,
    endDate DATE,
    description VARCHAR(500),
    FOREIGN KEY (reservationsReserved) REFERENCES reservation(reservationID)
);

CREATE TABLE rec_room_reservation (
    recRoomReservationID INT PRIMARY KEY,
    recRoomType INT,
    reservationsReserved INT,
    FOREIGN KEY (reservationsReserved) REFERENCES reservation(reservationID)
);


#### billing, payment 

CREATE TABLE payment (
    paymentID INT PRIMARY KEY,
    customerID INT,
    reservationID INT,
    amount DECIMAL(10,2),
    date DATE,
    method VARCHAR(50),
    FOREIGN KEY (customerID) REFERENCES customer(customerID),
    FOREIGN KEY (reservationID) REFERENCES reservation(reservationID)
);

CREATE TABLE customer_payment_relation (
    customerID INT,
    paymentID INT,
    PRIMARY KEY (customerID, paymentID),
    FOREIGN KEY (customerID) REFERENCES customer(customerID),
    FOREIGN KEY (paymentID) REFERENCES payment(paymentID)
);

CREATE TABLE billing (
    billingID INT PRIMARY KEY,
    reservationID INT,
    roomID INT,
    totalAmount DECIMAL(10,2),
    FOREIGN KEY (reservationID) REFERENCES reservation(reservationID),
    FOREIGN KEY (roomID) REFERENCES room(roomID)
);

CREATE TABLE charges (
    transactionID INT PRIMARY KEY,
    chargeType VARCHAR(50),
    amount DECIMAL(10,2),
    reservationID INT,
    FOREIGN KEY (reservationID) REFERENCES reservation(reservationID)
);

#### service and damage pricing 
CREATE TABLE room_usage_time_price (
    priceID INT PRIMARY KEY,
    roomTypeID INT,
    usageType VARCHAR(50),
    price DECIMAL(10,2),
    FOREIGN KEY (roomTypeID) REFERENCES room_type(roomTypeID)
);



#### staff, roles, staff logs 

CREATE TABLE staff_role (
    roleID INT PRIMARY KEY,
    roleType VARCHAR(50),
    description VARCHAR(200)
);

CREATE TABLE staff (
    staffID INT PRIMARY KEY,
    name VARCHAR(150),
    gender VARCHAR(20),
    hireDate DATE,
    department VARCHAR(100),
    phone VARCHAR(50)
);

CREATE TABLE staff_assignment (
    staffID INT,
    roleID INT,
    reservationID INT,
    description VARCHAR(200),
    PRIMARY KEY (staffID, roleID),
    FOREIGN KEY (staffID) REFERENCES staff(staffID),
    FOREIGN KEY (roleID) REFERENCES staff_role(roleID),
    FOREIGN KEY (reservationID) REFERENCES reservation(reservationID)
);

CREATE TABLE staff_log (
    logID INT PRIMARY KEY,
    staffID INT,
    reservationID INT,
    action VARCHAR(100),
    time DATETIME,
    FOREIGN KEY (staffID) REFERENCES staff(staffID),
    FOREIGN KEY (reservationID) REFERENCES reservation(reservationID)
);

INSERT INTO room_kind (roomKindName) VALUES
('Standard Sleeping Room'),
('Suite'),
('Meeting Room'),
('Ballroom'),
('Outdoor Courtyard'),
('Pool Patio');

INSERT INTO room_function (roomFunctionName) VALUES
('Sleeping'),
('Meeting'),
('Eating'),
('Event Hosting'),
('Recreation');

INSERT INTO bed_kind (bedKindName) VALUES
('Regular Double'),
('Extra Long Double'),
('Queen'),
('King'),
('Rollaway'),
('Fold-up Wall Bed');

INSERT INTO building (buildingID, completed, country, state, city, street, zipcode, buildingName) VALUES
(1, TRUE, 'USA', 'California', 'Los Angeles', '123 Sunset Blvd', '90028', 'Sunset Tower'),
(2, TRUE, 'France', 'Provence-Alpes-Côte d''Azur', 'Nice', '45 Promenade des Anglais', '06000', 'Mediterranean Palace'),
(3, TRUE, 'Japan', 'Tokyo', 'Tokyo', '1-2-3 Shibuya', '150-0002', 'Sakura Gardens'),
(4, FALSE, 'UAE', 'Dubai', 'Dubai', 'Sheikh Zayed Rd', '00000', 'Desert Oasis (Under Construction)'),
(5, TRUE, 'UK', 'England', 'London', '12 Park Lane', 'W1K 7AA', 'London Grand'),
(6, TRUE, 'Australia', 'NSW', 'Sydney', '100 George Street', '2000', 'Sydney Harbour View');

INSERT INTO wing (wingID, buildingID, wingName, smokingFacility, smokingWing) VALUES
(1, 1, 'A', TRUE, FALSE),
(2, 1, 'B', TRUE, TRUE),
(3, 2, 'North', TRUE, FALSE),
(4, 2, 'South', FALSE, FALSE),
(5, 3, 'East', TRUE, TRUE),
(6, 3, 'West', FALSE, FALSE),
(7, 4, 'Main', TRUE, FALSE),
(8, 5, 'Royal', TRUE, TRUE),
(9, 6, 'Harbour', FALSE, FALSE);

INSERT INTO floor (floorID, wingID, floorNumber, smokingFacility, smokingFloor) VALUES
(1, 1, 1, TRUE, FALSE),
(2, 1, 2, TRUE, TRUE),
(3, 2, 1, TRUE, FALSE),
(4, 2, 2, TRUE, FALSE),
(5, 3, 1, TRUE, FALSE),
(6, 3, 2, FALSE, FALSE),
(7, 4, 1, FALSE, FALSE),
(8, 5, 1, TRUE, TRUE),
(9, 5, 2, TRUE, FALSE),
(10, 6, 1, FALSE, FALSE);

INSERT INTO room_type (roomTypeID, sizeLabel) VALUES
(1, 'Single Occupancy'),
(2, 'Double Occupancy'),
(3, 'Family Suite'),
(4, 'Executive Suite'),
(5, 'Small Meeting Room'),
(6, 'Large Ballroom'),
(7, 'Conference Room'),
(8, 'Presidential Suite'),
(9, 'Standard Suite'),
(10, 'Deluxe Room');

INSERT INTO room_feature_type (featureTypeID, featureName) VALUES
(1, 'Toilet and Bath'),
(2, 'Telephone'),
(3, 'Television'),
(4, 'Closet'),
(5, 'Drawers'),
(6, 'Movable Walls'),
(7, 'Private Access Door'),
(8, 'Fold-up Bed'),
(9, 'Mini Bar'),
(10, 'Coffee Machine'),
(11, 'Safe'),
(12, 'Balcony');

INSERT INTO room_feature_relation (roomTypeID, featureTypeID) VALUES
(1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
(2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 9),
(3, 1), (3, 2), (3, 3), (3, 4), (3, 5), (3, 7), (3, 9), (3, 10),
(4, 1), (4, 2), (4, 3), (4, 4), (4, 5), (4, 7), (4, 9), (4, 10), (4, 11), (4, 12),
(5, 1), (5, 2), (5, 6),
(6, 2), (6, 6),
(8, 1), (8, 2), (8, 3), (8, 4), (8, 5), (8, 7), (8, 9), (8, 10), (8, 11), (8, 12);

INSERT INTO facility (facilityID, roomTypeID, buildingID, position) VALUES
(1, 1, 1, 'First floor, near elevator'),
(2, 2, 1, 'Second floor, corner room'),
(3, 3, 1, 'Third floor, sea view'),
(4, 4, 2, 'Top floor, panoramic view'),
(5, 5, 2, 'Ground floor, near lobby'),
(6, 6, 3, 'Main hall, ground floor'),
(7, 7, 3, 'Conference wing'),
(8, 8, 4, 'Penthouse'),
(9, 9, 5, 'Executive floor'),
(10, 10, 6, 'Harbour view rooms');

INSERT INTO room_status (statusID, statusName) VALUES
(1, 'Available'),
(2, 'Occupied'),
(3, 'Under Maintenance'),
(4, 'Being Cleaned'),
(5, 'Reserved'),
(6, 'Out of Service'),
(7, 'Ready for Check-in');

INSERT INTO room (roomID, floorID, roomNumber, roomTypeID, capacity, smokingFacility, smokingRoom) VALUES
(1, 1, '101', 1, 2, TRUE, FALSE),
(2, 1, '102', 2, 4, TRUE, TRUE),
(3, 2, '201', 3, 6, TRUE, FALSE),
(4, 2, '202', 4, 2, TRUE, FALSE),
(5, 3, '103', 1, 2, TRUE, TRUE),
(6, 3, '104', 2, 4, TRUE, FALSE),
(7, 4, '301', 5, 20, TRUE, FALSE),
(8, 5, '401', 6, 10000, FALSE, FALSE),
(9, 6, '501', 7, 50, FALSE, FALSE),
(10, 7, '601', 8, 4, TRUE, FALSE),
(11, 8, '701', 9, 4, TRUE, TRUE),
(12, 9, '801', 10, 2, TRUE, FALSE),
(13, 10, '901', 1, 2, FALSE, FALSE),
(14, 1, '105', 2, 4, TRUE, TRUE),
(15, 2, '203', 3, 6, TRUE, FALSE);

INSERT INTO room_availability (availabilityID, roomID, date, statusID) VALUES
(1, 1, '2024-11-01', 1),
(2, 2, '2024-11-01', 2),
(3, 3, '2024-11-01', 3),
(4, 4, '2024-11-01', 4),
(5, 5, '2024-11-01', 5),
(6, 1, '2024-11-02', 1),
(7, 2, '2024-11-02', 2),
(8, 3, '2024-11-02', 7),
(9, 4, '2024-11-02', 1),
(10, 5, '2024-11-02', 5);

INSERT INTO room_assignment (reservationID, roomID) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10);

INSERT INTO customer_type (customerTypeID, description) VALUES
(1, 'Individual Guest'),
(2, 'Corporate Client'),
(3, 'Event Host'),
(4, 'Travel Agency'),
(5, 'Government Entity');

INSERT INTO customer (customerID, customerTypeID, name, phone, email, gender) VALUES
(1, 1, 'John Smith', '+1-555-0101', 'john.smith@email.com', 'Male'),
(2, 2, 'TechCorp Inc.', '+1-555-0102', 'contact@techcorp.com', NULL),
(3, 3, 'Alice Johnson', '+1-555-0103', 'alice.j@email.com', 'Female'),
(4, 4, 'World Travel Agency', '+1-555-0104', 'bookings@worldtravel.com', NULL),
(5, 5, 'City of Los Angeles', '+1-555-0105', 'events@la.gov', NULL),
(6, 1, 'Robert Brown', '+1-555-0106', 'robert.b@email.com', 'Male'),
(7, 1, 'Maria Garcia', '+1-555-0107', 'maria.g@email.com', 'Female'),
(8, 2, 'Global Foods LLC', '+1-555-0108', 'info@globalfoods.com', NULL),
(9, 3, 'David Wilson', '+1-555-0109', 'david.w@email.com', 'Male'),
(10, 1, 'Sarah Miller', '+1-555-0110', 'sarah.m@email.com', 'Female'),
(11, 1, 'Michael Davis', '+1-555-0111', 'michael.d@email.com', 'Male'),
(12, 2, 'Innovate Solutions', '+1-555-0112', 'info@innovatesolutions.com', NULL),
(13, 1, 'Jennifer Taylor', '+1-555-0113', 'jennifer.t@email.com', 'Female'),
(14, 3, 'Thomas Anderson', '+1-555-0114', 'thomas.a@email.com', 'Male'),
(15, 1, 'Emily Clark', '+1-555-0115', 'emily.c@email.com', 'Female'),
(16, 4, 'Global Voyages', '+1-555-0116', 'reservations@globalvoyages.com', NULL),
(17, 1, 'Christopher Lee', '+1-555-0117', 'chris.lee@email.com', 'Male'),
(18, 2, 'MediTech Corp', '+1-555-0118', 'contact@meditech.com', NULL),
(19, 1, 'Amanda White', '+1-555-0119', 'amanda.w@email.com', 'Female'),
(20, 1, 'Daniel Martinez', '+1-555-0120', 'daniel.m@email.com', 'Male'),
(21, 3, 'Sophia Robinson', '+1-555-0121', 'sophia.r@email.com', 'Female'),
(22, 1, 'Kevin Harris', '+1-555-0122', 'kevin.h@email.com', 'Male'),
(23, 2, 'Future Tech Ltd', '+1-555-0123', 'info@futuretech.com', NULL),
(24, 1, 'Olivia Walker', '+1-555-0124', 'olivia.w@email.com', 'Female'),
(25, 5, 'State Department', '+1-555-0125', 'travel@statedept.gov', NULL),
(26, 1, 'Matthew King', '+1-555-0126', 'matthew.k@email.com', 'Male'),
(27, 1, 'Jessica Scott', '+1-555-0127', 'jessica.s@email.com', 'Female'),
(28, 3, 'Benjamin Young', '+1-555-0128', 'benjamin.y@email.com', 'Male'),
(29, 2, 'Green Energy Inc', '+1-555-0129', 'contact@greenenergy.com', NULL),
(30, 1, 'Elizabeth Hall', '+1-555-0130', 'elizabeth.h@email.com', 'Female'),
(31, 1, 'Andrew Allen', '+1-555-0131', 'andrew.a@email.com', 'Male'),
(32, 4, 'Luxury Travel Co', '+1-555-0132', 'info@luxurytravel.com', NULL),
(33, 1, 'Megan Wright', '+1-555-0133', 'megan.w@email.com', 'Female'),
(34, 2, 'Creative Designs', '+1-555-0134', 'contact@creativedesigns.com', NULL),
(35, 1, 'Ryan Lopez', '+1-555-0135', 'ryan.l@email.com', 'Male'),
(36, 3, 'Grace Hill', '+1-555-0136', 'grace.h@email.com', 'Female'),
(37, 1, 'Joshua Green', '+1-555-0137', 'joshua.g@email.com', 'Male'),
(38, 1, 'Brittany Adams', '+1-555-0138', 'brittany.a@email.com', 'Female'),
(39, 2, 'Precision Tools', '+1-555-0139', 'sales@precisiontools.com', NULL),
(40, 1, 'Alexander Nelson', '+1-555-0140', 'alexander.n@email.com', 'Male'),
(41, 5, 'County Council', '+1-555-0141', 'admin@countycouncil.gov', NULL),
(42, 1, 'Victoria Carter', '+1-555-0142', 'victoria.c@email.com', 'Female'),
(43, 3, 'Samuel Mitchell', '+1-555-0143', 'samuel.m@email.com', 'Male'),
(44, 1, 'Lauren Perez', '+1-555-0144', 'lauren.p@email.com', 'Female'),
(45, 2, 'Quality Foods', '+1-555-0145', 'info@qualityfoods.com', NULL),
(46, 1, 'Nathan Roberts', '+1-555-0146', 'nathan.r@email.com', 'Male'),
(47, 1, 'Hannah Turner', '+1-555-0147', 'hannah.t@email.com', 'Female'),
(48, 4, 'Adventure Tours', '+1-555-0148', 'book@adventuretours.com', NULL),
(49, 3, 'Isaac Phillips', '+1-555-0149', 'isaac.p@email.com', 'Male'),
(50, 1, 'Rachel Campbell', '+1-555-0150', 'rachel.c@email.com', 'Female'),
(51, 2, 'Smart Solutions', '+1-555-0151', 'contact@smartsolutions.com', NULL),
(52, 1, 'Patrick Parker', '+1-555-0152', 'patrick.p@email.com', 'Male'),
(53, 1, 'Samantha Evans', '+1-555-0153', 'samantha.e@email.com', 'Female'),
(54, 3, 'Jonathan Edwards', '+1-555-0154', 'jonathan.e@email.com', 'Male'),
(55, 2, 'Tech Innovators', '+1-555-0155', 'info@techinnovators.com', NULL),
(56, 1, 'Stephanie Collins', '+1-555-0156', 'stephanie.c@email.com', 'Female'),
(57, 5, 'City University', '+1-555-0157', 'conferences@cityuniversity.edu', NULL),
(58, 1, 'Brandon Stewart', '+1-555-0158', 'brandon.s@email.com', 'Male'),
(59, 1, 'Nicole Sanchez', '+1-555-0159', 'nicole.s@email.com', 'Female'),
(60, 3, 'Justin Morris', '+1-555-0160', 'justin.m@email.com', 'Male'),
(61, 2, 'Global Logistics', '+1-555-0161', 'contact@globallogistics.com', NULL),
(62, 1, 'Kayla Rogers', '+1-555-0162', 'kayla.r@email.com', 'Female'),
(63, 1, 'Tyler Reed', '+1-555-0163', 'tyler.r@email.com', 'Male'),
(64, 4, 'Business Travel Pro', '+1-555-0164', 'service@businesstravelpro.com', NULL),
(65, 3, 'Madison Cook', '+1-555-0165', 'madison.c@email.com', 'Female'),
(66, 1, 'Caleb Morgan', '+1-555-0166', 'caleb.m@email.com', 'Male'),
(67, 2, 'Health Plus Inc', '+1-555-0167', 'info@healthplus.com', NULL),
(68, 1, 'Alexis Bell', '+1-555-0168', 'alexis.b@email.com', 'Female'),
(69, 1, 'Gabriel Murphy', '+1-555-0169', 'gabriel.m@email.com', 'Male'),
(70, 3, 'Zoe Bailey', '+1-555-0170', 'zoe.b@email.com', 'Female'),
(71, 2, 'Eco Solutions', '+1-555-0171', 'contact@ecosolutions.com', NULL),
(72, 1, 'Dylan Rivera', '+1-555-0172', 'dylan.r@email.com', 'Male'),
(73, 1, 'Chloe Cooper', '+1-555-0173', 'chloe.c@email.com', 'Female'),
(74, 5, 'Hospital District', '+1-555-0174', 'events@hospitaldistrict.org', NULL),
(75, 1, 'James Taylor', '+1-555-0175', 'james.t@email.com', 'Male');

INSERT INTO customer_call (callID, customerID, message, callTime) VALUES
(1, 1, 'Requested late check-out', '2024-11-01 10:30:00'),
(2, 2, 'Inquiry about conference facilities', '2024-11-02 14:15:00'),
(3, 3, 'Changed reservation dates', '2024-11-03 09:45:00'),
(4, 4, 'Group booking inquiry', '2024-11-04 16:20:00'),
(5, 5, 'Government event coordination', '2024-11-05 11:10:00'),
(6, 6, 'Room upgrade request', '2024-11-06 13:25:00'),
(7, 7, 'Special dietary requirements', '2024-11-07 10:05:00'),
(8, 8, 'Corporate account setup', '2024-11-08 15:30:00'),
(9, 9, 'Event planning consultation', '2024-11-09 12:15:00'),
(10, 10, 'Honeymoon package inquiry', '2024-11-10 09:20:00');

INSERT INTO customer_call_outcome (customerID, callID, outcomeType, fee) VALUES
(1, 1, 'Late Check-out Approved', 50.00),
(2, 2, 'Facility Tour Scheduled', 0.00),
(3, 3, 'Reservation Modified', 0.00),
(4, 4, 'Group Quote Provided', 0.00),
(5, 5, 'Event Contract Sent', 0.00),
(6, 6, 'Upgrade Confirmed', 75.00),
(7, 7, 'Dietary Needs Noted', 0.00),
(8, 8, 'Account Created', 0.00),
(9, 9, 'Planning Session Scheduled', 0.00),
(10, 10, 'Package Details Sent', 0.00);

INSERT INTO event (eventID, roomNeeded, estimatedAttendance, estimatedEndDate) VALUES
(1, TRUE, 50, '2024-12-01'),
(2, FALSE, 200, '2024-12-02'),
(3, TRUE, 20, '2024-12-03'),
(4, TRUE, 1000, '2024-12-04'),
(5, FALSE, 30, '2024-12-05'),
(6, TRUE, 150, '2024-12-06'),
(7, FALSE, 75, '2024-12-07'),
(8, TRUE, 300, '2024-12-08'),
(9, TRUE, 60, '2024-12-09'),
(10, FALSE, 120, '2024-12-10'),
(11, TRUE, 80, '2024-12-11'),
(12, FALSE, 250, '2024-12-12'),
(13, TRUE, 40, '2024-12-13'),
(14, TRUE, 500, '2024-12-14'),
(15, FALSE, 100, '2024-12-15');

INSERT INTO reservation (reservationID, customerID, eventID, startDate, endDate, checkOutDate, channel, status) VALUES
(1, 1, 1, '2024-11-01', '2024-11-05', '2024-11-05 12:00:00', 'Online', 'Checked Out'),
(2, 2, NULL, '2024-11-02', '2024-11-07', NULL, 'Phone', 'Confirmed'),
(3, 3, 2, '2024-11-03', '2024-11-06', NULL, 'Online', 'Pending'),
(4, 4, NULL, '2024-11-04', '2024-11-08', NULL, 'Travel Agent', 'Confirmed'),
(5, 5, 3, '2024-11-05', '2024-11-10', NULL, 'Email', 'Confirmed'),
(6, 6, NULL, '2024-11-06', '2024-11-09', NULL, 'Online', 'Pending'),
(7, 7, NULL, '2024-11-07', '2024-11-12', NULL, 'Phone', 'Checked In'),
(8, 8, 4, '2024-11-08', '2024-11-15', NULL, 'Online', 'Confirmed'),
(9, 9, NULL, '2024-11-09', '2024-11-11', NULL, 'Online', 'Pending'),
(10, 10, NULL, '2024-11-10', '2024-11-14', NULL, 'Phone', 'Confirmed'),
(11, 11, 5, '2024-11-11', '2024-11-16', NULL, 'Online', 'Confirmed'),
(12, 12, NULL, '2024-11-12', '2024-11-15', NULL, 'Phone', 'Pending'),
(13, 13, 6, '2024-11-13', '2024-11-18', NULL, 'Email', 'Confirmed'),
(14, 14, NULL, '2024-11-14', '2024-11-17', NULL, 'Online', 'Confirmed'),
(15, 15, NULL, '2024-11-15', '2024-11-20', NULL, 'Travel Agent', 'Checked In'),
(16, 16, 7, '2024-11-16', '2024-11-21', NULL, 'Online', 'Confirmed'),
(17, 17, NULL, '2024-11-17', '2024-11-19', NULL, 'Phone', 'Pending'),
(18, 18, 8, '2024-11-18', '2024-11-23', NULL, 'Online', 'Confirmed'),
(19, 19, NULL, '2024-11-19', '2024-11-22', NULL, 'Email', 'Confirmed'),
(20, 20, NULL, '2024-11-20', '2024-11-25', NULL, 'Online', 'Checked Out'),
(21, 21, 9, '2024-11-21', '2024-11-26', NULL, 'Phone', 'Confirmed'),
(22, 22, NULL, '2024-11-22', '2024-11-24', NULL, 'Online', 'Pending'),
(23, 23, 10, '2024-11-23', '2024-11-28', NULL, 'Travel Agent', 'Confirmed'),
(24, 24, NULL, '2024-11-24', '2024-11-27', NULL, 'Online', 'Confirmed'),
(25, 25, NULL, '2024-11-25', '2024-11-30', NULL, 'Email', 'Checked In'),
(26, 26, 11, '2024-11-26', '2024-12-01', NULL, 'Online', 'Confirmed'),
(27, 27, NULL, '2024-11-27', '2024-11-29', NULL, 'Phone', 'Pending'),
(28, 28, 12, '2024-11-28', '2024-12-03', NULL, 'Online', 'Confirmed'),
(29, 29, NULL, '2024-11-29', '2024-12-02', NULL, 'Email', 'Confirmed'),
(30, 30, NULL, '2024-11-30', '2024-12-05', NULL, 'Travel Agent', 'Checked In'),
(31, 31, 13, '2024-12-01', '2024-12-06', NULL, 'Online', 'Confirmed'),
(32, 32, NULL, '2024-12-02', '2024-12-04', NULL, 'Phone', 'Pending'),
(33, 33, 14, '2024-12-03', '2024-12-08', NULL, 'Online', 'Confirmed'),
(34, 34, NULL, '2024-12-04', '2024-12-07', NULL, 'Email', 'Confirmed'),
(35, 35, NULL, '2024-12-05', '2024-12-10', NULL, 'Online', 'Checked Out'),
(36, 36, 15, '2024-12-06', '2024-12-11', NULL, 'Phone', 'Confirmed'),
(37, 37, NULL, '2024-12-07', '2024-12-09', NULL, 'Online', 'Pending'),
(38, 38, 1, '2024-12-08', '2024-12-13', NULL, 'Travel Agent', 'Confirmed'),
(39, 39, NULL, '2024-12-09', '2024-12-12', NULL, 'Online', 'Confirmed'),
(40, 40, NULL, '2024-12-10', '2024-12-15', NULL, 'Email', 'Checked In'),
(41, 41, 2, '2024-12-11', '2024-12-16', NULL, 'Online', 'Confirmed'),
(42, 42, NULL, '2024-12-12', '2024-12-14', NULL, 'Phone', 'Pending'),
(43, 43, 3, '2024-12-13', '2024-12-18', NULL, 'Online', 'Confirmed'),
(44, 44, NULL, '2024-12-14', '2024-12-17', NULL, 'Email', 'Confirmed'),
(45, 45, NULL, '2024-12-15', '2024-12-20', NULL, 'Travel Agent', 'Checked In'),
(46, 46, 4, '2024-12-16', '2024-12-21', NULL, 'Online', 'Confirmed'),
(47, 47, NULL, '2024-12-17', '2024-12-19', NULL, 'Phone', 'Pending'),
(48, 48, 5, '2024-12-18', '2024-12-23', NULL, 'Online', 'Confirmed'),
(49, 49, NULL, '2024-12-19', '2024-12-22', NULL, 'Email', 'Confirmed'),
(50, 50, NULL, '2024-12-20', '2024-12-25', NULL, 'Online', 'Checked Out'),
(51, 51, 6, '2024-12-21', '2024-12-26', NULL, 'Phone', 'Confirmed'),
(52, 52, NULL, '2024-12-22', '2024-12-24', NULL, 'Online', 'Pending'),
(53, 53, 7, '2024-12-23', '2024-12-28', NULL, 'Travel Agent', 'Confirmed'),
(54, 54, NULL, '2024-12-24', '2024-12-27', NULL, 'Online', 'Confirmed'),
(55, 55, NULL, '2024-12-25', '2024-12-30', NULL, 'Email', 'Checked In'),
(56, 56, 8, '2024-12-26', '2024-12-31', NULL, 'Online', 'Confirmed'),
(57, 57, NULL, '2024-12-27', '2024-12-29', NULL, 'Phone', 'Pending'),
(58, 58, 9, '2024-12-28', '2025-01-02', NULL, 'Online', 'Confirmed'),
(59, 59, NULL, '2024-12-29', '2025-01-01', NULL, 'Email', 'Confirmed'),
(60, 60, NULL, '2024-12-30', '2025-01-04', NULL, 'Travel Agent', 'Checked In'),
(61, 61, 10, '2024-12-31', '2025-01-05', NULL, 'Online', 'Confirmed'),
(62, 62, NULL, '2025-01-01', '2025-01-03', NULL, 'Phone', 'Pending'),
(63, 63, 11, '2025-01-02', '2025-01-07', NULL, 'Online', 'Confirmed'),
(64, 64, NULL, '2025-01-03', '2025-01-06', NULL, 'Email', 'Confirmed'),
(65, 65, NULL, '2025-01-04', '2025-01-09', NULL, 'Online', 'Checked Out'),
(66, 66, 12, '2025-01-05', '2025-01-10', NULL, 'Phone', 'Confirmed'),
(67, 67, NULL, '2025-01-06', '2025-01-08', NULL, 'Online', 'Pending'),
(68, 68, 13, '2025-01-07', '2025-01-12', NULL, 'Travel Agent', 'Confirmed'),
(69, 69, NULL, '2025-01-08', '2025-01-11', NULL, 'Online', 'Confirmed'),
(70, 70, NULL, '2025-01-09', '2025-01-14', NULL, 'Email', 'Checked In'),
(71, 71, 14, '2025-01-10', '2025-01-15', NULL, 'Online', 'Confirmed'),
(72, 72, NULL, '2025-01-11', '2025-01-13', NULL, 'Phone', 'Pending'),
(73, 73, 15, '2025-01-12', '2025-01-17', NULL, 'Online', 'Confirmed'),
(74, 74, NULL, '2025-01-13', '2025-01-16', NULL, 'Email', 'Confirmed'),
(75, 75, NULL, '2025-01-14', '2025-01-19', NULL, 'Travel Agent', 'Checked In'),
(76, 1, NULL, '2025-01-15', '2025-01-20', NULL, 'Online', 'Confirmed'),
(77, 2, 1, '2025-01-16', '2025-01-21', NULL, 'Phone', 'Confirmed'),
(78, 3, NULL, '2025-01-17', '2025-01-19', NULL, 'Online', 'Pending'),
(79, 4, 2, '2025-01-18', '2025-01-23', NULL, 'Travel Agent', 'Confirmed'),
(80, 5, NULL, '2025-01-19', '2025-01-22', NULL, 'Email', 'Confirmed'),
(81, 6, NULL, '2025-01-20', '2025-01-25', NULL, 'Online', 'Checked Out'),
(82, 7, 3, '2025-01-21', '2025-01-26', NULL, 'Phone', 'Confirmed'),
(83, 8, NULL, '2025-01-22', '2025-01-24', NULL, 'Online', 'Pending'),
(84, 9, 4, '2025-01-23', '2025-01-28', NULL, 'Travel Agent', 'Confirmed'),
(85, 10, NULL, '2025-01-24', '2025-01-27', NULL, 'Online', 'Confirmed'),
(86, 11, NULL, '2025-01-25', '2025-01-30', NULL, 'Email', 'Checked In'),
(87, 12, 5, '2025-01-26', '2025-01-31', NULL, 'Online', 'Confirmed'),
(88, 13, NULL, '2025-01-27', '2025-01-29', NULL, 'Phone', 'Pending'),
(89, 14, 6, '2025-01-28', '2025-02-02', NULL, 'Online', 'Confirmed'),
(90, 15, NULL, '2025-01-29', '2025-02-01', NULL, 'Email', 'Confirmed'),
(91, 16, NULL, '2025-01-30', '2025-02-04', NULL, 'Travel Agent', 'Checked In'),
(92, 17, 7, '2025-01-31', '2025-02-05', NULL, 'Online', 'Confirmed'),
(93, 18, NULL, '2025-02-01', '2025-02-03', NULL, 'Phone', 'Pending'),
(94, 19, 8, '2025-02-02', '2025-02-07', NULL, 'Online', 'Confirmed'),
(95, 20, NULL, '2025-02-03', '2025-02-06', NULL, 'Email', 'Confirmed'),
(96, 21, NULL, '2025-02-04', '2025-02-09', NULL, 'Online', 'Checked Out'),
(97, 22, 9, '2025-02-05', '2025-02-10', NULL, 'Phone', 'Confirmed'),
(98, 23, NULL, '2025-02-06', '2025-02-08', NULL, 'Online', 'Pending'),
(99, 24, 10, '2025-02-07', '2025-02-12', NULL, 'Travel Agent', 'Confirmed'),
(100, 25, NULL, '2025-02-08', '2025-02-11', NULL, 'Online', 'Confirmed'),
(101, 26, NULL, '2025-02-09', '2025-02-14', NULL, 'Email', 'Checked In'),
(102, 27, 11, '2025-02-10', '2025-02-15', NULL, 'Online', 'Confirmed'),
(103, 28, NULL, '2025-02-11', '2025-02-13', NULL, 'Phone', 'Pending'),
(104, 29, 12, '2025-02-12', '2025-02-17', NULL, 'Online', 'Confirmed'),
(105, 30, NULL, '2025-02-13', '2025-02-16', NULL, 'Email', 'Confirmed'),
(106, 31, NULL, '2025-02-14', '2025-02-19', NULL, 'Travel Agent', 'Checked In'),
(107, 32, 13, '2025-02-15', '2025-02-20', NULL, 'Online', 'Confirmed'),
(108, 33, NULL, '2025-02-16', '2025-02-18', NULL, 'Phone', 'Pending'),
(109, 34, 14, '2025-02-17', '2025-02-22', NULL, 'Online', 'Confirmed'),
(110, 35, NULL, '2025-02-18', '2025-02-21', NULL, 'Email', 'Confirmed'),
(111, 36, NULL, '2025-02-19', '2025-02-24', NULL, 'Online', 'Checked Out'),
(112, 37, 15, '2025-02-20', '2025-02-25', NULL, 'Phone', 'Confirmed'),
(113, 38, NULL, '2025-02-21', '2025-02-23', NULL, 'Online', 'Pending'),
(114, 39, 1, '2025-02-22', '2025-02-27', NULL, 'Travel Agent', 'Confirmed'),
(115, 40, NULL, '2025-02-23', '2025-02-26', NULL, 'Online', 'Confirmed'),
(116, 41, NULL, '2025-02-24', '2025-02-29', NULL, 'Email', 'Checked In'),
(117, 42, 2, '2025-02-25', '2025-03-02', NULL, 'Online', 'Confirmed'),
(118, 43, NULL, '2025-02-26', '2025-02-28', NULL, 'Phone', 'Pending'),
(119, 44, 3, '2025-02-27', '2025-03-04', NULL, 'Online', 'Confirmed'),
(120, 45, NULL, '2025-02-28', '2025-03-03', NULL, 'Email', 'Confirmed'),
(121, 46, NULL, '2025-03-01', '2025-03-06', NULL, 'Travel Agent', 'Checked In'),
(122, 47, 4, '2025-03-02', '2025-03-07', NULL, 'Online', 'Confirmed'),
(123, 48, NULL, '2025-03-03', '2025-03-05', NULL, 'Phone', 'Pending'),
(124, 49, 5, '2025-03-04', '2025-03-09', NULL, 'Online', 'Confirmed'),
(125, 50, NULL, '2025-03-05', '2025-03-08', NULL, 'Email', 'Confirmed'),
(126, 51, NULL, '2025-03-06', '2025-03-11', NULL, 'Online', 'Checked Out'),
(127, 52, 6, '2025-03-07', '2025-03-12', NULL, 'Phone', 'Confirmed'),
(128, 53, NULL, '2025-03-08', '2025-03-10', NULL, 'Online', 'Pending'),
(129, 54, 7, '2025-03-09', '2025-03-14', NULL, 'Travel Agent', 'Confirmed'),
(130, 55, NULL, '2025-03-10', '2025-03-13', NULL, 'Online', 'Confirmed'),
(131, 56, NULL, '2025-03-11', '2025-03-16', NULL, 'Email', 'Checked In'),
(132, 57, 8, '2025-03-12', '2025-03-17', NULL, 'Online', 'Confirmed'),
(133, 58, NULL, '2025-03-13', '2025-03-15', NULL, 'Phone', 'Pending'),
(134, 59, 9, '2025-03-14', '2025-03-19', NULL, 'Online', 'Confirmed'),
(135, 60, NULL, '2025-03-15', '2025-03-18', NULL, 'Email', 'Confirmed'),
(136, 61, NULL, '2025-03-16', '2025-03-21', NULL, 'Travel Agent', 'Checked In'),
(137, 62, 10, '2025-03-17', '2025-03-22', NULL, 'Online', 'Confirmed'),
(138, 63, NULL, '2025-03-18', '2025-03-20', NULL, 'Phone', 'Pending'),
(139, 64, 11, '2025-03-19', '2025-03-24', NULL, 'Online', 'Confirmed'),
(140, 65, NULL, '2025-03-20', '2025-03-23', NULL, 'Email', 'Confirmed'),
(141, 66, NULL, '2025-03-21', '2025-03-26', NULL, 'Online', 'Checked Out'),
(142, 67, 12, '2025-03-22', '2025-03-27', NULL, 'Phone', 'Confirmed'),
(143, 68, NULL, '2025-03-23', '2025-03-25', NULL, 'Online', 'Pending'),
(144, 69, 13, '2025-03-24', '2025-03-29', NULL, 'Travel Agent', 'Confirmed'),
(145, 70, NULL, '2025-03-25', '2025-03-28', NULL, 'Online', 'Confirmed'),
(146, 71, NULL, '2025-03-26', '2025-03-31', NULL, 'Email', 'Checked In'),
(147, 72, 14, '2025-03-27', '2025-04-01', NULL, 'Online', 'Confirmed'),
(148, 73, NULL, '2025-03-28', '2025-03-30', NULL, 'Phone', 'Pending'),
(149, 74, 15, '2025-03-29', '2025-04-03', NULL, 'Online', 'Confirmed'),
(150, 75, NULL, '2025-03-30', '2025-04-02', NULL, 'Email', 'Confirmed');

INSERT INTO meeting_room_reservation (meetingRoomReservationID, reservationsReserved, startDate, endDate, description) VALUES
(1, 1, '2024-11-01 09:00:00', '2024-11-01 17:00:00', 'Corporate Strategy Meeting'),
(2, 3, '2024-11-03 10:00:00', '2024-11-03 15:00:00', 'Product Launch'),
(3, 8, '2024-11-08 08:00:00', '2024-11-10 20:00:00', 'Annual Conference'),
(4, 13, '2024-11-13 09:00:00', '2024-11-13 16:00:00', 'Team Building Workshop'),
(5, 18, '2024-11-18 10:00:00', '2024-11-18 18:00:00', 'Investor Meeting'),
(6, 23, '2024-11-23 08:30:00', '2024-11-23 16:30:00', 'Training Session'),
(7, 28, '2024-11-28 09:00:00', '2024-11-28 17:00:00', 'Board Meeting'),
(8, 33, '2024-12-03 10:00:00', '2024-12-03 15:00:00', 'Client Presentation'),
(9, 38, '2024-12-08 08:00:00', '2024-12-10 20:00:00', 'Industry Conference'),
(10, 43, '2024-12-13 09:00:00', '2024-12-13 16:00:00', 'Workshop');

INSERT INTO rec_room_reservation (recRoomReservationID, recRoomType, reservationsReserved) VALUES
(1, 1, 5),
(2, 2, 10),
(3, 3, 15),
(4, 1, 20),
(5, 2, 25),
(6, 3, 30),
(7, 1, 35),
(8, 2, 40),
(9, 3, 45),
(10, 1, 50);

INSERT INTO payment (paymentID, customerID, reservationID, amount, date, method) VALUES
(1, 1, 1, 1200.00, '2024-11-05', 'Credit Card'),
(2, 2, 2, 2500.00, '2024-11-02', 'Bank Transfer'),
(3, 3, 3, 1800.00, '2024-11-03', 'Credit Card'),
(4, 4, 4, 3200.00, '2024-11-04', 'Travel Agency Account'),
(5, 5, 5, 1500.00, '2024-11-05', 'Government PO'),
(6, 6, 6, 900.00, '2024-11-06', 'Credit Card'),
(7, 7, 7, 2100.00, '2024-11-07', 'Cash'),
(8, 8, 8, 4800.00, '2024-11-08', 'Corporate Account'),
(9, 9, 9, 750.00, '2024-11-09', 'Credit Card'),
(10, 10, 10, 1800.00, '2024-11-10', 'Bank Transfer'),
(11, 11, 11, 2200.00, '2024-11-11', 'Credit Card'),
(12, 12, 12, 1600.00, '2024-11-12', 'Corporate Account'),
(13, 13, 13, 1900.00, '2024-11-13', 'Credit Card'),
(14, 14, 14, 1400.00, '2024-11-14', 'Bank Transfer'),
(15, 15, 15, 2700.00, '2024-11-15', 'Credit Card');

INSERT INTO customer_payment_relation (customerID, paymentID) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 6),
(7, 7),
(8, 8),
(9, 9),
(10, 10),
(11, 11),
(12, 12),
(13, 13),
(14, 14),
(15, 15);

INSERT INTO billing (billingID, reservationID, roomID, totalAmount) VALUES
(1, 1, 1, 1200.00),
(2, 2, 2, 2500.00),
(3, 3, 3, 1800.00),
(4, 4, 4, 3200.00),
(5, 5, 5, 1500.00),
(6, 6, 6, 900.00),
(7, 7, 7, 2100.00),
(8, 8, 8, 4800.00),
(9, 9, 9, 750.00),
(10, 10, 10, 1800.00),
(11, 11, 11, 2200.00),
(12, 12, 12, 1600.00),
(13, 13, 13, 1900.00),
(14, 14, 14, 1400.00),
(15, 15, 15, 2700.00);

INSERT INTO charges (transactionID, chargeType, amount, reservationID) VALUES
(1, 'Room Rental', 800.00, 1),
(2, 'Meeting Room', 200.00, 1),
(3, 'Restaurant', 150.00, 1),
(4, 'Phone Calls', 50.00, 1),
(5, 'Room Rental', 1200.00, 2),
(6, 'Room Service', 300.00, 2),
(7, 'Laundry', 100.00, 3),
(8, 'Room Rental', 900.00, 3),
(9, 'Meeting Room', 600.00, 4),
(10, 'Room Rental', 2600.00, 4),
(11, 'Spa Services', 250.00, 5),
(12, 'Room Rental', 1250.00, 5),
(13, 'Mini Bar', 75.00, 6),
(14, 'Room Rental', 825.00, 6),
(15, 'Business Center', 150.00, 7);

INSERT INTO room_usage_time_price (priceID, roomTypeID, usageType, price) VALUES
(1, 1, 'Daily', 200.00),
(2, 2, 'Daily', 300.00),
(3, 3, 'Daily', 450.00),
(4, 4, 'Daily', 650.00),
(5, 5, 'Hourly', 50.00),
(6, 6, 'Event', 5000.00),
(7, 7, 'Half Day', 300.00),
(8, 8, 'Daily', 1000.00),
(9, 9, 'Daily', 400.00),
(10, 10, 'Daily', 250.00);

INSERT INTO staff_role (roleID, roleType, description) VALUES
(1, 'Receptionist', 'Front desk check-in/out'),
(2, 'Housekeeping', 'Room cleaning and maintenance'),
(3, 'Event Coordinator', 'Meeting and event planning'),
(4, 'Manager', 'Oversee operations and staff'),
(5, 'Concierge', 'Guest services and recommendations'),
(6, 'Chef', 'Food preparation and kitchen management'),
(7, 'Waiter', 'Food and beverage service'),
(8, 'Security', 'Safety and security management'),
(9, 'Maintenance', 'Building and equipment repair'),
(10, 'Accountant', 'Financial management and billing');

INSERT INTO staff (staffID, name, gender, hireDate, department, phone) VALUES
(1, 'Michael Chen', 'Male', '2020-03-15', 'Front Desk', '+1-555-0201'),
(2, 'Emily White', 'Female', '2021-06-22', 'Housekeeping', '+1-555-0202'),
(3, 'Daniel Lee', 'Male', '2019-11-30', 'Events', '+1-555-0203'),
(4, 'Jessica Brown', 'Female', '2022-01-10', 'Management', '+1-555-0204'),
(5, 'Carlos Rodriguez', 'Male', '2023-08-05', 'Concierge', '+1-555-0205'),
(6, 'Sophia Martinez', 'Female', '2020-09-12', 'Kitchen', '+1-555-0206'),
(7, 'James Wilson', 'Male', '2021-03-25', 'Restaurant', '+1-555-0207'),
(8, 'Olivia Taylor', 'Female', '2022-07-18', 'Security', '+1-555-0208'),
(9, 'David Clark', 'Male', '2019-05-30', 'Maintenance', '+1-555-0209'),
(10, 'Emma Anderson', 'Female', '2023-01-15', 'Finance', '+1-555-0210'),
(11, 'Robert Garcia', 'Male', '2020-11-08', 'Front Desk', '+1-555-0211'),
(12, 'Isabella Hernandez', 'Female', '2021-08-14', 'Housekeeping', '+1-555-0212'),
(13, 'William Martin', 'Male', '2022-04-30', 'Events', '+1-555-0213'),
(14, 'Mia Thompson', 'Female', '2023-10-22', 'Concierge', '+1-555-0214'),
(15, 'Joseph Moore', 'Male', '2020-12-05', 'Kitchen', '+1-555-0215');

INSERT INTO staff_assignment (staffID, roleID, reservationID, description) VALUES
(1, 1, 1, 'Check-in for reservation 1'),
(2, 2, 1, 'Room cleaning after checkout'),
(3, 3, 3, 'Event coordination for product launch'),
(4, 4, 8, 'Oversee annual conference'),
(5, 5, 10, 'Guest recommendations and services'),
(6, 6, 5, 'Prepare banquet for government event'),
(7, 7, 7, 'Serve meals for checked-in guests'),
(8, 8, 8, 'Security for large conference'),
(9, 9, 3, 'Repair HVAC in meeting room'),
(10, 10, 1, 'Process billing for reservation 1'),
(11, 1, 2, 'Check-in for corporate client'),
(12, 2, 2, 'Prepare room for new guest'),
(13, 3, 13, 'Coordinate team building workshop'),
(14, 5, 15, 'Assist with travel arrangements'),
(15, 6, 18, 'Prepare food for investor meeting');

INSERT INTO staff_log (logID, staffID, reservationID, action, time) VALUES
(1, 1, 1, 'Checked in guest', '2024-11-01 16:30:00'),
(2, 1, 1, 'Processed payment', '2024-11-05 11:45:00'),
(3, 2, 1, 'Cleaned room after checkout', '2024-11-05 14:20:00'),
(4, 3, 3, 'Set up meeting room', '2024-11-03 08:30:00'),
(5, 4, 8, 'Approved conference setup', '2024-11-08 09:15:00'),
(6, 5, 10, 'Made restaurant reservation for guest', '2024-11-10 18:00:00'),
(7, 6, 5, 'Prepared special menu', '2024-11-05 19:30:00'),
(8, 7, 7, 'Served room service', '2024-11-07 20:15:00'),
(9, 8, 8, 'Conducted security check', '2024-11-08 22:00:00'),
(10, 9, 3, 'Fixed projector in meeting room', '2024-11-03 10:45:00'),
(11, 10, 1, 'Generated final bill', '2024-11-05 12:15:00'),
(12, 11, 2, 'Assisted with luggage', '2024-11-02 17:30:00'),
(13, 12, 2, 'Turned down room', '2024-11-02 20:00:00'),
(14, 13, 13, 'Organized workshop materials', '2024-11-13 07:45:00'),
(15, 14, 15, 'Booked taxi for guest', '2024-11-15 16:20:00');

--Queries--
--find all vacant room on given day--
SELECT room.roomID, room.roomNumber
FROM room
LEFT JOIN room_availability
    ON room.roomID = room_availability.roomID
WHERE room_availability.date = '2025-02-10'
  AND room_availability.statusID = 1;

--count reservations per customer--
SELECT customer.name, COUNT(reservation.reservationID)
FROM customer
LEFT JOIN reservation
    ON customer.customerID = reservation.customerID
GROUP BY customer.customerID, customer.name
ORDER BY COUNT(reservation.reservationID) DESC;

--total revenue per customer--
SELECT customer.name, SUM(payment.amount)
FROM customer
JOIN payment
    ON customer.customerID = payment.customerID
GROUP BY customer.customerID, customer.name
ORDER BY SUM(payment.amount) DESC;

--rooms used by each reservation--
SELECT reservation.reservationID, room.roomNumber
FROM reservation
JOIN room_assignment
    ON reservation.reservationID = room_assignment.reservationID
JOIN room
    ON room_assignment.roomID = room.roomID;

--staff involved in each reservation--
SELECT reservation.reservationID, staff.name, staff_role.roleType
FROM reservation
JOIN staff_assignment
    ON reservation.reservationID = staff_assignment.reservationID
JOIN staff
    ON staff_assignment.staffID = staff.staffID
JOIN staff_role
    ON staff_assignment.roleID = staff_role.roleID;

--average event attendance--
SELECT AVG(event.estimatedAttendance)
FROM event;

--most frequently booked room type--
SELECT room_type.sizeLabel, COUNT(*)
FROM reservation
JOIN room_assignment
    ON reservation.reservationID = room_assignment.reservationID
JOIN room
    ON room_assignment.roomID = room.roomID
JOIN room_type
    ON room.roomTypeID = room_type.roomTypeID
GROUP BY room_type.sizeLabel
ORDER BY COUNT(*) DESC
LIMIT 1;

--customers who booked more than 3 times--
SELECT customer.customerID, customer.name, COUNT(*)
FROM reservation
JOIN customer
    ON reservation.customerID = customer.customerID
GROUP BY customer.customerID, customer.name
HAVING COUNT(*) > 3;
