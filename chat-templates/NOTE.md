## Chat Templates

```sql
CREATE TABLE dbo.chat_templates (
    template_id INT IDENTITY(1,1) PRIMARY KEY,
    template_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    is_active BIT NOT NULL DEFAULT 1,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
```

## Template → Groups

```sql
CREATE TABLE dbo.chat_template_groups (
    template_group_id INT IDENTITY(1,1) PRIMARY KEY,
    template_id INT NOT NULL,
    group_id INT NOT NULL,
);

CREATE UNIQUE INDEX UX_chat_template_groups_unique
ON dbo.chat_template_groups (template_id, group_id);
```

## Template → Individual Users

```sql
CREATE TABLE dbo.chat_template_users (
    template_user_id INT IDENTITY(1,1) PRIMARY KEY,
    template_id INT NOT NULL,
    user_id INT NOT NULL,

    CONSTRAINT FK_chat_template_users_template
        FOREIGN KEY (template_id)
        REFERENCES dbo.chat_templates (template_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_chat_template_users_user
        FOREIGN KEY (user_id)
        REFERENCES dbo.users (user_id)
);

CREATE UNIQUE INDEX UX_chat_template_users_unique
ON dbo.chat_template_users (template_id, user_id);

```

## Example: Create a Template

```sql
INSERT INTO dbo.chat_templates (template_name, description)
VALUES ('Submitter + Travel Services', 'Default case discussion chat');

-- Add group
INSERT INTO dbo.chat_template_groups (template_id, group_id)
VALUES (1, 3);

-- Add specific user
INSERT INTO dbo.chat_template_users (template_id, user_id)
VALUES (1, 1005);

```

## Add to Chat Creation Proc: Expand Template → Chat Members

This handles:

- users directly on the template
- users in template groups
- deduplication

```sql
INSERT INTO dbo.chat_members (chat_id, user_id, added_by_user_id)
SELECT DISTINCT
    @chat_id,
    users.user_id,
    @admin_user_id
FROM (
    -- Users directly on template
    SELECT tu.user_id
    FROM dbo.chat_template_users tu
    WHERE tu.template_id = @template_id

    UNION

    -- Users from template groups
    SELECT ugm.user_id
    FROM dbo.chat_template_groups tg
    JOIN dbo.user_group_members ugm
        ON ugm.group_id = tg.group_id
    WHERE tg.template_id = @template_id
) users
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.chat_members cm
    WHERE cm.chat_id = @chat_id
      AND cm.user_id = users.user_id
);
```
