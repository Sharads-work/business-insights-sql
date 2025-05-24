DROP TABLE IF EXISTS StageCarsBulk;
DROP TABLE IF EXISTS ManualStage;
DROP TABLE IF EXISTS Make;
DROP TABLE IF EXISTS Model;
DROP TABLE IF EXISTS Trim;
DROP TABLE IF EXISTS TrimSpec;
DROP TABLE IF EXISTS Engine;
DROP TABLE IF EXISTS Vehicle;


--CREATE DATABASE ManualNihonCars
--USE ManualNihonCars


-- STEP 1: Create Raw Staging Table
-- ================================
-- Temporary table to load all raw car data from CSV.
CREATE TABLE StageCarsBulk(
	Year INT,
	Make VARCHAR(50),
	Model VARCHAR(50),
	Trim VARCHAR(50),
	ChassisCode VARCHAR(50),
	Price DECIMAL(10,2),
	TireSize VARCHAR(50),
	LengthIn DECIMAL(6,2),
	HeightIn DECIMAL(6,2),
	WidthIn DECIMAL(6,2),
	CargoVolumeCF DECIMAL(6,2),
	TurningRadiusFt DECIMAL(6,2),
	WheelDiameterIn DECIMAL(6,2),
	WheelWidthIn DECIMAL(6,2),
	WheelbaseIn DECIMAL(6,2),
	TrackWidthFrontIn DECIMAL(6,2),
	TrackWidthRearIn DECIMAL(6,2),
	EngineCode VARCHAR(50),
	EngineDisplacementL DECIMAL(3,1),
	CyclinderConfig VARCHAR(50),
	NumCylinders INT,
	Horsepower INT,
	HP_RPM INT,
	PowerToWeight DECIMAL(6,3),
	TorqueLbFt INT,
	Torque_RPM INT,
	BoreMM DECIMAL(6,2),
	CompressionRatio DECIMAL(6,2),
	StrokeMM DECIMAL(6,2),
	CityMPG DECIMAL(3,1),
	HighwayMPG DECIMAL(3,1),
	CombinedMPG DECIMAL(3,1),
	AnnualFuelConsGal DECIMAL(6,2),
	EnergyBarrelsPerYear DECIMAL(6,2),
	FuelTankCapacityGal DECIMAL(3,1),
	Transmission VARCHAR(50),
	TowingCapacityLb INT,
	Driveline VARCHAR(50),
	PayloadLb INT,
	CurbWeightLb INT,
	GVWR_Lb INT,
	WarrantyYears INT,
	WarrantyMiles INT,
	BodyStyle VARCHAR(50)
);


-- STEP 2: Bulk Insert CSV Data into Staging
-- =========================================
-- Bulk import the full dataset from manual_cars_data.csv into StageCarsBulk.
BULK INSERT ManualNihonCars.dbo.StageCarsBulk
FROM 'C:\SQLData\manual_cars_data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- STEP 3: Filter StageCarsBulk to Manual Transmission
-- ===================================================
-- Create ManualStage to isolate only manual transmission vehicles.
-- This aligns with business focus on manual Japanese cars.
SELECT *
INTO ManualStage
FROM StageCarsBulk
WHERE Transmission LIKE '%Manual%'
;


-- STEP 4: Create Normalized Tables
-- ================================

-- MAKES: Unique manufacturers; prevents Make duplication.
CREATE TABLE Make (
	MakeID	 INT IDENTITY(1,1) PRIMARY KEY,
	MakeName VARCHAR(50) NOT NULL UNIQUE,
);

-- MODELS: Associated to Make via FK. Enforces 1:N from Make to Model.
CREATE TABLE Model (
	ModelID	  INT IDENTITY(1, 1) PRIMARY KEY,
	MakeID	  INT NOT NULL REFERENCES Make(MakeID),
	ModelName VARCHAR(50) NOT NULL,
	CONSTRAINT unique_Model_makeid_modelname UNIQUE (MakeID, ModelName)
);

-- TRIMS: Specific versions of a model; 1:N from Model to Trim. Includes chassis, body style, etc.
CREATE TABLE Trim (
	TrimID		INT IDENTITY(1,1) PRIMARY KEY,
	ModelID		INT NOT NULL REFERENCES Model(ModelID),
	TrimName	VARCHAR(50),
	BodyStyle	VARCHAR(50),
	ChassisCode VARCHAR(25),
	CONSTRAINT unique_Trim_modelid_trimname_bodystyle_chassiscode UNIQUE (ModelID, TrimName, BodyStyle, ChassisCode)
);

-- TRIM SPECIFICATIONS: Physical + performance specs per Trim.
CREATE TABLE TrimSpec (
	SpecID				 INT IDENTITY(1,1) PRIMARY KEY,
	TrimID				 INT NOT NULL REFERENCES Trim(TrimID),
	TireSize			 VARCHAR(50),
	WheelDiameterIn		 DECIMAL(6,2),
	WheelWidthIn		 DECIMAL(6,2),
	WheelbaseIn			 DECIMAL(6,2),
	TrackWidthFrontIn	 DECIMAL(6,2),
	TrackWidthRearIn	 DECIMAL(6,2),
	LengthIn			 DECIMAL(6,2),
	HeightIn			 DECIMAL(6,2),
	WidthIn				 DECIMAL(6,2),
	CargoVolumeCF		 DECIMAL(6,2),
	TurningRadiusFt		 DECIMAL(6,2),
	CityMPG				 DECIMAL(3,1),
	HighwayMPG			 DECIMAL(3,1),
	FuelTankCapacityGal	 DECIMAL(3,1),
	TowingCapacityLb     INT,
	GVWR_Lb				 INT,
	CurbWeightLb		 INT
	CONSTRAINT unique_TrimSpec_trimid_spec UNIQUE(TrimID, TireSize, HeightIn, CityMPG, GVWR_Lb, CurbWeightLb)
);

-- ENGINES: Engine-specific details. Avoids repeating engine specs per vehicle.
CREATE TABLE Engine (
	EngineID			INT IDENTITY(1,1) PRIMARY KEY,
	EngineCode			VARCHAR(50),
	EngineDisplacementL	DECIMAL(3,1),
	CylinderConfig		VARCHAR(50),
	NumCylinders		INT,
	BoreMM				DECIMAL(6,2),
	StrokeMM			DECIMAL(6,2),
	CompressionRatio	DECIMAL(6,2),
	Horsepower			INT,
	HP_RPM				INT,
	TorqueLbFt			INT,
	Torque_RPM			INT,
	CONSTRAINT unique_Engine_spec UNIQUE (EngineCode, CompressionRatio, Horsepower, TorqueLbFt, Torque_RPM)
);

-- VEHICLES: Final entity combining Trim, Engine, Year, Price, Transmission
CREATE TABLE Vehicle (
	VehicleID	  INT IDENTITY(1,1) PRIMARY KEY,
	TrimID		  INT REFERENCES Trim(TrimID),
	EngineID	  INT REFERENCES Engine(EngineID),
	Year		  INT,
	Price		  DECIMAL(10,2),
	Transmission  VARCHAR(50),
	Driveline	  VARCHAR(5),
	WarrantyYears INT,
	WarrantyMiles INT
);

-- STEP 5: Populating Normalized Tables
-- ====================================

-- Insert unique Makes
INSERT INTO Make (MakeName)
SELECT DISTINCT Make
FROM ManualStage
;

-- Insert Models avoiding duplicates
INSERT INTO Model (MakeID, ModelName)
SELECT DISTINCT m.MakeID, s.Model
FROM ManualStage s
INNER JOIN Make m ON s.make = m.MakeName 
WHERE NOT EXISTS (
	SELECT 1
	FROM Model mo
	WHERE mo.MakeID = m.MakeID 
		AND mo.ModelName = s.Model
);

-- Insert Trims with uniqueness enforced on combo of Model + Trim details
INSERT INTO Trim (
	ModelID, 
	TrimName, 
	BodyStyle, 
	ChassisCode
	)
SELECT DISTINCT 
	m.ModelID, 
	s.Trim, 
	s.BodyStyle, 
	s.ChassisCode
FROM ManualStage s
INNER JOIN Model m ON s.Model = m.ModelName
WHERE NOT EXISTS (
	SELECT 1 
	FROM Trim t
	WHERE t.TrimName = s.Trim 
		AND t.ModelID = m.ModelID
);

-- Inserts unique Trim specifications
INSERT INTO TrimSpec (
	TrimID, 
	TireSize,
	WheelDiameterIn,
	WheelWidthIn,
	WheelbaseIn, 
	TrackWidthFrontIn, 
	TrackWidthRearIn,
	LengthIn,
	HeightIn, 
	WidthIn,
	CargoVolumeCF,
	TurningRadiusFt,
	CityMPG,
	HighwayMPG, 
	FuelTankCapacityGal, 
	TowingCapacityLb, 
	GVWR_Lb,
	CurbWeightLb
	)
SELECT DISTINCT
	t.TrimID,
	s.TireSize, 
	s.WheelDiameterIn,
	s.WheelWidthIn,
	s.WheelbaseIn, 
	s.TrackWidthFrontIn,
	s.TrackWidthRearIn,
	s.LengthIn, 
	s.HeightIn, 
	s.WidthIn,
	s.CargoVolumeCF, 
	s.TurningRadiusFt,
	s.CityMPG, 
	s.HighwayMPG, 
	s.FuelTankCapacityGal, 
	s.TowingCapacityLb,
	s.GVWR_Lb,
	s.CurbWeightLb
FROM ManualStage s
JOIN Trim t ON t.TrimName = s.Trim
			AND t.ChassisCode = s.ChassisCode
			AND t.BodyStyle = s.BodyStyle
WHERE NOT EXISTS (
    SELECT 1
    FROM TrimSpec ts
    WHERE ts.TrimID = t.TrimID
	  AND ts.CargoVolumeCF = s.CargoVolumeCF
      AND ts.TireSize = s.TireSize
      AND ts.CurbWeightLb = s.CurbWeightLb
);

-- Insert Engine records
INSERT INTO Engine (
	EngineCode, 
	EngineDisplacementL, 
	CylinderConfig, 
	NumCylinders, 
	BoreMM, 
	StrokeMM, 
	CompressionRatio, 
	Horsepower, 
	HP_RPM, 
	TorqueLbFt, 
	Torque_RPM
	)
SELECT DISTINCT 
	EngineCode, 
	EngineDisplacementL, 
	CylinderConfig, 
	NumCylinders, 
	BoreMM, 
	StrokeMM, 
	CompressionRatio, 
	Horsepower, 
	HP_RPM, 
	TorqueLbFt, 
	Torque_RPM
FROM ManualStage s
WHERE NOT EXISTS (
	SELECT 1
	FROM Engine e
	WHERE e.EngineCode = s.EngineCode
		AND e.Horsepower = s.Horsepower
		AND e.TorqueLbFt = s.TorqueLbFt
		AND e.CompressionRatio = s.CompressionRatio
);

-- Insert Vehicle records (ties Trim, Engine, and general attributes)
INSERT INTO Vehicle (
	TrimID,
	EngineID,
	Year,
	Price,
	Transmission,
	Driveline,
	WarrantyYears,
	WarrantyMiles
	)
SELECT DISTINCT
	t.TrimID,
	e.EngineID,
	s.Year,
	s.Price,
	s.Transmission,
	s.Driveline,
	s.WarrantyYears,
	s.WarrantyMiles
FROM ManualStage s
INNER JOIN Trim t ON t.TrimName = s.Trim
				 AND t.ChassisCode = s.ChassisCode
				 AND t.BodyStyle = s.BodyStyle
INNER JOIN Engine e ON e.BoreMM = s.BoreMM
				   AND e.CompressionRatio = s.CompressionRatio
				   AND e.CylinderConfig = s.CylinderConfig
				   AND e.EngineCode = s.EngineCode
				   AND e.EngineDisplacementL = s.EngineDisplacementL
				   AND e.Horsepower = s.Horsepower
				   AND e.HP_RPM = s.HP_RPM
				   AND e.NumCylinders = s.NumCylinders
				   AND e.StrokeMM = s.StrokeMM
				   AND e.Torque_RPM = s.Torque_RPM
				   AND e.TorqueLbFt = s.TorqueLbFt
WHERE NOT EXISTS (
	SELECT 1
	FROM Vehicle v
	WHERE t.TrimID = v.TrimID
	  AND e.EngineID = v.EngineID
	  AND s.Year = v.Year
	  AND s.Price = v.Price
 	  AND s.Transmission = v.Transmission
	  AND s.Driveline = v.Driveline
	  AND s.WarrantyYears = v.WarrantyYears
	  AND s.WarrantyMiles = v.WarrantyMiles
);
