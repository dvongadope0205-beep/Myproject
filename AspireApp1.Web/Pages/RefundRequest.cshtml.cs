using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System.Security.Claims;

namespace WebApps.Pages
{
    [Authorize]
    public class RefundRequestModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public RefundRequestModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // User's completed orders eligible for refund
        public List<EligibleOrderDto> EligibleOrders { get; set; } = new();

        // User's existing refund requests
        public List<RefundDto> RefundHistory { get; set; } = new();

        // Refund reasons lookup
        public List<RefundReasonDto> RefundReasons { get; set; } = new();

        public string CustomerName { get; set; } = "";

        public class EligibleOrderDto
        {
            public int OrderId { get; set; }
            public string OrderType { get; set; }
            public string ItemName { get; set; }
            public decimal TotalAmount { get; set; }
            public string OrderDate { get; set; }
            public string TransactionRef { get; set; }
        }

        public class RefundDto
        {
            public int RefundId { get; set; }
            public int OrderId { get; set; }
            public string ItemName { get; set; }
            public decimal RefundAmount { get; set; }
            public decimal OriginalAmount { get; set; }
            public string RefundReason { get; set; }
            public string Status { get; set; }
            public string RequestedAt { get; set; }
            public string ProcessedAt { get; set; }
            public string AdminNotes { get; set; }
        }

        public class RefundReasonDto
        {
            public string ReasonCode { get; set; }
            public string ReasonLabel { get; set; }
        }

        public void OnGet()
        {
            string connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString)) return;

            string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            CustomerName = User.FindFirst(ClaimTypes.Name)?.Value ?? "";

            try
            {
                using (var conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    // Get UserId
                    int userId = 0;
                    using (var cmd = new SqlCommand("SELECT UserId FROM Users WHERE Email = @Email", conn))
                    {
                        cmd.Parameters.AddWithValue("@Email", userEmail);
                        var result = cmd.ExecuteScalar();
                        if (result != null) userId = (int)result;
                    }

                    if (userId == 0) return;

                    // Load eligible orders (Completed, not already refunded)
                    string orderSql = @"
                        SELECT o.OrderId, o.OrderType, 
                               ISNULL((SELECT TOP 1 oi.ItemName FROM OrderItems oi WHERE oi.OrderId = o.OrderId), 'Order #' + CAST(o.OrderId AS VARCHAR)),
                               o.TotalAmount, o.OrderDate, ISNULL(o.TransactionRef, '—')
                        FROM Orders o
                        WHERE o.UserId = @UserId 
                          AND o.PaymentStatus = 'Completed'
                          AND NOT EXISTS (SELECT 1 FROM Refunds r WHERE r.OrderId = o.OrderId AND r.Status IN ('Requested', 'Approved', 'Completed'))
                        ORDER BY o.OrderDate DESC";

                    using (var cmd = new SqlCommand(orderSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                EligibleOrders.Add(new EligibleOrderDto
                                {
                                    OrderId = reader.GetInt32(0),
                                    OrderType = reader.GetString(1),
                                    ItemName = reader.GetString(2),
                                    TotalAmount = reader.GetDecimal(3),
                                    OrderDate = reader.GetDateTime(4).ToString("dd/MM/yyyy"),
                                    TransactionRef = reader.GetString(5)
                                });
                            }
                        }
                    }

                    // Load refund history
                    string refundSql = @"
                        SELECT r.RefundId, r.OrderId,
                               ISNULL((SELECT TOP 1 oi.ItemName FROM OrderItems oi WHERE oi.OrderId = r.OrderId), 'Order #' + CAST(r.OrderId AS VARCHAR)),
                               r.RefundAmount, r.OriginalAmount,
                               ISNULL(rr.ReasonLabel, r.RefundReason),
                               r.Status, r.RequestedAt, r.ProcessedAt, ISNULL(r.AdminNotes, '')
                        FROM Refunds r
                        LEFT JOIN RefundReasons rr ON r.RefundReason = rr.ReasonCode
                        WHERE r.UserId = @UserId
                        ORDER BY r.RequestedAt DESC";

                    using (var cmd = new SqlCommand(refundSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RefundHistory.Add(new RefundDto
                                {
                                    RefundId = reader.GetInt32(0),
                                    OrderId = reader.GetInt32(1),
                                    ItemName = reader.GetString(2),
                                    RefundAmount = reader.GetDecimal(3),
                                    OriginalAmount = reader.GetDecimal(4),
                                    RefundReason = reader.GetString(5),
                                    Status = reader.GetString(6),
                                    RequestedAt = reader.GetDateTime(7).ToString("dd/MM/yyyy HH:mm"),
                                    ProcessedAt = reader.IsDBNull(8) ? "—" : reader.GetDateTime(8).ToString("dd/MM/yyyy HH:mm"),
                                    AdminNotes = reader.GetString(9)
                                });
                            }
                        }
                    }

                    // Load refund reasons
                    string reasonSql = "SELECT ReasonCode, ReasonLabel FROM RefundReasons WHERE IsActive = 1 ORDER BY SortOrder";
                    using (var cmd = new SqlCommand(reasonSql, conn))
                    {
                        using (var reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RefundReasons.Add(new RefundReasonDto
                                {
                                    ReasonCode = reader.GetString(0),
                                    ReasonLabel = reader.GetString(1)
                                });
                            }
                        }
                    }

                    // If no reasons in DB, add defaults
                    if (RefundReasons.Count == 0)
                    {
                        RefundReasons.Add(new RefundReasonDto { ReasonCode = "CHANGE_PLANS", ReasonLabel = "Change of Plans" });
                        RefundReasons.Add(new RefundReasonDto { ReasonCode = "WEATHER", ReasonLabel = "Weather Conditions" });
                        RefundReasons.Add(new RefundReasonDto { ReasonCode = "HEALTH", ReasonLabel = "Health / Medical Reasons" });
                        RefundReasons.Add(new RefundReasonDto { ReasonCode = "DUPLICATE", ReasonLabel = "Duplicate Purchase" });
                        RefundReasons.Add(new RefundReasonDto { ReasonCode = "OTHER", ReasonLabel = "Other" });
                    }
                }
            }
            catch (SqlException)
            {
                // Silently handle — page shows empty state
            }
        }

        // Submit refund request
        public async Task<IActionResult> OnPostSubmitRefundAsync()
        {
            var body = await ReadJsonBodyAsync<RefundSubmitData>();
            if (body == null)
                return new JsonResult(new { success = false, message = "Invalid data." });

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";

            if (string.IsNullOrEmpty(userEmail))
                return new JsonResult(new { success = false, message = "Not authenticated." });

            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Get UserId
                    int userId = 0;
                    using (var cmd = new SqlCommand("SELECT UserId FROM Users WHERE Email = @Email", conn))
                    {
                        cmd.Parameters.AddWithValue("@Email", userEmail);
                        var result = cmd.ExecuteScalar();
                        if (result != null) userId = (int)result;
                    }

                    if (userId == 0)
                        return new JsonResult(new { success = false, message = "User not found." });

                    // Verify order belongs to this user and is eligible
                    decimal originalAmount = 0;
                    using (var cmd = new SqlCommand(
                        @"SELECT TotalAmount FROM Orders 
                          WHERE OrderId = @OrderId AND UserId = @UserId AND PaymentStatus = 'Completed'
                          AND NOT EXISTS (SELECT 1 FROM Refunds r WHERE r.OrderId = @OrderId AND r.Status IN ('Requested','Approved','Completed'))", conn))
                    {
                        cmd.Parameters.AddWithValue("@OrderId", body.OrderId);
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        var result = cmd.ExecuteScalar();
                        if (result == null)
                            return new JsonResult(new { success = false, message = "Order not eligible for refund." });
                        originalAmount = (decimal)result;
                    }

                    // Insert refund request
                    string insertSql = @"
                        INSERT INTO Refunds (OrderId, UserId, RefundReason, ReasonDetail, RefundAmount, OriginalAmount, RefundPercent, Status, RequestedAt)
                        VALUES (@OrderId, @UserId, @Reason, @Detail, @OriginalAmount, @OriginalAmount, 100.00, 'Requested', GETDATE());
                        SELECT SCOPE_IDENTITY();";

                    int refundId = 0;
                    using (var cmd = new SqlCommand(insertSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@OrderId", body.OrderId);
                        cmd.Parameters.AddWithValue("@UserId", userId);
                        cmd.Parameters.AddWithValue("@Reason", body.ReasonCode ?? "OTHER");
                        cmd.Parameters.AddWithValue("@Detail", (object)body.ReasonDetail ?? DBNull.Value);
                        cmd.Parameters.AddWithValue("@OriginalAmount", originalAmount);
                        var result = cmd.ExecuteScalar();
                        if (result != null) refundId = Convert.ToInt32(result);
                    }

                    if (refundId > 0)
                    {
                        // Create notification for admin
                        try
                        {
                            using (var cmd = new SqlCommand(@"
                                INSERT INTO Notifications (RecipientRole, Title, Message, Type, ReferenceId, IconClass)
                                VALUES ('Admin', 'New Refund Request', 
                                        'A refund request has been submitted for Order #' + CAST(@OrderId AS VARCHAR), 
                                        'Refund', CAST(@RefundId AS VARCHAR), 'fa-undo')", conn))
                            {
                                cmd.Parameters.AddWithValue("@OrderId", body.OrderId);
                                cmd.Parameters.AddWithValue("@RefundId", refundId);
                                cmd.ExecuteNonQuery();
                            }
                        }
                        catch { /* notification failure is non-critical */ }

                        return new JsonResult(new { success = true, message = "Refund request submitted successfully! We'll review it within 3-5 business days." });
                    }

                    return new JsonResult(new { success = false, message = "Failed to submit refund request." });
                }
            }
            catch (Exception)
            {
                return new JsonResult(new { success = false, message = "An error occurred. Please try again." });
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

        public class RefundSubmitData
        {
            public int OrderId { get; set; }
            public string ReasonCode { get; set; }
            public string ReasonDetail { get; set; }
        }
    }
}
