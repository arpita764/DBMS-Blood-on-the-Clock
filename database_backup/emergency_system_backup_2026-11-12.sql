CREATE DATABASE  IF NOT EXISTS `emergency_system` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `emergency_system`;
-- MySQL dump 10.13  Distrib 8.0.33, for Win64 (x86_64)
--
-- Host: localhost    Database: emergency_system
-- ------------------------------------------------------
-- Server version	8.0.33

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `app_user`
--

DROP TABLE IF EXISTS `app_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_user` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('ADMIN','HOSPITAL_STAFF') COLLATE utf8mb4_unicode_ci NOT NULL,
  `account_status` enum('ACTIVE','DISABLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `hospital_id` int DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  KEY `fk_user_hospital` (`hospital_id`),
  CONSTRAINT `fk_user_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital` (`hospital_id`),
  CONSTRAINT `chk_user_role` CHECK (((`role` = _cp850'ADMIN') or (`hospital_id` is not null)))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='System users: Admin or Hospital Staff';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_user`
--

LOCK TABLES `app_user` WRITE;
/*!40000 ALTER TABLE `app_user` DISABLE KEYS */;
INSERT INTO `app_user` VALUES (1,'Admin User','admin@bloodclock.com','$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u','ADMIN','ACTIVE',NULL),(2,'Priya Sharma','priya@citygeneral.com','$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u','HOSPITAL_STAFF','ACTIVE',1),(3,'Rajan Nair','rajan@apollobb.com','$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u','HOSPITAL_STAFF','ACTIVE',2),(4,'Anjali Mehta','anjali@metrotrauma.com','$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u','HOSPITAL_STAFF','ACTIVE',3),(5,'Suresh Pillai','suresh@sunrisemc.com','$2b$12$K9L1mV5XjZL.VqY8f4CcOeNZrLQ1gP2hBwDmUKf7xTtM8sA3nIv4u','HOSPITAL_STAFF','ACTIVE',4);
/*!40000 ALTER TABLE `app_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `available_blood_by_hospital`
--

DROP TABLE IF EXISTS `available_blood_by_hospital`;
/*!50001 DROP VIEW IF EXISTS `available_blood_by_hospital`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `available_blood_by_hospital` AS SELECT 
 1 AS `hospital_id`,
 1 AS `hospital_name`,
 1 AS `city`,
 1 AS `blood_group`,
 1 AS `available_units`,
 1 AS `reserved_units`,
 1 AS `last_updated`,
 1 AS `hospital_status`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `blood_compatibility`
--

DROP TABLE IF EXISTS `blood_compatibility`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blood_compatibility` (
  `donor_group_id` int NOT NULL,
  `recipient_group_id` int NOT NULL,
  PRIMARY KEY (`donor_group_id`,`recipient_group_id`),
  KEY `fk_bc_recipient` (`recipient_group_id`),
  CONSTRAINT `fk_bc_donor` FOREIGN KEY (`donor_group_id`) REFERENCES `blood_group` (`blood_group_id`),
  CONSTRAINT `fk_bc_recipient` FOREIGN KEY (`recipient_group_id`) REFERENCES `blood_group` (`blood_group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='M:N blood compatibility (donor -> recipient)';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blood_compatibility`
--

LOCK TABLES `blood_compatibility` WRITE;
/*!40000 ALTER TABLE `blood_compatibility` DISABLE KEYS */;
INSERT INTO `blood_compatibility` VALUES (1,1),(2,1),(7,1),(8,1),(2,2),(8,2),(3,3),(4,3),(7,3),(8,3),(4,4),(8,4),(1,5),(2,5),(3,5),(4,5),(5,5),(6,5),(7,5),(8,5),(2,6),(4,6),(6,6),(8,6),(7,7),(8,7),(8,8);
/*!40000 ALTER TABLE `blood_compatibility` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `blood_group`
--

DROP TABLE IF EXISTS `blood_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blood_group` (
  `blood_group_id` int NOT NULL AUTO_INCREMENT,
  `group_name` varchar(3) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`blood_group_id`),
  UNIQUE KEY `group_name` (`group_name`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Blood group reference lookup';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blood_group`
--

LOCK TABLES `blood_group` WRITE;
/*!40000 ALTER TABLE `blood_group` DISABLE KEYS */;
INSERT INTO `blood_group` VALUES (2,'A-'),(1,'A+'),(6,'AB-'),(5,'AB+'),(4,'B-'),(3,'B+'),(8,'O-'),(7,'O+');
/*!40000 ALTER TABLE `blood_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `blood_inventory`
--

DROP TABLE IF EXISTS `blood_inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blood_inventory` (
  `inventory_id` int NOT NULL AUTO_INCREMENT,
  `hospital_id` int NOT NULL,
  `blood_group_id` int NOT NULL,
  `available_units` int NOT NULL DEFAULT '0',
  `reserved_units` int NOT NULL DEFAULT '0',
  `allocated_units` int NOT NULL DEFAULT '0',
  `last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`inventory_id`),
  UNIQUE KEY `uq_inv_hosp_grp` (`hospital_id`,`blood_group_id`),
  KEY `idx_inv_group_avail` (`blood_group_id`,`available_units`),
  CONSTRAINT `fk_inv_blood` FOREIGN KEY (`blood_group_id`) REFERENCES `blood_group` (`blood_group_id`),
  CONSTRAINT `fk_inv_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital` (`hospital_id`),
  CONSTRAINT `chk_inv_alloc` CHECK ((`allocated_units` >= 0)),
  CONSTRAINT `chk_inv_avail` CHECK ((`available_units` >= 0)),
  CONSTRAINT `chk_inv_resv` CHECK ((`reserved_units` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Blood stock per hospital and blood group';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blood_inventory`
--

LOCK TABLES `blood_inventory` WRITE;
/*!40000 ALTER TABLE `blood_inventory` DISABLE KEYS */;
INSERT INTO `blood_inventory` VALUES (1,1,1,15,0,2,'2026-11-11 03:33:20'),(2,1,2,8,0,1,'2026-11-11 03:33:20'),(3,1,3,20,0,0,'2026-11-11 03:33:20'),(4,1,7,25,0,3,'2026-11-11 03:33:20'),(5,1,8,5,5,1,'2026-11-11 03:34:50'),(6,2,1,32,0,0,'2026-11-11 03:34:50'),(7,2,5,12,0,0,'2026-11-11 03:33:20'),(8,2,7,21,0,0,'2026-11-11 03:34:50'),(9,2,8,22,0,0,'2026-11-11 03:33:20'),(10,3,3,10,0,1,'2026-11-11 03:33:20'),(11,3,4,5,0,0,'2026-11-11 03:33:20'),(12,3,7,14,1,0,'2026-11-11 03:33:20'),(13,3,8,9,0,0,'2026-11-11 03:33:20'),(14,4,1,6,0,0,'2026-11-11 03:33:20'),(15,4,2,3,0,0,'2026-11-11 03:33:20'),(16,4,3,4,0,4,'2026-11-11 03:34:50'),(17,4,6,4,0,0,'2026-11-11 03:33:20'),(18,4,7,11,0,0,'2026-11-11 03:33:20'),(19,4,8,2,5,0,'2026-11-11 03:34:50'),(20,4,5,5,0,0,'2026-11-11 03:33:20');
/*!40000 ALTER TABLE `blood_inventory` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_inventory_audit` AFTER UPDATE ON `blood_inventory` FOR EACH ROW BEGIN
  IF OLD.available_units <> NEW.available_units
     OR OLD.reserved_units <> NEW.reserved_units THEN
    INSERT INTO inventory_audit
      (inventory_id, old_available, new_available, old_reserved, new_reserved)
    VALUES
      (OLD.inventory_id, OLD.available_units, NEW.available_units,
       OLD.reserved_units, NEW.reserved_units);
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `blood_reservation`
--

DROP TABLE IF EXISTS `blood_reservation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `blood_reservation` (
  `reservation_id` int NOT NULL AUTO_INCREMENT,
  `request_id` int NOT NULL,
  `hospital_id` int NOT NULL,
  `blood_group_id` int NOT NULL,
  `units_reserved` int NOT NULL,
  `status` enum('RESERVED','ALLOCATED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RESERVED',
  `reserved_by` int DEFAULT NULL,
  `reserved_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`reservation_id`),
  KEY `fk_res_hospital` (`hospital_id`),
  KEY `fk_res_blood` (`blood_group_id`),
  KEY `fk_res_user` (`reserved_by`),
  KEY `idx_res_request` (`request_id`,`status`),
  CONSTRAINT `fk_res_blood` FOREIGN KEY (`blood_group_id`) REFERENCES `blood_group` (`blood_group_id`),
  CONSTRAINT `fk_res_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital` (`hospital_id`),
  CONSTRAINT `fk_res_request` FOREIGN KEY (`request_id`) REFERENCES `emergency_request` (`request_id`),
  CONSTRAINT `fk_res_user` FOREIGN KEY (`reserved_by`) REFERENCES `app_user` (`user_id`),
  CONSTRAINT `chk_res_units` CHECK ((`units_reserved` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Blood units reserved for a request';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `blood_reservation`
--

LOCK TABLES `blood_reservation` WRITE;
/*!40000 ALTER TABLE `blood_reservation` DISABLE KEYS */;
INSERT INTO `blood_reservation` VALUES (1,5,2,7,3,'CANCELLED',3,'2026-11-10 07:30:00'),(2,6,1,1,2,'ALLOCATED',2,'2026-11-09 06:30:00'),(3,2,2,1,2,'CANCELLED',2,'2026-11-11 09:15:00'),(4,7,4,5,1,'CANCELLED',5,'2026-11-08 05:15:00'),(5,3,4,3,4,'ALLOCATED',5,'2026-11-11 09:04:50'),(6,1,1,8,5,'RESERVED',4,'2026-11-11 09:04:50'),(7,1,4,8,5,'RESERVED',4,'2026-11-11 09:04:50');
/*!40000 ALTER TABLE `blood_reservation` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `donor`
--

DROP TABLE IF EXISTS `donor`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `donor` (
  `donor_id` int NOT NULL AUTO_INCREMENT,
  `donor_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `blood_group_id` int NOT NULL,
  `hospital_id` int NOT NULL,
  `availability_status` enum('AVAILABLE','UNAVAILABLE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AVAILABLE',
  `last_donation_date` date DEFAULT NULL,
  PRIMARY KEY (`donor_id`),
  KEY `fk_donor_hospital` (`hospital_id`),
  KEY `idx_donor_group_avail` (`blood_group_id`,`availability_status`),
  KEY `idx_donor_city` (`city`),
  CONSTRAINT `fk_donor_blood` FOREIGN KEY (`blood_group_id`) REFERENCES `blood_group` (`blood_group_id`),
  CONSTRAINT `fk_donor_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital` (`hospital_id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Blood donors registered by hospital staff';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `donor`
--

LOCK TABLES `donor` WRITE;
/*!40000 ALTER TABLE `donor` DISABLE KEYS */;
INSERT INTO `donor` VALUES (1,'Arun Kumar','9876543210','Bangalore',7,1,'AVAILABLE','2026-08-15'),(2,'Meena Iyer','9765432109','Bangalore',2,1,'AVAILABLE','2026-07-20'),(3,'Vikram Singh','9654321098','Chennai',8,2,'AVAILABLE','2026-09-01'),(4,'Deepa Krishnan','9543210987','Chennai',5,2,'UNAVAILABLE','2026-10-05'),(5,'Rahul Gupta','9432109876','Delhi',3,3,'AVAILABLE','2026-06-18'),(6,'Sunita Patel','9321098765','Delhi',1,3,'AVAILABLE','2026-09-22'),(7,'Kiran Desai','9210987654','Pune',4,4,'AVAILABLE','2026-08-30'),(8,'Pooja Nair','9109876543','Pune',6,4,'AVAILABLE','2026-07-11'),(9,'Amit Joshi','9098765432','Bangalore',7,1,'UNAVAILABLE','2026-10-25'),(10,'Latha Reddy','9876501234','Chennai',8,2,'AVAILABLE','2026-05-14');
/*!40000 ALTER TABLE `donor` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `emergency_request`
--

DROP TABLE IF EXISTS `emergency_request`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `emergency_request` (
  `request_id` int NOT NULL AUTO_INCREMENT,
  `hospital_id` int NOT NULL,
  `blood_group_id` int NOT NULL,
  `quantity_required` int NOT NULL,
  `priority` enum('CRITICAL','HIGH','MEDIUM','LOW') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'MEDIUM',
  `status` enum('PENDING','RESERVED','FULFILLED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `required_by` datetime NOT NULL,
  `created_by` int DEFAULT NULL,
  PRIMARY KEY (`request_id`),
  KEY `fk_er_blood` (`blood_group_id`),
  KEY `fk_er_user` (`created_by`),
  KEY `idx_er_status_prio` (`status`,`priority`,`required_by`),
  KEY `idx_er_hospital` (`hospital_id`),
  CONSTRAINT `fk_er_blood` FOREIGN KEY (`blood_group_id`) REFERENCES `blood_group` (`blood_group_id`),
  CONSTRAINT `fk_er_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital` (`hospital_id`),
  CONSTRAINT `fk_er_user` FOREIGN KEY (`created_by`) REFERENCES `app_user` (`user_id`),
  CONSTRAINT `chk_er_qty` CHECK ((`quantity_required` > 0)),
  CONSTRAINT `chk_er_time` CHECK ((`required_by` > `created_at`))
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Emergency blood requests';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `emergency_request`
--

LOCK TABLES `emergency_request` WRITE;
/*!40000 ALTER TABLE `emergency_request` DISABLE KEYS */;
INSERT INTO `emergency_request` VALUES (1,3,8,5,'CRITICAL','RESERVED','2026-11-10 08:00:00','2026-11-10 10:00:00',4),(2,1,1,3,'HIGH','CANCELLED','2026-11-11 09:00:00','2026-11-11 15:00:00',2),(3,4,3,4,'MEDIUM','FULFILLED','2026-11-11 10:00:00','2026-11-12 10:00:00',5),(4,2,7,2,'LOW','PENDING','2026-11-11 11:00:00','2026-11-13 11:00:00',3),(5,3,7,3,'HIGH','PENDING','2026-11-10 07:00:00','2026-11-11 12:00:00',4),(6,1,1,2,'MEDIUM','FULFILLED','2026-11-09 06:00:00','2026-11-10 06:00:00',2),(7,4,5,1,'LOW','CANCELLED','2026-11-08 05:00:00','2026-11-09 05:00:00',5),(8,1,8,4,'CRITICAL','PENDING','2026-11-11 06:00:00','2026-11-11 14:00:00',2);
/*!40000 ALTER TABLE `emergency_request` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hospital`
--

DROP TABLE IF EXISTS `hospital`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hospital` (
  `hospital_id` int NOT NULL AUTO_INCREMENT,
  `hospital_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hospital_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (`hospital_id`),
  KEY `idx_hospital_city` (`city`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Registered hospitals / blood banks';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hospital`
--

LOCK TABLES `hospital` WRITE;
/*!40000 ALTER TABLE `hospital` DISABLE KEYS */;
INSERT INTO `hospital` VALUES (1,'City General Hospital','12 MG Road','Bangalore','080-22001100','General','ACTIVE'),(2,'Apollo Blood Bank','45 Anna Salai','Chennai','044-28001200','Blood Bank','ACTIVE'),(3,'Metro Trauma Centre','7 Rajpath','Delhi','011-23001300','Trauma','ACTIVE'),(4,'Sunrise Medical Centre','89 FC Road','Pune','020-24001400','General','ACTIVE'),(5,'Lifeline Hospital','33 Park Street','Kolkata','033-25001500','General','INACTIVE');
/*!40000 ALTER TABLE `hospital` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_audit`
--

DROP TABLE IF EXISTS `inventory_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_audit` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `inventory_id` int NOT NULL,
  `old_available` int NOT NULL,
  `new_available` int NOT NULL,
  `old_reserved` int NOT NULL,
  `new_reserved` int NOT NULL,
  `changed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`audit_id`),
  KEY `fk_audit_inv` (`inventory_id`),
  CONSTRAINT `fk_audit_inv` FOREIGN KEY (`inventory_id`) REFERENCES `blood_inventory` (`inventory_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Filled automatically by trigger';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_audit`
--

LOCK TABLES `inventory_audit` WRITE;
/*!40000 ALTER TABLE `inventory_audit` DISABLE KEYS */;
INSERT INTO `inventory_audit` VALUES (1,16,8,4,0,4,'2026-11-11 03:34:50'),(2,5,10,5,0,5,'2026-11-11 03:34:50'),(3,19,7,2,0,5,'2026-11-11 03:34:50'),(4,16,4,4,4,0,'2026-11-11 03:34:50'),(5,8,18,21,3,0,'2026-11-11 03:34:50'),(6,6,30,32,2,0,'2026-11-11 03:34:50');
/*!40000 ALTER TABLE `inventory_audit` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `resource`
--

DROP TABLE IF EXISTS `resource`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resource` (
  `resource_id` int NOT NULL AUTO_INCREMENT,
  `hospital_id` int NOT NULL,
  `resource_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `resource_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_quantity` int NOT NULL,
  `available_quantity` int NOT NULL,
  `status` enum('AVAILABLE','UNAVAILABLE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AVAILABLE',
  PRIMARY KEY (`resource_id`),
  KEY `idx_resource_hosp_type` (`hospital_id`,`resource_type`),
  CONSTRAINT `fk_resource_hospital` FOREIGN KEY (`hospital_id`) REFERENCES `hospital` (`hospital_id`),
  CONSTRAINT `chk_resource_avail` CHECK (((`available_quantity` >= 0) and (`available_quantity` <= `total_quantity`))),
  CONSTRAINT `chk_resource_total` CHECK ((`total_quantity` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Emergency resources owned by hospitals';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `resource`
--

LOCK TABLES `resource` WRITE;
/*!40000 ALTER TABLE `resource` DISABLE KEYS */;
INSERT INTO `resource` VALUES (1,1,'ICU Bed Unit A','ICU Bed',10,3,'AVAILABLE'),(2,1,'Adult Ventilator','Ventilator',6,2,'AVAILABLE'),(3,1,'Ambulance Unit 1','Ambulance',3,1,'AVAILABLE'),(4,2,'ICU Bed Wing B','ICU Bed',15,5,'AVAILABLE'),(5,2,'Paediatric Ventilator','Ventilator',4,4,'AVAILABLE'),(6,2,'Ambulance Unit 2','Ambulance',2,2,'AVAILABLE'),(7,3,'Trauma ICU Beds','ICU Bed',20,5,'AVAILABLE'),(8,3,'High-Flow Ventilator','Ventilator',8,0,'UNAVAILABLE'),(9,3,'Ambulance Unit 3','Ambulance',4,3,'AVAILABLE'),(10,4,'General ICU Beds','ICU Bed',8,6,'AVAILABLE'),(11,4,'Standard Ventilator','Ventilator',3,1,'AVAILABLE'),(12,4,'Ambulance Unit 4','Ambulance',2,0,'UNAVAILABLE'),(13,1,'Neonatal ICU Bed','ICU Bed',4,4,'AVAILABLE'),(14,2,'Transport Ambulance','Ambulance',3,3,'AVAILABLE'),(15,3,'Mobile ICU','ICU Bed',2,2,'AVAILABLE');
/*!40000 ALTER TABLE `resource` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'emergency_system'
--
/*!50003 DROP FUNCTION IF EXISTS `calculate_emergency_priority` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` FUNCTION `calculate_emergency_priority`(
  p_priority    VARCHAR(10),
  p_required_by DATETIME
) RETURNS int
    DETERMINISTIC
BEGIN
  DECLARE v_score INT DEFAULT 0;

  SET v_score = CASE p_priority
    WHEN 'CRITICAL' THEN 4
    WHEN 'HIGH'     THEN 3
    WHEN 'MEDIUM'   THEN 2
    ELSE 1
  END;

  
  IF p_required_by IS NOT NULL AND p_required_by < NOW() THEN
    SET v_score = v_score + 1;
  END IF;

  RETURN v_score;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `allocate_resource` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `allocate_resource`(
  IN  p_resource_id       INT,
  IN  p_units_to_allocate INT,
  IN  p_allocated_by      INT,
  OUT p_message           VARCHAR(255)
)
BEGIN
  DECLARE v_available INT DEFAULT -1;
  DECLARE v_status    VARCHAR(20) DEFAULT '';
  DECLARE v_new_avail INT DEFAULT 0;
  DECLARE v_ok        TINYINT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception ??? transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT available_quantity, `status`
  INTO   v_available, v_status
  FROM   resource
  WHERE  resource_id = p_resource_id
  FOR UPDATE;

  IF v_available = -1 THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Resource not found.';
  END IF;

  IF v_ok = 1 AND v_status = 'UNAVAILABLE' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Resource is marked UNAVAILABLE.';
  END IF;

  IF v_ok = 1 AND v_available < p_units_to_allocate THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Insufficient resource units. Available: ',
                            v_available, ', requested: ', p_units_to_allocate, '.');
  END IF;

  IF v_ok = 1 THEN
    SET v_new_avail = v_available - p_units_to_allocate;

    UPDATE resource
    SET    available_quantity = v_new_avail,
           `status`           = IF(v_new_avail = 0, 'UNAVAILABLE', 'AVAILABLE')
    WHERE  resource_id        = p_resource_id;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Allocated ', p_units_to_allocate,
                            ' unit(s) of resource ', p_resource_id,
                            '. Remaining available: ', v_new_avail, '.');
  ELSE
    ROLLBACK;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `cancel_request` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `cancel_request`(
  IN  p_request_id   INT,
  IN  p_cancelled_by INT,
  OUT p_message      VARCHAR(255)
)
BEGIN
  DECLARE v_req_status   VARCHAR(20) DEFAULT '';
  DECLARE v_done         INT DEFAULT 0;
  DECLARE v_res_id       INT;
  DECLARE v_units        INT;
  DECLARE v_blood_grp    INT;
  DECLARE v_hosp_id      INT;
  DECLARE v_inv_id       INT DEFAULT 0;
  DECLARE v_released_cnt INT DEFAULT 0;
  DECLARE v_ok           TINYINT DEFAULT 1;

  DECLARE cur_reservations CURSOR FOR
    SELECT reservation_id, units_reserved, blood_group_id, hospital_id
    FROM   blood_reservation
    WHERE  request_id = p_request_id
      AND  `status`   = 'RESERVED';

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception ??? transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT `status`
  INTO   v_req_status
  FROM   emergency_request
  WHERE  request_id = p_request_id
  FOR UPDATE;

  IF v_req_status = '' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Request not found.';
  END IF;

  IF v_ok = 1 AND v_req_status IN ('FULFILLED', 'CANCELLED') THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Request is already ', v_req_status,
                            ' ??? cannot cancel.');
  END IF;

  IF v_ok = 1 THEN
    OPEN cur_reservations;

    reservation_loop: LOOP
      FETCH cur_reservations INTO v_res_id, v_units, v_blood_grp, v_hosp_id;
      IF v_done = 1 THEN LEAVE reservation_loop; END IF;

      SET v_inv_id = 0;

      SELECT inventory_id
      INTO   v_inv_id
      FROM   blood_inventory
      WHERE  hospital_id    = v_hosp_id
        AND  blood_group_id = v_blood_grp;

      IF v_inv_id > 0 THEN
        UPDATE blood_inventory
        SET    available_units = available_units + v_units,
               reserved_units  = reserved_units  - v_units
        WHERE  inventory_id    = v_inv_id;
      END IF;

      UPDATE blood_reservation
      SET    `status` = 'CANCELLED'
      WHERE  reservation_id = v_res_id;

      SET v_released_cnt = v_released_cnt + 1;
    END LOOP;

    CLOSE cur_reservations;

    UPDATE emergency_request
    SET    `status` = 'CANCELLED'
    WHERE  request_id = p_request_id;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Request ', p_request_id,
                            ' cancelled. ', v_released_cnt,
                            ' reservation(s) released and inventory restored.');
  ELSE
    ROLLBACK;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `find_available_resources` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_available_resources`(IN p_type VARCHAR(50))
BEGIN
  SELECT
    h.hospital_name,
    h.city,
    r.resource_name,
    r.resource_type,
    r.available_quantity
  FROM resource r
  JOIN hospital h ON h.hospital_id = r.hospital_id
  WHERE r.resource_type     = p_type
    AND r.available_quantity > 0
    AND r.status             = 'AVAILABLE'
    AND h.status             = 'ACTIVE'
  ORDER BY r.available_quantity DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `fulfill_reservation` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `fulfill_reservation`(
  IN  p_reservation_id INT,
  IN  p_fulfilled_by   INT,
  OUT p_message        VARCHAR(255)
)
BEGIN
  DECLARE v_inv_id      INT DEFAULT 0;
  DECLARE v_units       INT DEFAULT 0;
  DECLARE v_res_status  VARCHAR(20) DEFAULT '';
  DECLARE v_request_id  INT DEFAULT 0;
  DECLARE v_blood_grp   INT DEFAULT 0;
  DECLARE v_hosp_id     INT DEFAULT 0;
  DECLARE v_pending_cnt INT DEFAULT 0;
  DECLARE v_ok          TINYINT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception ??? transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT `status`, units_reserved, request_id, blood_group_id, hospital_id
  INTO   v_res_status, v_units, v_request_id, v_blood_grp, v_hosp_id
  FROM   blood_reservation
  WHERE  reservation_id = p_reservation_id
  FOR UPDATE;

  IF v_res_status = '' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Reservation not found.';
  END IF;

  IF v_ok = 1 AND v_res_status <> 'RESERVED' THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Reservation is already ', v_res_status,
                            ' ??? duplicate fulfilment prevented.');
  END IF;

  IF v_ok = 1 THEN
    SELECT inventory_id
    INTO   v_inv_id
    FROM   blood_inventory
    WHERE  hospital_id    = v_hosp_id
      AND  blood_group_id = v_blood_grp
    FOR UPDATE;

    UPDATE blood_inventory
    SET    reserved_units  = reserved_units  - v_units,
           allocated_units = allocated_units + v_units
    WHERE  inventory_id    = v_inv_id;

    UPDATE blood_reservation
    SET    `status` = 'ALLOCATED'
    WHERE  reservation_id = p_reservation_id;

    
    SELECT COUNT(*)
    INTO   v_pending_cnt
    FROM   blood_reservation
    WHERE  request_id = v_request_id
      AND  `status`   = 'RESERVED';

    IF v_pending_cnt = 0 THEN
      UPDATE emergency_request
      SET    `status` = 'FULFILLED'
      WHERE  request_id = v_request_id;
    END IF;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Reservation ', p_reservation_id,
                            ' fulfilled (', v_units, ' unit(s) allocated).');
  ELSE
    ROLLBACK;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `release_reservation` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `release_reservation`(
  IN  p_reservation_id INT,
  IN  p_released_by    INT,
  OUT p_message        VARCHAR(255)
)
BEGIN
  DECLARE v_inv_id      INT DEFAULT 0;
  DECLARE v_units       INT DEFAULT 0;
  DECLARE v_res_status  VARCHAR(20) DEFAULT '';
  DECLARE v_request_id  INT DEFAULT 0;
  DECLARE v_blood_grp   INT DEFAULT 0;
  DECLARE v_hosp_id     INT DEFAULT 0;
  DECLARE v_still_res   INT DEFAULT 0;
  DECLARE v_ok          TINYINT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_message = 'ERROR: Unexpected SQL exception ??? transaction rolled back.';
  END;

  SET p_message = '';
  SET v_ok      = 1;

  START TRANSACTION;

  SELECT `status`, units_reserved, request_id, blood_group_id, hospital_id
  INTO   v_res_status, v_units, v_request_id, v_blood_grp, v_hosp_id
  FROM   blood_reservation
  WHERE  reservation_id = p_reservation_id
  FOR UPDATE;

  IF v_res_status = '' THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Reservation not found.';
  END IF;

  IF v_ok = 1 AND v_res_status <> 'RESERVED' THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Reservation is ', v_res_status,
                            ' ??? only RESERVED reservations can be released.');
  END IF;

  IF v_ok = 1 THEN
    SELECT inventory_id
    INTO   v_inv_id
    FROM   blood_inventory
    WHERE  hospital_id    = v_hosp_id
      AND  blood_group_id = v_blood_grp
    FOR UPDATE;

    UPDATE blood_inventory
    SET    available_units = available_units + v_units,
           reserved_units  = reserved_units  - v_units
    WHERE  inventory_id    = v_inv_id;

    UPDATE blood_reservation
    SET    `status` = 'CANCELLED'
    WHERE  reservation_id = p_reservation_id;

    SELECT COUNT(*)
    INTO   v_still_res
    FROM   blood_reservation
    WHERE  request_id = v_request_id
      AND  `status`   = 'RESERVED';

    IF v_still_res = 0 THEN
      UPDATE emergency_request
      SET    `status` = 'PENDING'
      WHERE  request_id = v_request_id
        AND  `status`   = 'RESERVED';
    END IF;

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Reservation ', p_reservation_id,
                            ' released ??? ', v_units,
                            ' unit(s) restored to available inventory.');
  ELSE
    ROLLBACK;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `reserve_blood` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `reserve_blood`(
  IN  p_request_id           INT,
  IN  p_supplier_hospital_id INT,
  IN  p_units                INT,
  IN  p_reserved_by          INT,
  OUT p_reservation_id       INT,
  OUT p_message              VARCHAR(255)
)
BEGIN
  
  DECLARE v_req_blood_group_id INT     DEFAULT 0;
  DECLARE v_req_status         VARCHAR(20) DEFAULT '';
  DECLARE v_inv_id             INT     DEFAULT 0;
  DECLARE v_available          INT     DEFAULT 0;
  DECLARE v_ok                 TINYINT DEFAULT 1;   

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_reservation_id = 0;
    SET p_message = 'ERROR: Unexpected SQL exception ??? transaction rolled back.';
  END;

  
  SET p_reservation_id = 0;
  SET p_message        = '';
  SET v_ok             = 1;

  START TRANSACTION;

  
  SELECT blood_group_id, `status`
  INTO   v_req_blood_group_id, v_req_status
  FROM   emergency_request
  WHERE  request_id = p_request_id
  FOR UPDATE;

  IF v_req_blood_group_id = 0 THEN
    SET v_ok = 0;
    SET p_message = 'ERROR: Emergency request not found.';
  END IF;

  IF v_ok = 1 AND v_req_status NOT IN ('PENDING', 'RESERVED') THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Request is ', v_req_status,
                            ' ??? only PENDING or RESERVED requests can be reserved.');
  END IF;

  
  IF v_ok = 1 THEN
    SELECT inventory_id, available_units
    INTO   v_inv_id, v_available
    FROM   blood_inventory
    WHERE  hospital_id    = p_supplier_hospital_id
      AND  blood_group_id = v_req_blood_group_id
    FOR UPDATE;

    IF v_inv_id = 0 THEN
      SET v_ok = 0;
      SET p_message = 'ERROR: Supplier hospital has no inventory for the requested blood group.';
    END IF;
  END IF;

  
  IF v_ok = 1 AND v_available < p_units THEN
    SET v_ok = 0;
    SET p_message = CONCAT('ERROR: Insufficient stock. Available: ', v_available,
                            ' unit(s), requested: ', p_units, ' unit(s).');
  END IF;

  
  IF v_ok = 1 THEN
    UPDATE blood_inventory
    SET    available_units = available_units - p_units,
           reserved_units  = reserved_units  + p_units
    WHERE  inventory_id    = v_inv_id;

    INSERT INTO blood_reservation
      (request_id, hospital_id, blood_group_id, units_reserved,
       status, reserved_by, reserved_at)
    VALUES
      (p_request_id, p_supplier_hospital_id, v_req_blood_group_id,
       p_units, 'RESERVED', p_reserved_by, NOW());

    SET p_reservation_id = LAST_INSERT_ID();

    
    UPDATE emergency_request
    SET    `status` = 'RESERVED'
    WHERE  request_id = p_request_id
      AND  `status`   = 'PENDING';

    COMMIT;
    SET p_message = CONCAT('SUCCESS: Reserved ', p_units,
                            ' unit(s). Reservation ID = ', p_reservation_id, '.');
  ELSE
    ROLLBACK;
  END IF;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `available_blood_by_hospital`
--

/*!50001 DROP VIEW IF EXISTS `available_blood_by_hospital`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `available_blood_by_hospital` AS select `h`.`hospital_id` AS `hospital_id`,`h`.`hospital_name` AS `hospital_name`,`h`.`city` AS `city`,`bg`.`group_name` AS `blood_group`,`bi`.`available_units` AS `available_units`,`bi`.`reserved_units` AS `reserved_units`,`bi`.`last_updated` AS `last_updated`,`h`.`status` AS `hospital_status` from ((`blood_inventory` `bi` join `hospital` `h` on((`h`.`hospital_id` = `bi`.`hospital_id`))) join `blood_group` `bg` on((`bg`.`blood_group_id` = `bi`.`blood_group_id`))) where (`h`.`status` = 'ACTIVE') order by `bi`.`available_units` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-12 14:24:02
