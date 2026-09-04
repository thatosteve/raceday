-- ============================================================
-- RaceDay Database  |  PROG6212 Programming 2B  |  Part 1 Section C
-- Run this top to bottom in SSMS. It matches the ERD in /docs.
-- ============================================================

CREATE DATABASE RaceDayDb;
USE RaceDayDb;

-- ============================================================
-- TABLES
-- ============================================================

-- Lookup table for the two roles
CREATE TABLE ROLES (
    role_id   INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    role_name VARCHAR(20) NOT NULL UNIQUE          -- 'Organiser' or 'Participant'
);

-- Every user (both Organisers and Participants)
CREATE TABLE USERS (
    user_id           INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    role_id           INT NOT NULL,
    first_name        VARCHAR(50) NOT NULL,
    last_name         VARCHAR(50) NOT NULL,
    email             VARCHAR(150) NOT NULL UNIQUE,
    password_hash     VARCHAR(255) NOT NULL,       -- store the HASH, never the real password
    phone_number      VARCHAR(20),
    date_of_birth     DATE,
    profile_image_url VARCHAR(500),                -- filled in Part 3 (Azure Blob)
    created_at        DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_USERS_ROLES FOREIGN KEY (role_id) REFERENCES ROLES(role_id)
);

-- Events created by Organisers
CREATE TABLE EVENTS (
    event_id         INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    organiser_id     INT NOT NULL,                 -- points to a USER who is an Organiser
    name             VARCHAR(150) NOT NULL,
    description      VARCHAR(1000),
    event_date       DATETIME NOT NULL,
    location         VARCHAR(200) NOT NULL,
    distance_km      DECIMAL(6,2),
    event_type       VARCHAR(10) NOT NULL,
    banner_image_url VARCHAR(500),                 -- filled in Part 3 (Azure Blob)
    created_at       DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_EVENTS_USERS FOREIGN KEY (organiser_id) REFERENCES USERS(user_id),
    CONSTRAINT CK_EVENTS_TYPE  CHECK (event_type IN ('run', 'walk', 'cycle'))
);

-- Categories belong to an event (e.g. 10km, Under 20)
CREATE TABLE CATEGORIES (
    category_id   INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    event_id      INT NOT NULL,
    name          VARCHAR(100) NOT NULL,
    category_type VARCHAR(20) NOT NULL,
    created_at    DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CATEGORIES_EVENTS FOREIGN KEY (event_id) REFERENCES EVENTS(event_id),
    CONSTRAINT CK_CATEGORIES_TYPE   CHECK (category_type IN ('Age', 'Distance'))
);

-- A Participant entering an event under a chosen category
CREATE TABLE ENROLMENTS (
    enrolment_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    user_id      INT NOT NULL,                     -- the Participant
    event_id     INT NOT NULL,
    category_id  INT NOT NULL,
    status       VARCHAR(20) NOT NULL DEFAULT 'Pending',
    enrolled_at  DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_ENROLMENTS_USERS      FOREIGN KEY (user_id)     REFERENCES USERS(user_id),
    CONSTRAINT FK_ENROLMENTS_EVENTS     FOREIGN KEY (event_id)    REFERENCES EVENTS(event_id),
    CONSTRAINT FK_ENROLMENTS_CATEGORIES FOREIGN KEY (category_id) REFERENCES CATEGORIES(category_id),
    CONSTRAINT CK_ENROLMENTS_STATUS     CHECK (status IN ('Pending', 'Confirmed')),
    CONSTRAINT UQ_ENROLMENTS            UNIQUE (user_id, event_id)  -- one entry per person per event
);

-- The result for an enrolment (captured by the Organiser after the event)
CREATE TABLE RESULTS (
    result_id       INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
    enrolment_id    INT NOT NULL UNIQUE,           -- one result per enrolment
    finish_time     TIME,
    finish_position INT,
    recorded_at     DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_RESULTS_ENROLMENTS FOREIGN KEY (enrolment_id) REFERENCES ENROLMENTS(enrolment_id)
);

-- ============================================================
-- SAMPLE DATA
-- Note: the ID numbers below rely on the auto-numbering.
-- The first row added to a table gets ID 1, the next gets 2, etc.
-- ============================================================

-- ROLES  ->  role_id 1 = Organiser, role_id 2 = Participant
INSERT INTO ROLES (role_name)
VALUES ('Organiser'),
       ('Participant');
SELECT * FROM ROLES;

-- USERS  ->  user 1 & 2 are Organisers, user 3 & 4 are Participants
INSERT INTO USERS (role_id, first_name, last_name, email, password_hash, phone_number, date_of_birth)
VALUES (1, 'Thandiwe', 'Nkosi',   'thandiwe.nkosi@raceday.co.za', 'HASH_ORG1', '0821234567', '1985-04-12'),  -- user_id 1
       (1, 'Pieter',   'van Wyk', 'pieter.vanwyk@raceday.co.za',  'HASH_ORG2', '0837654321', '1979-11-03'),  -- user_id 2
       (2, 'Sipho',    'Dlamini', 'sipho.dlamini@gmail.com',      'HASH_PT1',  '0729876543', '1996-07-21'),  -- user_id 3
       (2, 'Aisha',    'Patel',   'aisha.patel@gmail.com',        'HASH_PT2',  '0763456789', '2001-02-15');  -- user_id 4
SELECT * FROM USERS;

-- EVENTS  ->  events 1 & 2 owned by Organiser 1, event 3 owned by Organiser 2
INSERT INTO EVENTS (organiser_id, name, description, event_date, location, distance_km, event_type)
VALUES (1, 'Soweto Spring Run',        'Community road run through Soweto.',            '2026-09-20 07:00', 'Soweto, Johannesburg',   21.10, 'run'),   -- event_id 1
       (1, 'Joburg City Charity Walk', 'Family charity walk for local schools.',        '2026-10-05 08:00', 'Sandton, Johannesburg',   5.00, 'walk'),  -- event_id 2
       (2, 'Cape Peninsula Cycle',     'Scenic coastal cycle around the peninsula.',    '2026-11-15 06:30', 'Cape Town, Western Cape', 65.00, 'cycle'); -- event_id 3
SELECT * FROM EVENTS;

-- CATEGORIES  ->  numbered 1-7 in the order below
INSERT INTO CATEGORIES (event_id, name, category_type)
VALUES (1, '10km',     'Distance'),   -- category_id 1  (Soweto Spring Run)
       (1, '21km',     'Distance'),   -- category_id 2  (Soweto Spring Run)
       (1, 'Senior',   'Age'),        -- category_id 3  (Soweto Spring Run)
       (2, '5km',      'Distance'),   -- category_id 4  (Charity Walk)
       (2, 'Under 20', 'Age'),        -- category_id 5  (Charity Walk)
       (3, '65km',     'Distance'),   -- category_id 6  (Cape Peninsula Cycle)
       (3, 'Masters',  'Age');        -- category_id 7  (Cape Peninsula Cycle)
SELECT * FROM CATEGORIES;

-- ENROLMENTS  ->  (user_id, event_id, category_id)
INSERT INTO ENROLMENTS (user_id, event_id, category_id, status)
VALUES (3, 1, 2, 'Confirmed'),   -- enrolment 1: Sipho -> Soweto Spring Run (21km)
       (3, 2, 4, 'Pending'),     -- enrolment 2: Sipho -> Charity Walk (5km)
       (4, 1, 2, 'Confirmed'),   -- enrolment 3: Aisha -> Soweto Spring Run (21km)
       (4, 3, 6, 'Confirmed');   -- enrolment 4: Aisha -> Cape Peninsula Cycle (65km)
SELECT * FROM ENROLMENTS;

-- RESULTS  ->  captured for two enrolments from the Soweto Spring Run
INSERT INTO RESULTS (enrolment_id, finish_time, finish_position)
VALUES (1, '01:52:34', 47),   -- Sipho's result
       (3, '02:05:10', 88);   -- Aisha's result
SELECT * FROM RESULTS;
