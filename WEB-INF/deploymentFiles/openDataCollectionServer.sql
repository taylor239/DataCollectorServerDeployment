-- MySQL dump 10.13  Distrib 8.0.30, for Linux (x86_64)
--
-- Host: localhost    Database: openDataCollectionServer
-- ------------------------------------------------------
-- Server version	8.0.30-0ubuntu0.22.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE IF NOT EXISTS `openDataCollectionServer` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `openDataCollectionServer`;

--
-- Table structure for table `ActiveHistory`
--

DROP TABLE IF EXISTS `ActiveHistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ActiveHistory` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `snapTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `minutesActive` bigint NOT NULL,
  `isCurrent` tinyint NOT NULL DEFAULT '1',
  `resolution` int NOT NULL,
  PRIMARY KEY (`event`,`adminEmail`,`username`,`session`,`snapTime`,`isCurrent`) USING BTREE,
  KEY `event` (`event`,`username`,`session`,`adminEmail`),
  CONSTRAINT `ActiveHistory_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `adminEmail`) REFERENCES `User` (`event`, `username`, `session`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Admin`
--

DROP TABLE IF EXISTS `Admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Admin` (
  `adminEmail` varchar(100) NOT NULL,
  `adminPassword` text NOT NULL,
  `name` text NOT NULL,
  PRIMARY KEY (`adminEmail`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `BoundsHistory`
--

DROP TABLE IF EXISTS `BoundsHistory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `BoundsHistory` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `snapTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `count` bigint NOT NULL,
  `startDate` timestamp(3) NOT NULL,
  `endDate` timestamp(3) NOT NULL,
  `dataType` varchar(50) NOT NULL,
  `isCurrent` tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY (`event`,`adminEmail`,`username`,`session`,`dataType`,`snapTime`,`isCurrent`) USING BTREE,
  KEY `event` (`event`,`username`,`session`,`adminEmail`),
  CONSTRAINT `BoundsHistory_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `adminEmail`) REFERENCES `User` (`event`, `username`, `session`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Event`
--

DROP TABLE IF EXISTS `Event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Event` (
  `event` varchar(50) NOT NULL,
  `start` timestamp(3) NULL DEFAULT NULL,
  `end` timestamp(3) NULL DEFAULT NULL,
  `description` text NOT NULL,
  `continuous` text,
  `taskgui` text,
  `password` text NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `public` tinyint NOT NULL DEFAULT '0',
  `publicEvent` tinyint NOT NULL DEFAULT '0',
  `dynamicTokens` int NOT NULL DEFAULT '0',
  `autorestart` tinyint NOT NULL DEFAULT '0',
  `diffType` varchar(20) NOT NULL DEFAULT '',
  `compType` varchar(20) NOT NULL DEFAULT 'png',
  `compAmount` varchar(20) NOT NULL DEFAULT '0',
  `metrics` tinyint NOT NULL DEFAULT '0',
  `processGranularity` varchar(20) NOT NULL DEFAULT 'thread',
  `screenshotInterval` varchar(20) NOT NULL DEFAULT '100',
  `processInterval` varchar(20) NOT NULL DEFAULT '10000',
  PRIMARY KEY (`event`,`adminEmail`),
  KEY `Event_ibfk_1` (`adminEmail`),
  CONSTRAINT `Event_ibfk_1` FOREIGN KEY (`adminEmail`) REFERENCES `Admin` (`adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EventContact`
--

DROP TABLE IF EXISTS `EventContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EventContact` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL,
  `name` varchar(50) NOT NULL,
  `contact` text NOT NULL,
  PRIMARY KEY (`event`,`name`,`adminEmail`) USING BTREE,
  KEY `EventContact_ibfk_1` (`event`,`adminEmail`),
  CONSTRAINT `EventContact_ibfk_1` FOREIGN KEY (`event`, `adminEmail`) REFERENCES `Event` (`event`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EventPassword`
--

DROP TABLE IF EXISTS `EventPassword`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EventPassword` (
  `event` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `adminEmail` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `password` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `tagger` varchar(50) DEFAULT NULL,
  `anon` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`event`,`adminEmail`,`password`),
  KEY `adminEmail` (`adminEmail`,`event`),
  CONSTRAINT `EventPassword_ibfk_1` FOREIGN KEY (`adminEmail`, `event`) REFERENCES `Event` (`adminEmail`, `event`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EventTimeSynchro`
--

DROP TABLE IF EXISTS `EventTimeSynchro`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EventTimeSynchro` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `localServerTime` timestamp(3) NULL DEFAULT NULL,
  `eventServerTime` bigint NOT NULL,
  PRIMARY KEY (`event`,`adminEmail`) USING BTREE,
  CONSTRAINT `EventTimeSynchro_ibfk_1` FOREIGN KEY (`event`, `adminEmail`) REFERENCES `Event` (`event`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `KeyboardInput`
--

DROP TABLE IF EXISTS `KeyboardInput`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `KeyboardInput` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `xid` varchar(10) NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `button` varchar(10) NOT NULL,
  `type` varchar(10) NOT NULL,
  `inputTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`inputTime`,`type`,`adminEmail`) USING BTREE,
  KEY `KeyboardInput_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`),
  CONSTRAINT `KeyboardInput_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) REFERENCES `WindowDetails` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LastTransfer`
--

DROP TABLE IF EXISTS `LastTransfer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LastTransfer` (
  `lastTransfer` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`lastTransfer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MouseInput`
--

DROP TABLE IF EXISTS `MouseInput`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `MouseInput` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `xid` varchar(10) NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `type` varchar(10) NOT NULL,
  `xLoc` int NOT NULL,
  `yLoc` int NOT NULL,
  `inputTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`inputTime`,`adminEmail`) USING BTREE,
  KEY `MouseInput_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`),
  CONSTRAINT `MouseInput_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) REFERENCES `WindowDetails` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `PerformanceMetrics`
--

DROP TABLE IF EXISTS `PerformanceMetrics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `PerformanceMetrics` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `metricName` varchar(50) NOT NULL,
  `metricValue1` double NOT NULL,
  `metricUnit1` varchar(50) NOT NULL,
  `metricValue2` double NOT NULL DEFAULT '0',
  `metricUnit2` varchar(50) NOT NULL,
  `recordedTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  PRIMARY KEY (`event`,`adminEmail`,`username`,`session`,`metricName`,`metricUnit1`,`metricUnit2`,`recordedTimestamp`) USING BTREE,
  CONSTRAINT `PerformanceMetrics_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Process`
--

DROP TABLE IF EXISTS `Process`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Process` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `pid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `command` text NOT NULL,
  `parentpid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '0',
  `parentuser` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `parentstart` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL DEFAULT '',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`adminEmail`) USING BTREE,
  KEY `Process_ibfk_1` (`event`,`adminEmail`,`username`,`session`),
  CONSTRAINT `Process_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ProcessArgs`
--

DROP TABLE IF EXISTS `ProcessArgs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ProcessArgs` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `pid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `numbered` int NOT NULL,
  `arg` text NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`numbered`,`adminEmail`) USING BTREE,
  KEY `ProcessArgs_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`),
  CONSTRAINT `ProcessArgs_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) REFERENCES `Process` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ProcessAttributes`
--

DROP TABLE IF EXISTS `ProcessAttributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ProcessAttributes` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `pid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `cpu` decimal(10,0) NOT NULL,
  `mem` decimal(10,0) NOT NULL,
  `vsz` bigint NOT NULL,
  `rss` bigint NOT NULL,
  `tty` varchar(10) NOT NULL,
  `stat` varchar(10) NOT NULL,
  `time` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `timestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`timestamp`,`adminEmail`) USING BTREE,
  KEY `ProcessAttributes_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`),
  CONSTRAINT `ProcessAttributes_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) REFERENCES `Process` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ProcessThreads`
--

DROP TABLE IF EXISTS `ProcessThreads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ProcessThreads` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `name` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `tid` varchar(100) NOT NULL,
  `tstate` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `tcpu` decimal(10,0) NOT NULL,
  `minorfault` bigint NOT NULL,
  `majorfault` bigint NOT NULL,
  `tstart` varchar(100) NOT NULL,
  `priority` int NOT NULL,
  `timestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`timestamp`,`adminEmail`,`tid`) USING BTREE,
  KEY `ProcessAttributes_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`timestamp`) USING BTREE,
  CONSTRAINT `ProcessThreads_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `timestamp`) REFERENCES `ProcessAttributes` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `timestamp`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Screenshot`
--

DROP TABLE IF EXISTS `Screenshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Screenshot` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taken` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `screenshot` longblob NOT NULL,
  `ocrtext` text NOT NULL,
  `doneocr` tinyint NOT NULL DEFAULT '0',
  `frameType` varchar(5) NOT NULL DEFAULT 'key',
  `encoding` varchar(5) NOT NULL DEFAULT 'jpg',
  `xStart` int NOT NULL DEFAULT '0',
  `yStart` int NOT NULL DEFAULT '0',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`taken`,`adminEmail`) USING BTREE,
  KEY `Screenshot_ibfk_1` (`event`,`adminEmail`,`username`,`session`),
  CONSTRAINT `Screenshot_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Task`
--

DROP TABLE IF EXISTS `Task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Task` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taskName` varchar(50) NOT NULL,
  `goal` text NOT NULL,
  `completion` double NOT NULL,
  `note` text NOT NULL,
  `startTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`taskName`,`startTimestamp`,`adminEmail`) USING BTREE,
  KEY `Task_ibfk_1` (`event`,`adminEmail`,`username`,`session`),
  CONSTRAINT `Task_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TaskEvent`
--

DROP TABLE IF EXISTS `TaskEvent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TaskEvent` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taskName` varchar(50) NOT NULL,
  `eventTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `eventDescription` varchar(20) NOT NULL,
  `startTimestamp` timestamp(3) NOT NULL DEFAULT '1970-01-01 07:00:01.000',
  `source` varchar(100) NOT NULL DEFAULT 'User',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`taskName`,`eventTime`,`startTimestamp`,`adminEmail`) USING BTREE,
  KEY `event` (`event`,`username`,`session`,`taskName`,`startTimestamp`),
  KEY `TaskEvent_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`taskName`,`startTimestamp`),
  CONSTRAINT `TaskEvent_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `taskName`, `startTimestamp`) REFERENCES `Task` (`event`, `adminEmail`, `username`, `session`, `taskName`, `startTimestamp`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TaskTags`
--

DROP TABLE IF EXISTS `TaskTags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TaskTags` (
  `event` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `adminEmail` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `username` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `session` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `taskName` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `startTimestamp` timestamp(3) NOT NULL,
  `tag` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`event`,`adminEmail`,`username`,`session`,`taskName`,`startTimestamp`,`tag`),
  KEY `TaskTags_ibfk_1` (`event`,`username`,`session`,`taskName`,`startTimestamp`,`adminEmail`),
  CONSTRAINT `TaskTags_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `taskName`, `startTimestamp`, `adminEmail`) REFERENCES `Task` (`event`, `username`, `session`, `taskName`, `startTimestamp`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TaskTagsPublic`
--

DROP TABLE IF EXISTS `TaskTagsPublic`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TaskTagsPublic` (
  `tag` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  PRIMARY KEY (`tag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TokenRequest`
--

DROP TABLE IF EXISTS `TokenRequest`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TokenRequest` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL,
  `requestedUsername` varchar(50) NOT NULL,
  `requesterName` varchar(50) NOT NULL,
  `requesterEmail` varchar(100) NOT NULL,
  `insertTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`adminEmail`,`requestedUsername`),
  CONSTRAINT `TokenRequest_ibfk_1` FOREIGN KEY (`event`, `adminEmail`) REFERENCES `Event` (`event`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UploadToken`
--

DROP TABLE IF EXISTS `UploadToken`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UploadToken` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `token` varchar(50) NOT NULL,
  `framesUploaded` int NOT NULL DEFAULT '0',
  `framesRemaining` int NOT NULL DEFAULT '0',
  `framesAborted` int NOT NULL DEFAULT '0',
  `active` tinyint NOT NULL DEFAULT '1',
  `lastAltered` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `continuous` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`event`,`username`,`token`,`adminEmail`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `User`
--

DROP TABLE IF EXISTS `User`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `User` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `sessionEnvironment` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `notes` text NOT NULL,
  PRIMARY KEY (`event`,`username`,`session`,`adminEmail`) USING BTREE,
  KEY `User_ibfk_1` (`event`,`adminEmail`),
  CONSTRAINT `User_ibfk_1` FOREIGN KEY (`event`, `adminEmail`) REFERENCES `Event` (`event`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UserIP`
--

DROP TABLE IF EXISTS `UserIP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UserIP` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `ip` varchar(50) NOT NULL,
  `start` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`ip`,`start`,`adminEmail`) USING BTREE,
  KEY `UserIP_ibfk_1` (`event`,`adminEmail`,`username`,`session`),
  CONSTRAINT `UserIP_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UserList`
--

DROP TABLE IF EXISTS `UserList`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `UserList` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `name` text NOT NULL,
  `email` text NOT NULL,
  PRIMARY KEY (`event`,`username`,`adminEmail`) USING BTREE,
  KEY `UserList_ibfk_1` (`event`,`adminEmail`),
  CONSTRAINT `UserList_ibfk_1` FOREIGN KEY (`event`, `adminEmail`) REFERENCES `Event` (`event`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `VisualizationFilters`
--

DROP TABLE IF EXISTS `VisualizationFilters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `VisualizationFilters` (
  `event` varchar(50) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `adminEmail` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `level` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `field` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `value` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `server` int NOT NULL DEFAULT '0',
  `saveName` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `filterNum` int NOT NULL,
  PRIMARY KEY (`event`,`adminEmail`,`saveName`,`filterNum`),
  KEY `adminEmail` (`adminEmail`,`event`),
  CONSTRAINT `VisualizationFilters_ibfk_1` FOREIGN KEY (`adminEmail`, `event`) REFERENCES `Event` (`adminEmail`, `event`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Window`
--

DROP TABLE IF EXISTS `Window`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Window` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `pid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `xid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `firstClass` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `secondClass` text CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`adminEmail`) USING BTREE,
  KEY `Window_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`),
  CONSTRAINT `Window_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) REFERENCES `Process` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WindowDetails`
--

DROP TABLE IF EXISTS `WindowDetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `WindowDetails` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `pid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `start` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `xid` varchar(100) CHARACTER SET latin1 COLLATE latin1_swedish_ci NOT NULL,
  `x` int NOT NULL,
  `y` int NOT NULL,
  `width` int NOT NULL,
  `height` int NOT NULL,
  `name` text NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `active` int NOT NULL DEFAULT '1',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`adminEmail`) USING BTREE,
  KEY `WindowDetails_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`),
  CONSTRAINT `WindowDetails_ibfk_1` FOREIGN KEY (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`) REFERENCES `Window` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2022-10-13  3:11:21