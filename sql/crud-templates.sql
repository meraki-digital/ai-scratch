/*
  T-SQL Stored Procedure Templates
  Replace [TableName], [SchemaName], columns as needed
*/

-- ============================================
-- SELECT BY ID
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_GetById]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        CreatedAt,
        UpdatedAt
    FROM [SchemaName].[TableName]
    WHERE Id = @Id;
END
GO


-- ============================================
-- SELECT ALL (with optional filter)
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_GetAll]
    @IsActive BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Id,
        Name,
        IsActive,
        CreatedAt,
        UpdatedAt
    FROM [SchemaName].[TableName]
    WHERE (@IsActive IS NULL OR IsActive = @IsActive)
    ORDER BY Name;
END
GO


-- ============================================
-- SELECT WITH PAGINATION
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_GetPaged]
    @PageNumber INT = 1,
    @PageSize INT = 20,
    @SearchTerm NVARCHAR(100) = NULL,
    @TotalCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Get total count
    SELECT @TotalCount = COUNT(*)
    FROM [SchemaName].[TableName]
    WHERE @SearchTerm IS NULL OR Name LIKE '%' + @SearchTerm + '%';

    -- Get paged results
    SELECT
        Id,
        Name,
        CreatedAt,
        UpdatedAt
    FROM [SchemaName].[TableName]
    WHERE @SearchTerm IS NULL OR Name LIKE '%' + @SearchTerm + '%'
    ORDER BY Name
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END
GO


-- ============================================
-- INSERT (returns new ID)
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_Insert]
    @Name NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @CreatedBy INT,
    @NewId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO [SchemaName].[TableName] (
        Name,
        Description,
        CreatedAt,
        CreatedBy
    )
    VALUES (
        @Name,
        @Description,
        GETUTCDATE(),
        @CreatedBy
    );

    SET @NewId = SCOPE_IDENTITY();
END
GO


-- ============================================
-- UPDATE
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_Update]
    @Id INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @ModifiedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [SchemaName].[TableName]
    SET
        Name = @Name,
        Description = @Description,
        UpdatedAt = GETUTCDATE(),
        UpdatedBy = @ModifiedBy
    WHERE Id = @Id;

    -- Return rows affected (0 = not found)
    SELECT @@ROWCOUNT AS RowsAffected;
END
GO


-- ============================================
-- DELETE (hard delete)
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_Delete]
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM [SchemaName].[TableName]
    WHERE Id = @Id;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO


-- ============================================
-- SOFT DELETE (sets IsDeleted flag)
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_SoftDelete]
    @Id INT,
    @DeletedBy INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [SchemaName].[TableName]
    SET
        IsDeleted = 1,
        DeletedAt = GETUTCDATE(),
        DeletedBy = @DeletedBy
    WHERE Id = @Id
      AND IsDeleted = 0;

    SELECT @@ROWCOUNT AS RowsAffected;
END
GO


-- ============================================
-- UPSERT (Insert or Update)
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_Upsert]
    @Id INT = NULL,
    @Name NVARCHAR(100),
    @Description NVARCHAR(500) = NULL,
    @UserId INT,
    @ResultId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @Id IS NULL OR NOT EXISTS (SELECT 1 FROM [SchemaName].[TableName] WHERE Id = @Id)
    BEGIN
        -- Insert
        INSERT INTO [SchemaName].[TableName] (Name, Description, CreatedAt, CreatedBy)
        VALUES (@Name, @Description, GETUTCDATE(), @UserId);

        SET @ResultId = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        -- Update
        UPDATE [SchemaName].[TableName]
        SET
            Name = @Name,
            Description = @Description,
            UpdatedAt = GETUTCDATE(),
            UpdatedBy = @UserId
        WHERE Id = @Id;

        SET @ResultId = @Id;
    END
END
GO


-- ============================================
-- EXISTS CHECK
-- ============================================
CREATE OR ALTER PROCEDURE [SchemaName].[usp_TableName_Exists]
    @Id INT,
    @Exists BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM [SchemaName].[TableName] WHERE Id = @Id)
        SET @Exists = 1;
    ELSE
        SET @Exists = 0;
END
GO
