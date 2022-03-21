/* 
SET SQL_SAFE_UPDATES = 1; -- Changes SafeMode to On, 1 = ON, 0 = OFF
*/ 

-- CONVERT EMPTY STRINGS TO NULL
UPDATE NashvilleHousing
SET
    PropertyAddress = CASE PropertyAddress WHEN '' THEN NULL ELSE PropertyAddress END,
    OwnerName = CASE OwnerName WHEN '' THEN NULL ELSE OwnerName END,
    OwnerAddress = CASE OwnerAddress WHEN '' THEN NULL ELSE OwnerAddress END,
    Acreage = CASE Acreage WHEN '' THEN NULL ELSE Acreage END,
    TaxDistrict = CASE TaxDistrict WHEN '' THEN NULL ELSE TaxDistrict END,
    LandValue = CASE LandValue WHEN '' THEN NULL ELSE LandValue END,
    BuildingValue = CASE BuildingValue WHEN '' THEN NULL ELSE BuildingValue END,
    TotalValue = CASE TotalValue WHEN '' THEN NULL ELSE TotalValue END,
    YearBuilt = CASE YearBuilt WHEN '' THEN NULL ELSE YearBuilt END,
    Bedrooms = CASE Bedrooms WHEN '' THEN NULL ELSE Bedrooms END,
    FullBath = CASE FullBath WHEN '' THEN NULL ELSE FullBath END,
    HalfBath = CASE HalfBath WHEN '' THEN NULL ELSE HalfBath END


/*

CLEANING DATA IN SQL QUERIES

*/


-- STANDARDIZE DATE FORMAT

SELECT SaleDateConverted -- , CONVERT('SaleDateConverted', DATE)
FROM PortfolioDataCleaning.NashvilleHousing

-- UPDATE NashvilleHousing
-- SET SaleDate = CONVERT('SaleDate', DATE)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %D %Y');
 
 ------------------------------------------------------------------------
 
-- Populate Property Address Data

SELECT PropertyAddress
FROM PortfolioDataCleaning.NashvilleHousing
-- WHERE PropertyAddress <=> ''
ORDER BY ParcelID;

-- Visualizing the column that will fill in the NULL
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioDataCleaning.NashvilleHousing a
JOIN PortfolioDataCleaning.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;


------------------------------------------------------------------------


-- Filling in the NULL values in PropertyAddress
UPDATE NashvilleHousing a, NashvilleHousing b 
	SET b.PropertyAddress = a.PropertyAddress
WHERE b.PropertyAddress IS NULL
	AND b.ParcelID = a.ParcelID
	AND a.PropertyAddress is not null;


------------------------------------------------------------------------


/*
This script doesn't work on MYSQL
UPDATE NashvilleHousing a, NashvilleHousing b
JOIN NashvilleHousing as b 
		ON a.ParcelID = b.ParcelID
		AND a.UniqueID = b.UniqueID
	SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;
*/

/*
SQL SERVER SYNTAX
-- FROM PortfolioDataCleaning.NashvilleHousing a
-- JOIN PortfolioDataCleaning.NashvilleHousing b
-- 	ON a.ParcelID = b.ParcelID
-- 	AND a.UniqueID <> b.UniqueID
*/


------------------------------------------------------------------------


-- Breaking the Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM PortfolioDataCleaning.NashvilleHousing
-- WHERE PropertyAddress <=> ''
-- ORDER BY ParcelID;

SELECT 
SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') -1 ) AS Address,
SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') +1 ) AS Address
FROM PortfolioDataCleaning.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, INSTR(PropertyAddress, ',') -1 );

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, INSTR(PropertyAddress, ',') +1 );


------------------------------------------------------------------------


-- SELECT OwnerAddress FROM PortfolioDataCleaning.NashvilleHousing
-- Breaking the OwnerAddress into Individual Columns (Address, City, State)
-- Updating the table to add the individual columns

SELECT 
SUBSTRING_INDEX(OwnerAddress,',', 1),
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2),',' , -1),
SUBSTRING_INDEX(OwnerAddress,',', -1)
FROM PortfolioDataCleaning.NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress,',', 1);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress,',', 2),',' , -1);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = SUBSTRING_INDEX(OwnerAddress,',', -1);

-- SELECT * FROM PortfolioDataCleaning.NashvilleHousing -- Viewing entire table


------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioDataCleaning.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2


SELECT SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END
FROM PortfolioDataCleaning.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        ELSE SoldAsVacant
        END
        
        
------------------------------------------------------------------------


-- Remove Duplicates

/* 

-- MS SQL SCRIPT TO REMOVE DUPLICATES USING CTE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
	)Row_Num
FROM PortfolioDataCleaning.NashvilleHousing
-- ORDER BY ParcelID
)
DELETE FROM RowNumCTE
WHERE Row_Num > 1
-- ORDER BY PropertyAddress

*/ 

-- MYSQL SCRIPT TO REMOVE DUPLICATES USING CTE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
                 SalePrice,
                 SaleDate,
                 LegalReference
                 ORDER BY UniqueID
	) AS Row_Num
FROM PortfolioDataCleaning.NashvilleHousing
)
DELETE nh
from NashvilleHousing nh INNER JOIN RowNumCTE r ON nh.UniqueID = r.UniqueID
where Row_Num > 1;


------------------------------------------------------------------------


-- Delete Ununsed Columns

SELECT * FROM PortfolioDataCleaning.NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, 
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict,
DROP COLUMN SaleDate;
