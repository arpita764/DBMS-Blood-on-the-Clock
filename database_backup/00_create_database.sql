-- =============================================================
-- FILE   : 00_create_database.sql
-- PURPOSE: Create the emergency_system database.
--          Run this FIRST before any other SQL file.
--          Safe to re-run: CREATE DATABASE IF NOT EXISTS.
-- =============================================================

CREATE DATABASE IF NOT EXISTS emergency_system
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE emergency_system;
