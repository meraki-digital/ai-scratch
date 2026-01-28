Awesome — this is a solid design choice. Below is something you can pretty much drop straight into an `.md` file and ship. I’ll keep it clear, structured, and example-heavy.

---

# Case Chat User & Group Model (MSSQL)

This design supports:

- Multiple chats per case
- Explicit user membership per chat
- Predefined user groups for bulk-adding users to chats
- Clean auditing and predictable permissions

Groups are used **only as a convenience** when adding users and do not themselves grant chat access.

---

## 1. Case Chats

Each case can have one or more chats. A “Submitter Chat” is created automatically on case creation.

```sql
CREATE TABLE dbo.case_chats (
    chat_id INT IDENTITY(1,1) PRIMARY KEY,
    case_id INT NOT NULL,
    chat_name VARCHAR(100) NOT NULL,
    is_submitter_chat BIT NOT NULL DEFAULT 0,
    created_by_user_id INT NOT NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_case_chats_case
        FOREIGN KEY (case_id)
        REFERENCES dbo.cases (case_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_case_chats_created_by
        FOREIGN KEY (created_by_user_id)
        REFERENCES dbo.users (user_id)
);
```

---

## 2. Chat Members

This table explicitly controls **who can see and participate in a chat**.

```sql
CREATE TABLE dbo.chat_members (
    chat_member_id INT IDENTITY(1,1) PRIMARY KEY,
    chat_id INT NOT NULL,
    user_id INT NOT NULL,
    added_by_user_id INT NOT NULL,
    added_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT FK_chat_members_chat
        FOREIGN KEY (chat_id)
        REFERENCES dbo.case_chats (chat_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_chat_members_user
        FOREIGN KEY (user_id)
        REFERENCES dbo.users (user_id),

    CONSTRAINT FK_chat_members_added_by
        FOREIGN KEY (added_by_user_id)
        REFERENCES dbo.users (user_id)
);
```

Prevent duplicate membership:

```sql
CREATE UNIQUE INDEX UX_chat_members_unique
ON dbo.chat_members (chat_id, user_id);
```

---

## 3. User Groups (Predefined Sets)

User groups are global and managed by admins.

```sql
CREATE TABLE dbo.user_groups (
    group_id INT IDENTITY(1,1) PRIMARY KEY,
    group_name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255) NULL,
    is_active BIT NOT NULL DEFAULT 1
);
```

Example seed data:

```sql
INSERT INTO dbo.user_groups (group_name, description)
VALUES
    ('Travel Services', 'Travel services support staff'),
    ('Finance', 'Finance department'),
    ('Executives', 'Executive leadership');
```

---

## 4. User Group Members

Defines which users belong to which group.

```sql
CREATE TABLE dbo.user_group_members (
    group_member_id INT IDENTITY(1,1) PRIMARY KEY,
    group_id INT NOT NULL,
    user_id INT NOT NULL,

    CONSTRAINT FK_user_group_members_group
        FOREIGN KEY (group_id)
        REFERENCES dbo.user_groups (group_id)
        ON DELETE CASCADE,

    CONSTRAINT FK_user_group_members_user
        FOREIGN KEY (user_id)
        REFERENCES dbo.users (user_id)
);
```

Prevent duplicates:

```sql
CREATE UNIQUE INDEX UX_user_group_members_unique
ON dbo.user_group_members (group_id, user_id);
```

---

## Example Usage

### Create a Submitter Chat on Case Creation

```sql
INSERT INTO dbo.case_chats (case_id, chat_name, is_submitter_chat, created_by_user_id)
VALUES (42, 'Submitter Chat', 1, @requestor_user_id);
```

---

### Add a Single User to a Chat

```sql
INSERT INTO dbo.chat_members (chat_id, user_id, added_by_user_id)
VALUES (12, 1001, @admin_user_id);
```

---

### Add an Entire Group to a Chat

This expands the group into individual users and adds them explicitly.

```sql
INSERT INTO dbo.chat_members (chat_id, user_id, added_by_user_id)
SELECT
    @chat_id,
    ugm.user_id,
    @admin_user_id
FROM dbo.user_group_members ugm
WHERE ugm.group_id = @group_id
AND NOT EXISTS (
    SELECT 1
    FROM dbo.chat_members cm
    WHERE cm.chat_id = @chat_id
      AND cm.user_id = ugm.user_id
);
```

---

### Get All Users in a Chat

```sql
SELECT u.user_id, u.name
FROM dbo.chat_members cm
JOIN dbo.users u ON u.user_id = cm.user_id
WHERE cm.chat_id = @chat_id;
```

---

### Get All Chats a User Can See for a Case

```sql
SELECT cc.chat_id, cc.chat_name
FROM dbo.case_chats cc
JOIN dbo.chat_members cm ON cm.chat_id = cc.chat_id
WHERE cc.case_id = @case_id
  AND cm.user_id = @user_id;
```

---

## Design Notes

- Chat access is **explicit and auditable**
- Groups are **selection shortcuts**, not permission holders
- Removing a user from a group does **not** retroactively remove chat access
- All authorization checks are simple joins
