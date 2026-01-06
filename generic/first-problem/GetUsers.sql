CREATE OR ALTER PROCEDURE [dbo].[GetUsers]
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @Search NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        UserId,
        Username,
        Email,
        DisplayName,
        CreatedAt
    FROM dbo.Users
    WHERE
        @Search IS NULL
        OR Username LIKE '%' + @Search + '%'
        OR Email LIKE '%' + @Search + '%'
        OR DisplayName LIKE '%' + @Search + '%'
    ORDER BY UserId
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;

    -- Return total count for pagination UI
    SELECT COUNT(*) AS TotalCount
    FROM dbo.Users
    WHERE
        @Search IS NULL
        OR Username LIKE '%' + @Search + '%'
        OR Email LIKE '%' + @Search + '%'
        OR DisplayName LIKE '%' + @Search + '%';
END
