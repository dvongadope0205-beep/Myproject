using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using System.Security.Claims;

namespace WebApps.Pages
{
    public class JoinModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public JoinModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public class MembershipCartDto
        {
            public string MembershipName { get; set; }
            public decimal Price { get; set; }
            public string StartDate { get; set; } // yyyy-MM-dd
        }

        public class ConfirmPaymentDto
        {
            public string TransactionRef { get; set; }
        }

        public void OnGet() { }

        // ============================================================
        // POST: InitMembershipPayment
        // ============================================================
        public async Task<IActionResult> OnPostInitMembershipPaymentAsync()
        {
            using var reader = new System.IO.StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            MembershipCartDto item;
            try { item = JsonSerializer.Deserialize<MembershipCartDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }); }
            catch { return new JsonResult(new { success = false, message = "Invalid data." }); }

            if (item == null || string.IsNullOrEmpty(item.MembershipName))
                return new JsonResult(new { success = false, message = "Please select a membership." });

            string customerName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Guest";
            string customerEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            string txRef = "TXN-MEM-" + DateTime.Now.ToString("yyyyMMdd") + "-" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using var tx = conn.BeginTransaction();
                    try
                    {
                        int? userId = null;
                        using (SqlCommand cmd = new SqlCommand("SELECT UserId FROM Users WHERE Email = @Email OR Username = @Name OR FullName = @Name", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Email", customerEmail);
                            cmd.Parameters.AddWithValue("@Name", customerName);
                            var r = cmd.ExecuteScalar();
                            if (r != null) userId = (int)r;
                        }

                        // Find MembershipTypeId - try LIKE match first, then fallback to default
                        int memTypeId = 0;
                        using (SqlCommand cmd = new SqlCommand("SELECT TOP 1 MembershipTypeId FROM MembershipTypes WHERE Name LIKE '%' + @Name + '%'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Name", item.MembershipName);
                            var r = cmd.ExecuteScalar();
                            if (r != null) memTypeId = (int)r;
                        }
                        // Fallback: if no match found, use the first available MembershipType
                        if (memTypeId == 0)
                        {
                            using (SqlCommand cmd = new SqlCommand("SELECT TOP 1 MembershipTypeId FROM MembershipTypes ORDER BY MembershipTypeId", conn, tx))
                            {
                                var r = cmd.ExecuteScalar();
                                if (r != null) memTypeId = (int)r;
                            }
                        }

                        // Create Order
                        string orderSql = @"INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes)
                                            VALUES (@UserId, 'Membership', @Total, 'QR Code', 'Pending', @TxRef, @Notes);
                                            SELECT SCOPE_IDENTITY();";
                        int orderId = 0;
                        using (SqlCommand cmd = new SqlCommand(orderSql, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@UserId", userId.HasValue ? (object)userId.Value : DBNull.Value);
                            cmd.Parameters.AddWithValue("@Total", item.Price);
                            cmd.Parameters.AddWithValue("@TxRef", txRef);
                            cmd.Parameters.AddWithValue("@Notes", $"{item.MembershipName} - {customerName}");
                            var r = cmd.ExecuteScalar();
                            if (r != null) orderId = Convert.ToInt32(r);
                        }

                        if (orderId == 0) { tx.Rollback(); return new JsonResult(new { success = false, message = "Failed to create order." }); }

                        // Insert OrderItem
                        string itemSql = @"INSERT INTO OrderItems (OrderId, ItemType, ItemName, MembershipTypeId, Quantity, UnitPrice, VisitDate)
                                           VALUES (@OrderId, 'Membership', @ItemName, @MemTypeId, 1, @Price, @StartDate)";
                        using (SqlCommand cmd = new SqlCommand(itemSql, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@OrderId", orderId);
                            cmd.Parameters.AddWithValue("@ItemName", item.MembershipName);
                            cmd.Parameters.AddWithValue("@MemTypeId", memTypeId > 0 ? (object)memTypeId : DBNull.Value);
                            cmd.Parameters.AddWithValue("@Price", item.Price);
                            DateTime startDate = DateTime.TryParse(item.StartDate, out var dt) ? dt : DateTime.Today;
                            if (startDate < DateTime.Today)
                            {
                                tx.Rollback();
                                return new JsonResult(new { success = false, message = "Membership start date cannot be in the past." });
                            }
                            cmd.Parameters.AddWithValue("@StartDate", startDate);
                            cmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                        return new JsonResult(new { success = true, transactionRef = txRef, totalAmount = item.Price, ticketCount = 1, customerName });
                    }
                    catch { tx.Rollback(); throw; }
                }
            }
            catch (SqlException ex) { return new JsonResult(new { success = false, message = $"Error: {ex.Message}" }); }
        }

        // ============================================================
        // POST: ConfirmMembershipPayment
        // ============================================================
        public async Task<IActionResult> OnPostConfirmMembershipPaymentAsync()
        {
            using var reader = new System.IO.StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            ConfirmPaymentDto data;
            try { data = JsonSerializer.Deserialize<ConfirmPaymentDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }); }
            catch { return new JsonResult(new { success = false, message = "Invalid data." }); }

            if (data == null || string.IsNullOrEmpty(data.TransactionRef))
                return new JsonResult(new { success = false, message = "Transaction ref required." });

            string connStr = _configuration.GetConnectionString("DefaultConnection");

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using var tx = conn.BeginTransaction();
                    try
                    {
                        // === AUTO COMPLETE - No QR scan check needed ===

                        // Update Order status
                        int rows = 0;
                        using (SqlCommand cmd = new SqlCommand("UPDATE Orders SET PaymentStatus = 'Completed' WHERE TransactionRef = @Ref AND PaymentStatus = 'Pending'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            rows = cmd.ExecuteNonQuery();
                        }

                        if (rows == 0) { tx.Rollback(); return new JsonResult(new { success = false, message = "No pending payment found." }); }

                        // Get order details for notifications
                        string customerName = User.FindFirst(ClaimTypes.Name)?.Value ?? "Guest";
                        string customerEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
                        decimal totalAmount = 0;
                        string memName = "";
                        using (SqlCommand cmd = new SqlCommand(@"SELECT o.TotalAmount, oi.ItemName FROM Orders o 
                            INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId 
                            WHERE o.TransactionRef = @Ref", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            using var r = cmd.ExecuteReader();
                            if (r.Read()) { totalAmount = r.GetDecimal(0); memName = r.GetString(1); }
                        }

                        // Activate membership for user (Status = 'Active', NOT IsActive)
                        // Handle case where MembershipTypeId might be NULL by using fallback
                        string memSql = @"INSERT INTO UserMemberships (UserId, MembershipTypeId, OrderId, StartDate, EndDate, Status)
                                          SELECT o.UserId, 
                                                 ISNULL(oi.MembershipTypeId, (SELECT TOP 1 MembershipTypeId FROM MembershipTypes)), 
                                                 o.OrderId,
                                                 ISNULL(oi.VisitDate, GETDATE()), 
                                                 DATEADD(YEAR, 1, ISNULL(oi.VisitDate, GETDATE())), 
                                                 'Active'
                                          FROM Orders o
                                          INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
                                          WHERE o.TransactionRef = @Ref AND oi.ItemType = 'Membership'";
                        using (SqlCommand cmd = new SqlCommand(memSql, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            cmd.ExecuteNonQuery();
                        }

                        // Update PaymentLog
                        using (SqlCommand cmd = new SqlCommand("UPDATE PaymentLog SET Status = 'Success' WHERE TransactionRef = @Ref AND Status = 'Pending'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            cmd.ExecuteNonQuery();
                        }

                        // === Notifications ===
                        // Admin notification
                        using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Notifications 
                            (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                            VALUES ('Admin', NULL, @Title, @Msg, 'Membership', @Ref, 'fa-id-card')", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Title", $"New Membership: {data.TransactionRef}");
                            cmd.Parameters.AddWithValue("@Msg", $"{customerName} purchased {memName} (${totalAmount:F2}) - Ref: {data.TransactionRef}");
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            cmd.ExecuteNonQuery();
                        }
                        // User notification
                        if (!string.IsNullOrEmpty(customerEmail))
                        {
                            using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Notifications 
                                (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                                VALUES ('User', @Email, @Title, @Msg, 'Membership', @Ref, 'fa-check-circle')", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@Email", customerEmail);
                                cmd.Parameters.AddWithValue("@Title", "Membership Activated!");
                                cmd.Parameters.AddWithValue("@Msg", $"Your {memName} membership is now active. Ref: {data.TransactionRef}");
                                cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tx.Commit();
                        return new JsonResult(new { success = true, message = "Membership activated! Welcome aboard.", ticketsConfirmed = 1 });
                    }
                    catch { tx.Rollback(); throw; }
                }
            }
            catch (SqlException ex) { return new JsonResult(new { success = false, message = $"Error: {ex.Message}" }); }
        }
    }
}
