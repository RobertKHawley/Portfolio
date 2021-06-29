-----------------
-- SELECT Data --
-----------------

Select *
FROM HousingProject.dbo.NashvilleHousing


---------------------------
-- Standardize sale date --
---------------------------

-- Can remove time part of date (all are 00:00:00) using convert
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM HousingProject.dbo.NashvilleHousing

-- Add converted column
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

-- Add data to new column
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate)


------------------------------------
-- Populate Property Address Data --
------------------------------------

-- Found that rows that share parcel IDs always share the same property address
SELECT *
FROM HousingProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID

-- Can fill in empty property address fields by using shared parcel IDs
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
, ISNULL(a.PropertyAddress, b.PropertyAddress) AS NewPropertyAddress
FROM HousingProject.dbo.NashvilleHousing a
JOIN HousingProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Update table using above query
UPDATE a
SET a.PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProject.dbo.NashvilleHousing a
JOIN HousingProject.dbo.NashvilleHousing b
    ON a.ParcelID = b.ParcelID
    AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


-------------------------------------------------------------------------
-- Breaking out address into individual columns (Address, City, State) --
-------------------------------------------------------------------------

-- First, the property address contains the street address and city

-- Found comma is a delimiter for seperating address, city and state
SELECT PropertyAddress
FROM HousingProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
--ORDER BY ParcelID

-- Select address before delimiter, select city after delimiter
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(', ', PropertyAddress) - 1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(', ', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM HousingProject.dbo.NashvilleHousing

-- Create new columns for property street address and property city
ALTER TABLE NashvilleHousing
ADD PropertyStreetAddress NVARCHAR(255)
, PropertyCity NVARCHAR(255);

-- Add data to new columns

UPDATE NashvilleHousing
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(', ', PropertyAddress) - 1)
, PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(', ', PropertyAddress) + 1, LEN(PropertyAddress))


-- Second, the owner address contains the street address, city and state

-- Comma is also the delimiter here
SELECT OwnerAddress
FROM HousingProject.dbo.NashvilleHousing

-- Using PARSENAME this time
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM HousingProject.dbo.NashvilleHousing

-- Create new columns for owner street address, owner city and owner state
ALTER TABLE NashvilleHousing
ADD OwnerStreetAddress NVARCHAR(255)
, OwnerCity NVARCHAR(255)
, OwnerState NVARCHAR(255);

-- Add data to new columns
UPDATE NashvilleHousing
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
, OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
, OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


----------------------------------------------------------
-- Change Y and N to Yes and No in 'SoldAsVacant' field --
----------------------------------------------------------

-- There are 4 distinct entries: N, Yes, Y, No
-- Y and N are the minority (i.e. not standard)
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS Count
FROM HousingProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

-- Use case statement to correct non-standardized entries
SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END
FROM HousingProject.dbo.NashvilleHousing

-- Update table
UPDATE NashvilleHousing
SET SoldAsVacant = 
    CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
         WHEN SoldAsVacant = 'N' THEN 'No'
         ELSE SoldAsVacant
         END


-----------------------
-- Remove duplicates --
-----------------------

-- Duplicates have a row number > 1
WITH CTE AS (
SELECT *
, ROW_NUMBER() OVER (
    PARTITION BY ParcelID
               , PropertyAddress
               , SalePrice
               , SaleDate
               , LegalReference
        ORDER BY UniqueID) row_num
FROM HousingProject.dbo.NashvilleHousing
)
DELETE FROM CTE
WHERE row_num > 1


---------------------------
-- Delete unused columns --
---------------------------

ALTER TABLE HousingProject.dbo.NashvilleHousing
DROP COLUMN SaleDate, PropertyAddress, OwnerAddress
