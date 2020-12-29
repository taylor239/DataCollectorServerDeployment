-- MySQL dump 10.13  Distrib 5.7.21, for Linux (x86_64)
--
-- Host: localhost    Database: openDataCollectionServer
-- ------------------------------------------------------
-- Server version	5.7.21-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE IF NOT EXISTS `openDataCollectionServer` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `openDataCollectionServer`;

--
-- Table structure for table `Event`
--

DROP TABLE IF EXISTS `Event`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Event` (
  `event` varchar(50) NOT NULL,
  `start` timestamp NULL DEFAULT NULL,
  `end` timestamp NULL DEFAULT NULL,
  `description` text NOT NULL,
  PRIMARY KEY (`event`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EventContact`
--

DROP TABLE IF EXISTS `EventContact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `EventContact` (
  `event` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `contact` text NOT NULL,
  PRIMARY KEY (`event`,`name`),
  CONSTRAINT `EventContact_ibfk_1` FOREIGN KEY (`event`) REFERENCES `Event` (`event`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EventTimeSynchro`
--

DROP TABLE IF EXISTS `EventTimeSynchro`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `EventTimeSynchro` (
  `event` varchar(50) NOT NULL,
  `localServerTime` timestamp(3) NULL DEFAULT NULL,
  `eventServerTime` bigint(20) NOT NULL,
  PRIMARY KEY (`event`),
  CONSTRAINT `EventTimeSynchro_ibfk_1` FOREIGN KEY (`event`) REFERENCES `Event` (`event`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `KeyboardInput`
--

DROP TABLE IF EXISTS `KeyboardInput`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `KeyboardInput` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `xid` varchar(10) NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `button` varchar(10) NOT NULL,
  `type` varchar(10) NOT NULL,
  `inputTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`inputTime`,`type`) USING BTREE,
  CONSTRAINT `KeyboardInput_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) REFERENCES `WindowDetails` (`event`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LastTransfer`
--

DROP TABLE IF EXISTS `LastTransfer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `LastTransfer` (
  `lastTransfer` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`lastTransfer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `MouseInput`
--

DROP TABLE IF EXISTS `MouseInput`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `MouseInput` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `xid` varchar(10) NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `type` varchar(10) NOT NULL,
  `xLoc` int(11) NOT NULL,
  `yLoc` int(11) NOT NULL,
  `inputTime` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`inputTime`) USING BTREE,
  CONSTRAINT `MouseInput_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) REFERENCES `WindowDetails` (`event`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Process`
--

DROP TABLE IF EXISTS `Process`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Process` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `command` text NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`) USING BTREE,
  CONSTRAINT `Process_ibfk_1` FOREIGN KEY (`event`, `username`, `session`) REFERENCES `User` (`event`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ProcessArgs`
--

DROP TABLE IF EXISTS `ProcessArgs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ProcessArgs` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `numbered` int(11) NOT NULL,
  `arg` text NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`numbered`) USING BTREE,
  CONSTRAINT `ProcessArgs_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `user`, `pid`, `start`) REFERENCES `Process` (`event`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ProcessAttributes`
--

DROP TABLE IF EXISTS `ProcessAttributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ProcessAttributes` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `cpu` decimal(10,0) NOT NULL,
  `mem` decimal(10,0) NOT NULL,
  `vsz` mediumint(9) NOT NULL,
  `rss` mediumint(9) NOT NULL,
  `tty` varchar(10) NOT NULL,
  `stat` varchar(10) NOT NULL,
  `time` varchar(10) NOT NULL,
  `timestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`timestamp`) USING BTREE,
  CONSTRAINT `ProcessAttributes_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `user`, `pid`, `start`) REFERENCES `Process` (`event`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Screenshot`
--

DROP TABLE IF EXISTS `Screenshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Screenshot` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taken` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `screenshot` longblob NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`taken`) USING BTREE,
  CONSTRAINT `Screenshot_ibfk_1` FOREIGN KEY (`event`, `username`, `session`) REFERENCES `User` (`event`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Task`
--

DROP TABLE IF EXISTS `Task`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Task` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taskName` varchar(50) NOT NULL,
  `completion` double NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`taskName`) USING BTREE,
  CONSTRAINT `Task_ibfk_1` FOREIGN KEY (`event`, `username`, `session`) REFERENCES `User` (`event`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TaskEvent`
--

DROP TABLE IF EXISTS `TaskEvent`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `TaskEvent` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taskName` varchar(50) NOT NULL,
  `eventTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `eventDescription` varchar(20) NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`taskName`,`eventTime`) USING BTREE,
  CONSTRAINT `TaskEvent_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `taskName`) REFERENCES `Task` (`event`, `username`, `session`, `taskName`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UploadToken`
--

DROP TABLE IF EXISTS `UploadToken`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `UploadToken` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `token` varchar(50) NOT NULL,
  `framesUploaded` int(11) NOT NULL DEFAULT '0',
  `framesRemaining` int(11) NOT NULL DEFAULT '0',
  `active` tinyint(4) NOT NULL DEFAULT '1',
  `lastAltered` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `continuous` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`event`,`username`,`token`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `User`
--

DROP TABLE IF EXISTS `User`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `User` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`),
  CONSTRAINT `User_ibfk_1` FOREIGN KEY (`event`) REFERENCES `Event` (`event`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UserIP`
--

DROP TABLE IF EXISTS `UserIP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `UserIP` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `ip` varchar(50) NOT NULL,
  `start` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`ip`,`start`) USING BTREE,
  CONSTRAINT `UserIP_ibfk_1` FOREIGN KEY (`event`, `username`, `session`) REFERENCES `User` (`event`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `UserList`
--

DROP TABLE IF EXISTS `UserList`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `UserList` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  PRIMARY KEY (`event`,`username`),
  CONSTRAINT `UserList_ibfk_1` FOREIGN KEY (`event`) REFERENCES `Event` (`event`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Window`
--

DROP TABLE IF EXISTS `Window`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `Window` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `xid` varchar(10) NOT NULL,
  `firstClass` varchar(20) NOT NULL,
  `secondClass` varchar(20) NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`) USING BTREE,
  CONSTRAINT `Window_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `user`, `pid`, `start`) REFERENCES `Process` (`event`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WindowDetails`
--

DROP TABLE IF EXISTS `WindowDetails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `WindowDetails` (
  `event` varchar(50) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(20) NOT NULL,
  `pid` varchar(10) NOT NULL,
  `start` varchar(10) NOT NULL,
  `xid` varchar(10) NOT NULL,
  `x` int(11) NOT NULL,
  `y` int(11) NOT NULL,
  `width` int(11) NOT NULL,
  `height` int(11) NOT NULL,
  `name` text NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`) USING BTREE,
  CONSTRAINT `WindowDetails_ibfk_1` FOREIGN KEY (`event`, `username`, `session`, `user`, `pid`, `start`, `xid`) REFERENCES `Window` (`event`, `username`, `session`, `user`, `pid`, `start`, `xid`) ON DELETE CASCADE ON UPDATE CASCADE
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

-- Dump completed on 2018-01-25 12:26:42
