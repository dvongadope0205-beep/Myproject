using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Claims;
using System.Threading.Tasks;

namespace WebApps.Pages.Shopnew
{
    [Authorize]
    public class ShopInfoModel : PageModel
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _env;

        public ShopInfoModel(IConfiguration configuration, IWebHostEnvironment env)
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

        // Statistics
        public int TotalShopPurchases { get; set; }
        public int TotalMembershipPurchases { get; set; }

        // Purchases lists for the info boxes
        public List<ShopPurchaseDto> ShopPurchases { get; set; } = new();
        public List<MemberPurchaseDto> MemberPurchases { get; set; } = new();

        public class ShopPurchaseDto
        {
            public int OrderId { get; set; }
            public string ItemName { get; set; }
            public decimal TotalAmount { get; set; }
            public string OrderDate { get; set; }
            public string Status { get; set; }
            public string TransactionRef { get; set; }
        }

        public class MemberPurchaseDto
        {
            public int OrderId { get; set; }
            public string MembershipType { get; set; }
            public decimal TotalAmount { get; set; }
            public string PurchaseDate { get; set; }
            public string Status { get; set; }
        }

        public void OnGet()
        {
            string connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString)) return;

            string userFullName = User.FindFirst(ClaimTypes.Name)?.Value ?? "";
            string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    // 1. Load User Profile
                    string customerQuery = @"
                        SELECT u.UserId, u.FullName, u.Email, u.Phone, u.Address, 
                               u.Gender, u.DateOfBirth, u.Username, u.CreatedAt, r.RoleName,
                               u.AvatarPath
                        FROM Users u
                        LEFT JOIN Roles r ON u.RoleId = r.RoleId
                        WHERE u.FullName = @FullName OR u.Email = @Email";

                    int userId = 0;
                    using (SqlCommand cmd = new SqlCommand(customerQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@FullName", userFullName);
                        cmd.Parameters.AddWithValue("@Email", string.IsNullOrEmpty(userEmail) ? (object)DBNull.Value : userEmail);

                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                userId = reader.GetInt32(0);
                                CustomerName = reader.IsDBNull(1) ? userFullName : reader.GetString(1);
                                Email = reader.IsDBNull(2) ? userEmail : reader.GetString(2);
                                Phone = reader.IsDBNull(3) ? "" : reader.GetString(3);
                                Address = reader.IsDBNull(4) ? "" : reader.GetString(4);
                                Gender = reader.IsDBNull(5) ? "" : reader.GetString(5);
                                DateOfBirth = reader.IsDBNull(6) ? "" : reader.GetDateTime(6).ToString("yyyy-MM-dd");
                                Username = reader.IsDBNull(7) ? "" : reader.GetString(7);
                                MemberSince = reader.IsDBNull(8) ? "—" : reader.GetDateTime(8).ToString("dd/MM/yyyy");
                                RoleName = reader.IsDBNull(9) ? "Customer" : reader.GetString(9);
                                AvatarUrl = reader.IsDBNull(10) ? "" : reader.GetString(10);
                            }
                            else
                            {
                                CustomerName = userFullName;
                                Email = userEmail;
                                RoleName = User.FindFirst(ClaimTypes.Role)?.Value ?? "Customer";
                            }
                        }
                    }

                    if (userId == 0) return;

                    // 2. Load Shop Purchases (OrderType = 'Shop')
                    string shopQuery = @"
                        SELECT o.OrderId, 
                               ISNULL((SELECT TOP 1 oi.ItemName FROM OrderItems oi WHERE oi.OrderId = o.OrderId), 'Shop Purchase') AS ItemName,
                               o.TotalAmount, o.OrderDate, o.PaymentStatus, ISNULL(o.TransactionRef, '—')
                        FROM Orders o
                        WHERE o.UserId = @UserId AND o.OrderType = 'Shop'
                        ORDER BY o.OrderDate DESC";

                    using (SqlCommand cmd = new SqlCommand(shopQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                ShopPurchases.Add(new ShopPurchaseDto
                                {
                                    OrderId = reader.GetInt32(0),
                                    ItemName = reader.GetString(1),
                                    TotalAmount = reader.GetDecimal(2),
                                    OrderDate = reader.GetDateTime(3).ToString("dd/MM/yyyy HH:mm"),
                                    Status = reader.GetString(4),
                                    TransactionRef = reader.GetString(5)
                                });
                            }
                        }
                    }
                    TotalShopPurchases = ShopPurchases.Count;

                    // 3. Load Membership Purchases (OrderType = 'Membership')
                    string memberQuery = @"
                        SELECT o.OrderId, 
                               ISNULL((SELECT TOP 1 oi.ItemName FROM OrderItems oi WHERE oi.OrderId = o.OrderId), 'Membership Signup') AS MembershipType,
                               o.TotalAmount, o.OrderDate, o.PaymentStatus
                        FROM Orders o
                        WHERE o.UserId = @UserId AND o.OrderType = 'Membership'
                        ORDER BY o.OrderDate DESC";

                    using (SqlCommand cmd = new SqlCommand(memberQuery, conn))
                    {
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                MemberPurchases.Add(new MemberPurchaseDto
                                {
                                    OrderId = reader.GetInt32(0),
                                    MembershipType = reader.GetString(1),
                                    TotalAmount = reader.GetDecimal(2),
                                    PurchaseDate = reader.GetDateTime(3).ToString("dd/MM/yyyy HH:mm"),
                                    Status = reader.GetString(4)
                                });
                            }
                        }
                    }
                    TotalMembershipPurchases = MemberPurchases.Count;
                }
            }
            catch (SqlException)
            {
                CustomerName = userFullName;
                Email = userEmail;
                RoleName = User.FindFirst(ClaimTypes.Role)?.Value ?? "Customer";
            }
        }

        // Update Profile logic (copied from CustomerInfo.cshtml.cs)
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
                            return new JsonResult(new { success = true, message = "Profile updated successfully!" });
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

        private async Task<T> ReadJsonBodyAsync<T>()
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
