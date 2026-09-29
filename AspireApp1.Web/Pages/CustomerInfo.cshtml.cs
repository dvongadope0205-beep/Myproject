using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Claims;

namespace WebApps.Pages
{
    [Authorize]
    public class CustomerInfoModel : PageModel
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _env;

        public CustomerInfoModel(IConfiguration configuration, IWebHostEnvironment env)
        {
            _configuration = configuration;
            _env = env;
        }

        // Customer Profile
        public string CustomerName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Phone { get; set; } = "";
        public string Address { get; set; } = "";
        public string Gender { get; set; } = "";
        public string DateOfBirth { get; set; } = "";
        public string MemberSince { get; set; } = "";
        public string Username { get; set; } = "";
        public string RoleName { get; set; } = "";
        public string AvatarUrl { get; set; } = "";

        // Flag: profile incomplete → show popup
        public bool ShowProfilePopup { get; set; } = false;


        // Stats
        public int TotalTransactions { get; set; }
        public decimal TotalSpent { get; set; }
        public int TotalTicketsBought { get; set; }

        // Purchase History
        public List<PurchaseHistoryDto> PurchaseHistory { get; set; } = new();

        // Refunds Info
        public decimal TotalRefundedAmount { get; set; }
        public List<RefundDto> RefundedOrders { get; set; } = new();

        public class RefundDto
        {
            public int RefundId { get; set; }
            public int OrderId { get; set; }
            public decimal Amount { get; set; }
            public string Type { get; set; } = "";
            public string Status { get; set; } = "";
            public string RequestedAt { get; set; } = "";
            public string CompletedAt { get; set; } = "";
            public string TransactionRef { get; set; } = "";
        }

        // Membership Info
        public MembershipDto? ActiveMembership { get; set; }

        public class PurchaseHistoryDto
        {
            public int ProceedId { get; set; }
            public string EventTitle { get; set; } = "";
            public string TicketType { get; set; } = "";
            public int Quantity { get; set; }
            public decimal UnitPrice { get; set; }
            public decimal TotalAmount { get; set; }
            public string PurchaseDate { get; set; } = "";
            public string PaymentMethod { get; set; } = "";
            public string PaymentStatus { get; set; } = "";
            public string TransactionRef { get; set; } = "";
        }

        public class MembershipDto
        {
            public string MembershipType { get; set; } = "";
            public string StartDate { get; set; } = "";
            public string EndDate { get; set; } = "";
            public string Status { get; set; } = "";
            public string Benefits { get; set; } = "";
        }

        public void OnGet()
        {
            string connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString)) return;

            string userFullName = User.FindFirst(ClaimTypes.Name)?.Value ?? "";
            string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            int userId = 0;

            string logPath = @"C:\WEBDEV\AspireApp1\debug.txt";
            try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] OnGet called. userFullName='{userFullName}', userEmail='{userEmail}'\n"); } catch {}

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    // 1. Load User Profile (Users table)
                    string customerQuery = @"
                        SELECT u.UserId, u.FullName, u.Email, u.Phone, u.Address, 
                               u.Gender, u.DateOfBirth, u.Username, u.CreatedAt, r.RoleName,
                               (SELECT COUNT(*) FROM Orders o WHERE o.UserId = u.UserId) AS TotalTx,
                               (SELECT ISNULL(SUM(o.TotalAmount), 0) FROM Orders o WHERE o.UserId = u.UserId AND o.PaymentStatus = 'Completed') AS TotalSpent,
                               (SELECT ISNULL(SUM(oi.Quantity), 0) FROM OrderItems oi INNER JOIN Orders o ON oi.OrderId = o.OrderId WHERE o.UserId = u.UserId AND o.PaymentStatus = 'Completed') AS TicketsBought,
                               u.AvatarPath
                        FROM Users u
                        LEFT JOIN Roles r ON u.RoleId = r.RoleId
                        WHERE u.FullName = @FullName OR u.Email = @Email";

                    using (SqlCommand cmd = new SqlCommand(customerQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@FullName", userFullName);
                        cmd.Parameters.AddWithValue("@Email", string.IsNullOrEmpty(userEmail) ? (object)DBNull.Value : userEmail);

                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                userId = reader.GetInt32(0);
                                try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] Resolved userId={userId}\n"); } catch {}
                                CustomerName = reader.IsDBNull(1) ? userFullName : reader.GetString(1);
                                Email = reader.IsDBNull(2) ? userEmail : reader.GetString(2);
                                Phone = reader.IsDBNull(3) ? "" : reader.GetString(3);
                                Address = reader.IsDBNull(4) ? "" : reader.GetString(4);
                                Gender = reader.IsDBNull(5) ? "" : reader.GetString(5);
                                DateOfBirth = reader.IsDBNull(6) ? "" : reader.GetDateTime(6).ToString("yyyy-MM-dd");
                                Username = reader.IsDBNull(7) ? "" : reader.GetString(7);
                                MemberSince = reader.IsDBNull(8) ? "—" : reader.GetDateTime(8).ToString("dd/MM/yyyy");
                                RoleName = reader.IsDBNull(9) ? "Customer" : reader.GetString(9);
                                TotalTransactions = reader.IsDBNull(10) ? 0 : reader.GetInt32(10);
                                TotalSpent = reader.IsDBNull(11) ? 0 : reader.GetDecimal(11);
                                TotalTicketsBought = reader.IsDBNull(12) ? 0 : reader.GetInt32(12);
                                AvatarUrl = reader.IsDBNull(13) ? "" : reader.GetString(13);

                                // Check if profile is incomplete → show popup
                                if (string.IsNullOrEmpty(Phone) || string.IsNullOrEmpty(Address) || string.IsNullOrEmpty(Gender) || string.IsNullOrEmpty(DateOfBirth))
                                {
                                    ShowProfilePopup = true;
                                }
                            }
                            else
                            {
                                CustomerName = userFullName;
                                Email = userEmail;
                                RoleName = User.FindFirst(ClaimTypes.Role)?.Value ?? "Customer";
                                ShowProfilePopup = true;
                            }
                        }
                    }

                    // 2. Load Completed Refunds for User
                    if (userId > 0)
                    {
                        try
                        {
                            string refundSumQuery = "SELECT ISNULL(SUM(RefundAmount), 0) FROM Refunds WHERE UserId = @UserId AND Status = 'Completed'";
                            using (SqlCommand cmd = new SqlCommand(refundSumQuery, conn))
                            {
                                cmd.Parameters.AddWithValue("@UserId", userId);
                                TotalRefundedAmount = (decimal)cmd.ExecuteScalar();
                            }

                            string refundListQuery = @"
                                SELECT RefundId, OrderId, RefundAmount, RefundReason, Status, RequestedAt, CompletedAt, TransactionRef
                                FROM Refunds
                                WHERE UserId = @UserId AND Status = 'Completed'
                                ORDER BY CompletedAt DESC";
                            using (SqlCommand cmd = new SqlCommand(refundListQuery, conn))
                            {
                                cmd.Parameters.AddWithValue("@UserId", userId);
                                using (SqlDataReader rdr = cmd.ExecuteReader())
                                {
                                    while (rdr.Read())
                                    {
                                        RefundedOrders.Add(new RefundDto
                                        {
                                            RefundId = rdr.GetInt32(0),
                                            OrderId = rdr.IsDBNull(1) ? 0 : rdr.GetInt32(1),
                                            Amount = rdr.GetDecimal(2),
                                            Type = rdr.IsDBNull(3) ? "" : rdr.GetString(3),
                                            Status = rdr.IsDBNull(4) ? "" : rdr.GetString(4),
                                            RequestedAt = rdr.IsDBNull(5) ? "—" : rdr.GetDateTime(5).ToString("dd/MM/yyyy HH:mm"),
                                            CompletedAt = rdr.IsDBNull(6) ? "—" : rdr.GetDateTime(6).ToString("dd/MM/yyyy HH:mm"),
                                            TransactionRef = rdr.IsDBNull(7) ? "—" : rdr.GetString(7)
                                        });
                                    }
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] Refunds load exception: {ex.Message}\n"); } catch {}
                        }
                    }

                    // 3. Load Active Membership
                    if (userId > 0)
                    {

                        try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] Querying active membership for userId={userId}\n"); } catch {}
                        string memberQuery = @"
                            SELECT mt.Name, um.StartDate, um.EndDate, um.Status, mt.Benefits
                            FROM UserMemberships um
                            INNER JOIN MembershipTypes mt ON um.MembershipTypeId = mt.MembershipTypeId
                            WHERE um.UserId = @UserId AND um.Status = 'Active'
                            ORDER BY um.EndDate DESC";

                        try
                        {
                            using (SqlCommand cmd = new SqlCommand(memberQuery, conn))
                            {
                                cmd.Parameters.AddWithValue("@UserId", userId);

                                using (SqlDataReader reader = cmd.ExecuteReader())
                                {
                                    if (reader.Read())
                                    {
                                        ActiveMembership = new MembershipDto
                                        {
                                            MembershipType = reader.GetString(0),
                                            StartDate = reader.GetDateTime(1).ToString("dd/MM/yyyy"),
                                            EndDate = reader.GetDateTime(2).ToString("dd/MM/yyyy"),
                                            Status = reader.GetString(3),
                                            Benefits = reader.IsDBNull(4) ? "" : reader.GetString(4)
                                        };

                                        try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] Found active membership: {ActiveMembership.MembershipType}\n"); } catch {}
                                    }
                                    else
                                    {

                                        try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] No active membership row found.\n"); } catch {}
                                    }
                                }
                            }
                        }
                        catch (Exception ex)
                        {

                            try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] Query exception: {ex.Message}\n"); } catch {}
                        }
                    }
                    else
                    {

                        try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] UserId is <= 0\n"); } catch {}
                    }
                }
            }
            catch (SqlException ex)
            {
                CustomerName = userFullName;
                Email = userEmail;
                RoleName = User.FindFirst(ClaimTypes.Role)?.Value ?? "Customer";
                try { System.IO.File.AppendAllText(logPath, $"[{DateTime.Now}] Outer SqlException caught: {ex.Message}\n"); } catch {}
            }
        }

        // ============================================================
        // UPDATE PROFILE (popup form)
        // ============================================================
        public async Task<IActionResult> OnPostUpdateProfileAsync()
        {
            var body = await ReadJsonBodyAsync<ProfileUpdateData>();
            if (body == null)
                return new JsonResult(new { success = false, message = "Invalid data." });

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            if (string.IsNullOrEmpty(userEmail))
                return new JsonResult(new { success = false, message = "User not authenticated." });

            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"UPDATE Users SET 
                        FullName = @FullName,
                        Phone = @Phone, 
                        Address = @Address, 
                        Gender = @Gender, 
                        DateOfBirth = @DOB 
                        WHERE Email = @Email";
                    using (var cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@FullName", string.IsNullOrEmpty(body.FullName) ? DBNull.Value : (object)body.FullName);
                        cmd.Parameters.AddWithValue("@Phone", (object)body.Phone ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@Address", (object)body.Address ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@Gender", (object)body.Gender ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@DOB", string.IsNullOrEmpty(body.DateOfBirth) ? DBNull.Value : (object)DateTime.Parse(body.DateOfBirth));
                        cmd.Parameters.AddWithValue("@Email", userEmail);
                        int rows = cmd.ExecuteNonQuery();
                        if (rows > 0)
                            return new JsonResult(new { success = true, message = "Profile updated!" });
                        else
                            return new JsonResult(new { success = false, message = "User not found." });
                    }
                }
            }
            catch (Exception ex)
            {
                return new JsonResult(new { success = false, message = "Error: " + ex.Message });
            }
        }

        // ============================================================
        // UPLOAD AVATAR
        // ============================================================
        public async Task<IActionResult> OnPostUploadAvatarAsync(IFormFile avatarFile)
        {
            if (avatarFile == null || avatarFile.Length == 0)
                return new JsonResult(new { success = false, message = "No file selected." });

            // Validate file type
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
            var ext = Path.GetExtension(avatarFile.FileName).ToLowerInvariant();
            if (!allowed.Contains(ext))
                return new JsonResult(new { success = false, message = "Only JPG, PNG, GIF, WebP files are allowed." });

            // Validate size (max 5MB)
            if (avatarFile.Length > 5 * 1024 * 1024)
                return new JsonResult(new { success = false, message = "File too large. Max 5MB." });

            string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            if (string.IsNullOrEmpty(userEmail))
                return new JsonResult(new { success = false, message = "User not authenticated." });

            try
            {
                // Create uploads directory
                string uploadsDir = Path.Combine(_env.WebRootPath, "uploads", "avatars");
                Directory.CreateDirectory(uploadsDir);

                // Generate unique filename
                string fileName = $"avatar_{Guid.NewGuid():N}{ext}";
                string filePath = Path.Combine(uploadsDir, fileName);
                string relativeUrl = $"/uploads/avatars/{fileName}";

                // Save file
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await avatarFile.CopyToAsync(stream);
                }

                // Update database
                string connStr = _configuration.GetConnectionString("DefaultConnection");
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Get old avatar to delete
                    string oldAvatar = "";
                    using (var cmd = new SqlCommand("SELECT AvatarPath FROM Users WHERE Email = @Email", conn))
                    {
                        cmd.Parameters.AddWithValue("@Email", userEmail);
                        var result = cmd.ExecuteScalar();
                        if (result != null && result != DBNull.Value) oldAvatar = result.ToString();
                    }

                    // Update AvatarPath
                    using (var cmd = new SqlCommand("UPDATE Users SET AvatarPath = @Path WHERE Email = @Email", conn))
                    {
                        cmd.Parameters.AddWithValue("@Path", relativeUrl);
                        cmd.Parameters.AddWithValue("@Email", userEmail);
                        cmd.ExecuteNonQuery();
                    }

                    // Log to avatar history
                    using (var cmd = new SqlCommand(@"INSERT INTO UserAvatarHistory (UserId, AvatarPath, UploadedAt)
                        SELECT UserId, @NewPath, GETDATE() FROM Users WHERE Email = @Email", conn))
                    {
                        cmd.Parameters.AddWithValue("@NewPath", relativeUrl);
                        cmd.Parameters.AddWithValue("@Email", userEmail);
                        cmd.ExecuteNonQuery();
                    }

                    // Delete old avatar file
                    if (!string.IsNullOrEmpty(oldAvatar))
                    {
                        string oldFilePath = Path.Combine(_env.WebRootPath, oldAvatar.TrimStart('/'));
                        if (System.IO.File.Exists(oldFilePath))
                            System.IO.File.Delete(oldFilePath);
                    }
                }

                return new JsonResult(new { success = true, message = "Avatar updated!", avatarUrl = relativeUrl });
            }
            catch (Exception ex)
            {
                return new JsonResult(new { success = false, message = "Error: " + ex.Message });
            }
        }

        // JSON body reader helper
        private async Task<T?> ReadJsonBodyAsync<T>()
        {
            try
            {
                using var reader = new StreamReader(Request.Body);
                string body = await reader.ReadToEndAsync();
                return System.Text.Json.JsonSerializer.Deserialize<T>(body, new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            }
            catch { return default; }
        }

        public class ProfileUpdateData
        {
            public string? FullName { get; set; }
            public string? Phone { get; set; }
            public string? Address { get; set; }
            public string? Gender { get; set; }
            public string? DateOfBirth { get; set; }
        }
    }
}
