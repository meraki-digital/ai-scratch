/*
  Paginated User Query with Search Filter

  Usage:
    DECLARE @TotalCount INT;
    EXEC dbo.usp_GetUsers
        @PageNumber = 1,
        @PageSize = 20,
        @SearchTerm = 'john',
        @TotalCount = @TotalCount OUTPUT;
    SELECT @TotalCount AS TotalRecords;
*/

-- ============================================
-- GET USERS - Paginated with Search Filter
-- ============================================
CREATE OR ALTER PROCEDURE dbo.usp_GetUsers
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @SearchTerm NVARCHAR(100) = NULL,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate inputs
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize < 1 SET @PageSize = 20;
    IF @PageSize > 100 SET @PageSize = 100; -- Max page size

    -- Get total count for pagination metadata
    SELECT @TotalCount = COUNT(*)
    FROM Users
    WHERE @SearchTerm IS NULL
       OR FirstName LIKE '%' + @SearchTerm + '%'
       OR LastName LIKE '%' + @SearchTerm + '%'
       OR Email LIKE '%' + @SearchTerm + '%'
       OR Username LIKE '%' + @SearchTerm + '%';

    -- Get paged results
    SELECT
        UserId,
        Username,
        FirstName,
        LastName,
        Email,
        IsActive,
        CreatedAt,
        LastLoginAt
    FROM Users
    WHERE @SearchTerm IS NULL
       OR FirstName LIKE '%' + @SearchTerm + '%'
       OR LastName LIKE '%' + @SearchTerm + '%'
       OR Email LIKE '%' + @SearchTerm + '%'
       OR Username LIKE '%' + @SearchTerm + '%'
    ORDER BY LastName, FirstName
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO
