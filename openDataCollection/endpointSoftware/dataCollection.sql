-- phpMyAdmin SQL Dump
-- version 5.0.4deb2ubuntu5
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Feb 22, 2022 at 02:55 AM
-- Server version: 8.0.28-0ubuntu0.21.10.3
-- PHP Version: 8.0.8

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dataCollection`
--
CREATE DATABASE IF NOT EXISTS `dataCollection` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `dataCollection`;

-- --------------------------------------------------------

--
-- Table structure for table `Event`
--

CREATE TABLE `Event` (
  `event` varchar(50) NOT NULL,
  `start` timestamp(3) NULL DEFAULT NULL,
  `end` timestamp(3) NULL DEFAULT NULL,
  `description` text NOT NULL,
  `continuous` text,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `KeyboardInput`
--

CREATE TABLE `KeyboardInput` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `xid` varchar(100) NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `button` varchar(100) NOT NULL,
  `type` varchar(100) NOT NULL,
  `inputTime` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `LastTransfer`
--

CREATE TABLE `LastTransfer` (
  `lastTransfer` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `MouseInput`
--

CREATE TABLE `MouseInput` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `xid` varchar(100) NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `type` varchar(100) NOT NULL,
  `xLoc` int NOT NULL,
  `yLoc` int NOT NULL,
  `inputTime` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `PerformanceMetrics`
--

CREATE TABLE `PerformanceMetrics` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `metricName` varchar(50) NOT NULL,
  `metricValue1` double NOT NULL,
  `metricUnit1` varchar(50) NOT NULL,
  `metricValue2` double NOT NULL DEFAULT '0',
  `metricUnit2` varchar(50) DEFAULT NULL,
  `recordedTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `Process`
--

CREATE TABLE `Process` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `command` text NOT NULL,
  `parentpid` varchar(100) NOT NULL DEFAULT '0',
  `parentuser` varchar(100) NOT NULL DEFAULT '',
  `parentstart` varchar(100) NOT NULL DEFAULT '',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `ProcessArgs`
--

CREATE TABLE `ProcessArgs` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `numbered` int NOT NULL,
  `arg` text NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `ProcessAttributes`
--

CREATE TABLE `ProcessAttributes` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `cpu` decimal(10,0) NOT NULL,
  `mem` decimal(10,0) NOT NULL,
  `vsz` bigint NOT NULL,
  `rss` bigint NOT NULL,
  `tty` varchar(100) NOT NULL,
  `stat` varchar(100) NOT NULL,
  `time` varchar(100) NOT NULL,
  `timestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `ProcessThreads`
--

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
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `Screenshot`
--

CREATE TABLE `Screenshot` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taken` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `screenshot` longblob NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `Task`
--

CREATE TABLE `Task` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taskName` varchar(50) NOT NULL,
  `completion` double NOT NULL,
  `startTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `TaskEvent`
--

CREATE TABLE `TaskEvent` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `taskName` varchar(50) NOT NULL,
  `eventTime` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `eventDescription` varchar(100) NOT NULL,
  `startTimestamp` timestamp(3) NOT NULL DEFAULT '1970-01-01 07:00:01.000',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `UploadToken`
--

CREATE TABLE `UploadToken` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `token` varchar(50) NOT NULL,
  `framesUploaded` int NOT NULL DEFAULT '0',
  `framesRemaining` int NOT NULL DEFAULT '0',
  `active` tinyint NOT NULL DEFAULT '1',
  `lastAltered` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `continuous` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `User`
--

CREATE TABLE `User` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `sessionEnvironment` text NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `Window`
--

CREATE TABLE `Window` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `xid` varchar(100) NOT NULL,
  `firstClass` text NOT NULL,
  `secondClass` text NOT NULL,
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `WindowDetails`
--

CREATE TABLE `WindowDetails` (
  `event` varchar(50) NOT NULL,
  `adminEmail` varchar(100) NOT NULL DEFAULT 'cgtboy1988@yahoo.com',
  `username` varchar(50) NOT NULL,
  `session` varchar(50) NOT NULL,
  `user` varchar(100) NOT NULL,
  `pid` varchar(100) NOT NULL,
  `start` varchar(100) NOT NULL,
  `xid` varchar(100) NOT NULL,
  `x` int NOT NULL,
  `y` int NOT NULL,
  `width` int NOT NULL,
  `height` int NOT NULL,
  `name` text NOT NULL,
  `timeChanged` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3)),
  `active` int NOT NULL DEFAULT '1',
  `insertTimestamp` timestamp(3) NOT NULL DEFAULT (utc_timestamp(3))
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `Event`
--
ALTER TABLE `Event`
  ADD PRIMARY KEY (`event`,`adminEmail`),
  ADD KEY `Event_ibfk_1` (`adminEmail`);

--
-- Indexes for table `KeyboardInput`
--
ALTER TABLE `KeyboardInput`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`inputTime`,`type`,`adminEmail`) USING BTREE,
  ADD KEY `KeyboardInput_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`);

--
-- Indexes for table `LastTransfer`
--
ALTER TABLE `LastTransfer`
  ADD PRIMARY KEY (`lastTransfer`);

--
-- Indexes for table `MouseInput`
--
ALTER TABLE `MouseInput`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`inputTime`,`adminEmail`) USING BTREE,
  ADD KEY `MouseInput_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`);

--
-- Indexes for table `PerformanceMetrics`
--
ALTER TABLE `PerformanceMetrics`
  ADD PRIMARY KEY (`event`,`adminEmail`,`username`,`session`,`metricName`,`recordedTimestamp`) USING BTREE;

--
-- Indexes for table `Process`
--
ALTER TABLE `Process`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`adminEmail`) USING BTREE,
  ADD KEY `Process_ibfk_1` (`event`,`adminEmail`,`username`,`session`);

--
-- Indexes for table `ProcessArgs`
--
ALTER TABLE `ProcessArgs`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`numbered`,`adminEmail`) USING BTREE,
  ADD KEY `ProcessArgs_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`);

--
-- Indexes for table `ProcessAttributes`
--
ALTER TABLE `ProcessAttributes`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`timestamp`,`adminEmail`) USING BTREE,
  ADD KEY `ProcessAttributes_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`timestamp`) USING BTREE;

--
-- Indexes for table `ProcessThreads`
--
ALTER TABLE `ProcessThreads`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`timestamp`,`adminEmail`,`tid`) USING BTREE,
  ADD KEY `ProcessAttributes_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`timestamp`) USING BTREE;

--
-- Indexes for table `Screenshot`
--
ALTER TABLE `Screenshot`
  ADD PRIMARY KEY (`event`,`username`,`session`,`taken`,`adminEmail`) USING BTREE,
  ADD KEY `Screenshot_ibfk_1` (`event`,`adminEmail`,`username`,`session`);

--
-- Indexes for table `Task`
--
ALTER TABLE `Task`
  ADD PRIMARY KEY (`event`,`username`,`session`,`taskName`,`startTimestamp`,`adminEmail`) USING BTREE,
  ADD KEY `Task_ibfk_1` (`event`,`adminEmail`,`username`,`session`);

--
-- Indexes for table `TaskEvent`
--
ALTER TABLE `TaskEvent`
  ADD PRIMARY KEY (`event`,`username`,`session`,`taskName`,`eventTime`,`startTimestamp`,`adminEmail`) USING BTREE,
  ADD KEY `event` (`event`,`adminEmail`,`username`,`session`,`taskName`,`startTimestamp`);

--
-- Indexes for table `UploadToken`
--
ALTER TABLE `UploadToken`
  ADD PRIMARY KEY (`event`,`username`,`token`,`adminEmail`) USING BTREE;

--
-- Indexes for table `User`
--
ALTER TABLE `User`
  ADD PRIMARY KEY (`event`,`username`,`session`,`adminEmail`) USING BTREE,
  ADD KEY `User_ibfk_1` (`event`,`adminEmail`);

--
-- Indexes for table `Window`
--
ALTER TABLE `Window`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`adminEmail`) USING BTREE,
  ADD KEY `Window_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`);

--
-- Indexes for table `WindowDetails`
--
ALTER TABLE `WindowDetails`
  ADD PRIMARY KEY (`event`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`,`adminEmail`) USING BTREE,
  ADD KEY `WindowDetails_ibfk_1` (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `KeyboardInput`
--
ALTER TABLE `KeyboardInput`
  ADD CONSTRAINT `KeyboardInput_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`) REFERENCES `WindowDetails` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `MouseInput`
--
ALTER TABLE `MouseInput`
  ADD CONSTRAINT `MouseInput_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`,`timeChanged`) REFERENCES `WindowDetails` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`, `timeChanged`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `PerformanceMetrics`
--
ALTER TABLE `PerformanceMetrics`
  ADD CONSTRAINT `PerformanceMetrics_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Process`
--
ALTER TABLE `Process`
  ADD CONSTRAINT `Process_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProcessArgs`
--
ALTER TABLE `ProcessArgs`
  ADD CONSTRAINT `ProcessArgs_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`) REFERENCES `Process` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProcessAttributes`
--
ALTER TABLE `ProcessAttributes`
  ADD CONSTRAINT `ProcessAttributes_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`) REFERENCES `Process` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `ProcessThreads`
--
ALTER TABLE `ProcessThreads`
  ADD CONSTRAINT `ProcessThreads_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`timestamp`) REFERENCES `ProcessAttributes` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `timestamp`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Screenshot`
--
ALTER TABLE `Screenshot`
  ADD CONSTRAINT `Screenshot_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Task`
--
ALTER TABLE `Task`
  ADD CONSTRAINT `Task_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`) REFERENCES `User` (`event`, `adminEmail`, `username`, `session`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `TaskEvent`
--
ALTER TABLE `TaskEvent`
  ADD CONSTRAINT `TaskEvent_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`taskName`,`startTimestamp`) REFERENCES `Task` (`event`, `adminEmail`, `username`, `session`, `taskName`, `startTimestamp`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `User`
--
ALTER TABLE `User`
  ADD CONSTRAINT `User_ibfk_1` FOREIGN KEY (`event`,`adminEmail`) REFERENCES `Event` (`event`, `adminEmail`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `Window`
--
ALTER TABLE `Window`
  ADD CONSTRAINT `Window_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`) REFERENCES `Process` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `WindowDetails`
--
ALTER TABLE `WindowDetails`
  ADD CONSTRAINT `WindowDetails_ibfk_1` FOREIGN KEY (`event`,`adminEmail`,`username`,`session`,`user`,`pid`,`start`,`xid`) REFERENCES `Window` (`event`, `adminEmail`, `username`, `session`, `user`, `pid`, `start`, `xid`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

