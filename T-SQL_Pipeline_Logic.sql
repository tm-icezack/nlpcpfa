-- =============================================
-- SCD TYPE 2 | Asset Register
-- Step 1: Expire changed rows
-- Step 2: Insert new + updated rows
-- =============================================

DECLARE @Today DATE = CAST(GETDATE() AS DATE);

-- =============================================
-- STEP 1: EXPIRE rows that have changed
-- Close the old version by setting EffectiveTo
-- and flipping IsCurrent to 0
-- =============================================

UPDATE dim_Asset
SET
    EffectiveTo = DATEADD(DAY, -1, @Today),  -- Expires yesterday
    IsCurrent   = 0
FROM dim_Asset d
INNER JOIN stg_Asset s ON s.AssetCode = d.AssetCode
WHERE d.IsCurrent = 1  -- Only touch the active row
  AND (                -- Only if something actually changed
        s.AssetName    <> d.AssetName   OR
        s.Category     <> d.Category    OR
        s.Location     <> d.Location    OR
        s.CostCentre   <> d.CostCentre  OR
        s.AssetStatus  <> d.AssetStatus
      );

-- =============================================
-- STEP 2: INSERT new rows + new versions
-- This covers brand-new assets AND
-- updated versions of changed assets
-- =============================================

INSERT INTO dim_Asset (
    AssetCode, AssetName, Category,
    Location, CostCentre, AssetStatus,
    EffectiveFrom, EffectiveTo, IsCurrent
)
SELECT
    s.AssetCode,
    s.AssetName,
    s.Category,
    s.Location,
    s.CostCentre,
    s.AssetStatus,
    @Today,  -- Starts today
    NULL,    -- NULL = still active, no end date yet
    1        -- IsCurrent = true
FROM stg_Asset s
LEFT JOIN dim_Asset d
    ON  s.AssetCode = d.AssetCode
    AND d.IsCurrent = 1
WHERE
    -- Brand new asset (never seen before)
    d.AssetCode IS NULL
    OR
    -- Changed asset (we just expired it above, so IsCurrent is now 0)
    (d.IsCurrent = 0 AND d.EffectiveTo = DATEADD(DAY, -1, @Today));