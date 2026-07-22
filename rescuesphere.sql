-- =============================================
-- RescueSphere - Smart Disaster Response System
-- Database Schema
-- =============================================

-- Drop database if exists (CAUTION: Deletes all data)
-- DROP DATABASE IF EXISTS rescuesphere;

-- Create database
CREATE DATABASE IF NOT EXISTS rescuesphere 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE rescuesphere;

-- =============================================
-- 1. USERS TABLE (All user roles)
-- =============================================
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    mobile VARCHAR(20),
    role ENUM('citizen', 'rescue', 'admin') NOT NULL DEFAULT 'citizen',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 2. CITIZENS TABLE (Citizen-specific details)
-- =============================================
CREATE TABLE IF NOT EXISTS citizens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE NOT NULL,
    address TEXT,
    emergency_contact VARCHAR(20),
    blood_group VARCHAR(5),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 3. RESCUE TEAMS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS rescue_teams (
    id INT PRIMARY KEY AUTO_INCREMENT,
    team_code VARCHAR(20) UNIQUE NOT NULL,
    team_name VARCHAR(255) NOT NULL,
    leader_name VARCHAR(255),
    member_count INT DEFAULT 0,
    district VARCHAR(100),
    is_available BOOLEAN DEFAULT TRUE,
    specialization VARCHAR(100),
    user_id INT, -- Team leader (rescue user)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_team_code (team_code),
    INDEX idx_district (district),
    INDEX idx_availability (is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 4. INCIDENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS incidents (
    id INT PRIMARY KEY AUTO_INCREMENT,
    incident_id VARCHAR(20) UNIQUE NOT NULL,
    disaster_type VARCHAR(50) NOT NULL,
    severity ENUM('critical', 'high', 'medium', 'low', 'minor') NOT NULL,
    priority_score INT DEFAULT 0,
    location VARCHAR(255) NOT NULL,
    district VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    people_affected INT DEFAULT 0,
    people_rescued INT DEFAULT 0,
    status ENUM('pending', 'assigned', 'in_progress', 'resolved', 'closed') DEFAULT 'pending',
    description TEXT,
    photos TEXT, -- Comma separated file paths
    reported_by INT,
    assigned_team_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL,
    FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (assigned_team_id) REFERENCES rescue_teams(id) ON DELETE SET NULL,
    INDEX idx_incident_id (incident_id),
    INDEX idx_severity (severity),
    INDEX idx_status (status),
    INDEX idx_district (district),
    INDEX idx_created (created_at),
    FULLTEXT INDEX idx_location_desc (location, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 5. RESOURCES TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS resources (
    id INT PRIMARY KEY AUTO_INCREMENT,
    resource_type ENUM('personnel', 'vehicle', 'medical', 'supply', 'equipment') NOT NULL,
    name VARCHAR(255) NOT NULL,
    total INT DEFAULT 0,
    deployed INT DEFAULT 0,
    available INT DEFAULT 0,
    district VARCHAR(100),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_type (resource_type),
    INDEX idx_district (district)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 6. SHELTERS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS shelters (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    district VARCHAR(100),
    capacity INT DEFAULT 0,
    occupied INT DEFAULT 0,
    is_open BOOLEAN DEFAULT TRUE,
    contact VARCHAR(20),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    amenities TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_district (district),
    INDEX idx_status (is_open)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 7. NOTIFICATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT,
    type ENUM('alert', 'info', 'update', 'warning') DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    link VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user (user_id),
    INDEX idx_read (is_read),
    INDEX idx_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 8. MISSION ASSIGNMENTS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS mission_assignments (
    id INT PRIMARY KEY AUTO_INCREMENT,
    incident_id INT NOT NULL,
    team_id INT NOT NULL,
    assigned_by INT,
    status ENUM('assigned', 'en_route', 'on_site', 'in_progress', 'completed', 'cancelled') DEFAULT 'assigned',
    estimated_arrival TIME,
    actual_arrival TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    FOREIGN KEY (team_id) REFERENCES rescue_teams(id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_incident (incident_id),
    INDEX idx_team (team_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- 9. AI RECOMMENDATIONS TABLE
-- =============================================
CREATE TABLE IF NOT EXISTS ai_recommendations (
    id INT PRIMARY KEY AUTO_INCREMENT,
    incident_id INT NOT NULL,
    recommendation_type VARCHAR(50) NOT NULL,
    recommendation_text TEXT,
    confidence_score DECIMAL(5,2) DEFAULT 0.00,
    status ENUM('pending', 'accepted', 'rejected', 'implemented') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    implemented_at TIMESTAMP NULL,
    FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE,
    INDEX idx_incident (incident_id),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- SAMPLE DATA (For testing)
-- =============================================

-- Insert sample users
INSERT INTO users (email, password_hash, first_name, last_name, mobile, role) VALUES
('admin@rescuesphere.in', 'hashed_password_here', 'Admin', 'User', '+91 99999 99999', 'admin'),
('citizen@example.com', 'hashed_password_here', 'Arjun', 'Nair', '+91 98765 43210', 'citizen'),
('rescue@example.com', 'hashed_password_here', 'Suresh', 'Kumar', '+91 94001 23456', 'rescue');

-- Insert sample rescue teams
INSERT INTO rescue_teams (team_code, team_name, leader_name, member_count, district, is_available) VALUES
('RT-04', 'Flood Response Team', 'Suresh Kumar', 5, 'Ernakulam', TRUE),
('RT-02', 'Mountain Rescue Team', 'Priya Menon', 4, 'Idukki', TRUE),
('RT-07', 'Urban Search & Rescue', 'Rajan Thomas', 6, 'Thrissur', TRUE);

-- Insert sample resources
INSERT INTO resources (resource_type, name, total, deployed, available, district) VALUES
('personnel', 'Rescue Personnel', 84, 62, 22, 'Ernakulam'),
('vehicle', 'Rescue Vehicles', 18, 12, 6, 'Ernakulam'),
('medical', 'Medical Teams', 8, 5, 3, 'Ernakulam'),
('supply', 'Medical Supplies', 1000, 730, 270, 'Ernakulam');

-- Insert sample shelters
INSERT INTO shelters (name, address, district, capacity, occupied, is_open, contact) VALUES
('St. Xavier\'s School', 'Perumbavoor, Ernakulam', 'Ernakulam', 300, 120, TRUE, '+91 98470 12345'),
('Govt. Medical College', 'Ernakulam', 'Ernakulam', 500, 350, TRUE, '+91 484 266 1234'),
('Relief Camp Kalady', 'Kalady Junction', 'Ernakulam', 200, 50, TRUE, '+91 98950 54321');

-- Insert sample incidents
INSERT INTO incidents (incident_id, disaster_type, severity, location, district, people_affected, status, description) VALUES
('INC-001', 'Flood', 'critical', 'Perumbavoor, Ernakulam', 'Ernakulam', 47, 'assigned', 'Major flood in Perumbavoor area. Water levels rising.'),
('INC-002', 'Landslide', 'high', 'Munnar-Bodimettu Road', 'Idukki', 12, 'assigned', 'Landslide blocking road. People trapped in vehicles.'),
('INC-003', 'Fire', 'high', 'Round East, Thrissur', 'Thrissur', 8, 'in_progress', 'Building fire in commercial area.');

-- Insert sample notifications
INSERT INTO notifications (user_id, title, message, type) VALUES
(2, 'Critical Flood Alert', 'Water levels rising in Perumbavoor. Team RT-04 dispatched.', 'alert'),
(2, 'Shelter Opened Nearby', 'St. Xavier\'s School shelter is now open 1.2km away.', 'info'),
(3, 'New Mission Assigned', 'INC-001 - Flood rescue in Perumbavoor', 'update');

-- =============================================
-- VIEWS (Optional - for easier reporting)
-- =============================================

-- View: Active incidents with team details
CREATE OR REPLACE VIEW v_active_incidents AS
SELECT 
    i.incident_id,
    i.disaster_type,
    i.severity,
    i.location,
    i.district,
    i.people_affected,
    i.status,
    i.created_at,
    rt.team_code,
    rt.team_name,
    rt.leader_name,
    u.first_name as reported_by_name
FROM incidents i
LEFT JOIN rescue_teams rt ON i.assigned_team_id = rt.id
LEFT JOIN users u ON i.reported_by = u.id
WHERE i.status IN ('pending', 'assigned', 'in_progress')
ORDER BY i.created_at DESC;

-- View: Resource utilization summary
CREATE OR REPLACE VIEW v_resource_summary AS
SELECT 
    resource_type,
    COUNT(*) as total_types,
    SUM(total) as total_units,
    SUM(deployed) as deployed_units,
    SUM(available) as available_units,
    ROUND(SUM(deployed) / SUM(total) * 100, 2) as utilization_percentage
FROM resources
GROUP BY resource_type;

-- View: District-wise incident statistics
CREATE OR REPLACE VIEW v_district_stats AS
SELECT 
    district,
    COUNT(*) as total_incidents,
    SUM(CASE WHEN severity = 'critical' THEN 1 ELSE 0 END) as critical,
    SUM(CASE WHEN severity = 'high' THEN 1 ELSE 0 END) as high,
    SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) as resolved,
    SUM(people_affected) as total_affected
FROM incidents
GROUP BY district
ORDER BY total_incidents DESC;

-- =============================================
-- STORED PROCEDURES (Optional)
-- =============================================

-- Procedure: Get incidents by district and severity
DELIMITER //
CREATE PROCEDURE sp_get_incidents_by_filter(
    IN p_district VARCHAR(100),
    IN p_severity VARCHAR(20)
)
BEGIN
    SELECT * FROM incidents
    WHERE (p_district IS NULL OR district = p_district)
    AND (p_severity IS NULL OR severity = p_severity)
    ORDER BY created_at DESC;
END //
DELIMITER ;

-- Procedure: Update incident status with timestamp
DELIMITER //
CREATE PROCEDURE sp_update_incident_status(
    IN p_incident_id VARCHAR(20),
    IN p_new_status VARCHAR(20)
)
BEGIN
    UPDATE incidents 
    SET status = p_new_status,
        updated_at = CURRENT_TIMESTAMP,
        resolved_at = IF(p_new_status = 'resolved', CURRENT_TIMESTAMP, resolved_at)
    WHERE incident_id = p_incident_id;
END //
DELIMITER ;

-- =============================================
-- INDEXES for performance optimization
-- =============================================

-- Additional indexes for common queries
CREATE INDEX idx_incidents_severity_status ON incidents(severity, status);
CREATE INDEX idx_incidents_district_created ON incidents(district, created_at);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX idx_mission_assignments_status ON mission_assignments(status);
CREATE INDEX idx_resources_district_type ON resources(district, resource_type);

-- =============================================
-- TRIGGERS (Optional)
-- =============================================

-- Trigger: Auto-update resource availability when deployed changes
DELIMITER //
CREATE TRIGGER trg_update_resource_available
BEFORE UPDATE ON resources
FOR EACH ROW
BEGIN
    SET NEW.available = NEW.total - NEW.deployed;
END //
DELIMITER ;

-- Trigger: Auto-create notification when incident assigned
DELIMITER //
CREATE TRIGGER trg_incident_assigned_notification
AFTER UPDATE ON incidents
FOR EACH ROW
BEGIN
    IF NEW.assigned_team_id IS NOT NULL AND OLD.assigned_team_id IS NULL THEN
        INSERT INTO notifications (user_id, title, message, type)
        SELECT 
            rt.user_id,
            CONCAT('New Mission: ', NEW.incident_id),
            CONCAT('Incident ', NEW.incident_id, ' - ', NEW.disaster_type, ' at ', NEW.location),
            'update'
        FROM rescue_teams rt
        WHERE rt.id = NEW.assigned_team_id;
    END IF;
END //
DELIMITER ;

-- =============================================
-- DISPLAY ALL TABLES
-- =============================================
SHOW TABLES;

-- =============================================
-- END OF SCRIPT
-- =============================================