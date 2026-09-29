-- ============================================================
-- 20_ForgotPassword.sql
-- Thêm các cột cho tính năng Quên mật khẩu
-- ============================================================

USE [ZooDatabase]
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ResetToken')
BEGIN
    ALTER TABLE Users ADD ResetToken NVARCHAR(100) NULL;
    PRINT N'✅ Đã thêm cột ResetToken vào Users';
END

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Users') AND name = 'ResetTokenExpiry')
BEGIN
    ALTER TABLE Users ADD ResetTokenExpiry DATETIME NULL;
    PRINT N'✅ Đã thêm cột ResetTokenExpiry vào Users';
END
GO
