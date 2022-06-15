CREATE PROCEDURE [dbo].[RebuildFragmentedIndexes] (@FragmentationLimit float = 80.0)
AS
BEGIN
  -- Code moved to [Core] schema
  -- This procedure should no longer be used, it's only there for backward compatability


  EXEC [Core].[RebuildFragmentedIndexes] @FragmentationLimit
END

