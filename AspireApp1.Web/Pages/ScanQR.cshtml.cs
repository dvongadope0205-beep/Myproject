using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace WebApps.Pages
{
    public class ScanQRModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ScanQRModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string TransactionRef { get; set; }
        public string Status { get; set; } // "success", "already", "notfound", "error"
        public string Message { get; set; }
        public decimal Amount { get; set; }
        public string OrderType { get; set; }

        /// <summary>
        /// GET /ScanQR?r=TXN-xxx → Quét QR → hoàn thành thanh toán luôn
        /// </summary>
        public void OnGet(string r)
        {
            TransactionRef = r ?? "";
            if (string.IsNullOrEmpty(TransactionRef))
            {
                Status = "notfound";
                Message = "No transaction reference provided.";
                return;
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using var tx = conn.BeginTransaction();

                    try
                    {
                        // Check if order exists
                        string checkSql = @"SELECT PaymentStatus, TotalAmount, OrderType, QRScannedAt 
                                            FROM Orders WHERE TransactionRef = @Ref";
                        string paymentStatus = null;
                        DateTime? scannedAt = null;

                        using (SqlCommand cmd = new SqlCommand(checkSql, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                            using (var reader = cmd.ExecuteReader())
                            {
                                if (reader.Read())
                                {
                                    paymentStatus = reader.GetString(0);
                                    Amount = reader.GetDecimal(1);
                                    OrderType = reader.IsDBNull(2) ? "" : reader.GetString(2);
                                    scannedAt = reader.IsDBNull(3) ? null : reader.GetDateTime(3);
                                }
                            }
                        }

                        if (paymentStatus == null)
                        {
                            tx.Rollback();
                            Status = "notfound";
                            Message = "Transaction not found.";
                            return;
                        }

                        if (paymentStatus == "Completed")
                        {
                            tx.Rollback();
                            Status = "already";
                            Message = "This payment has already been completed.";
                            return;
                        }

                        // === MARK AS SCANNED + COMPLETE PAYMENT ===
                        // 1. Update order status
                        using (SqlCommand cmd = new SqlCommand(
                            "UPDATE Orders SET PaymentStatus = 'Completed', QRScannedAt = GETDATE() WHERE TransactionRef = @Ref AND PaymentStatus = 'Pending'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                            int rows = cmd.ExecuteNonQuery();
                            if (rows == 0) { tx.Rollback(); Status = "error"; Message = "Could not update order."; return; }
                        }

                        // 2. Handle order-type specific logic
                        switch (OrderType)
                        {
                            case "Shop":
                                // Reduce stock
                                using (SqlCommand cmd = new SqlCommand(@"UPDATE sp SET sp.StockQuantity = sp.StockQuantity - oi.Quantity
                                    FROM ShopProducts sp
                                    INNER JOIN OrderItems oi ON sp.ProductId = oi.ProductId
                                    INNER JOIN Orders o ON oi.OrderId = o.OrderId
                                    WHERE o.TransactionRef = @Ref AND oi.ItemType = 'Shop'", conn, tx))
                                {
                                    cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                                    cmd.ExecuteNonQuery();
                                }
                                break;

                            case "Event":
                                // Decrease event capacity
                                using (SqlCommand cmd = new SqlCommand(@"UPDATE e SET e.Capacity = e.Capacity - oi.Quantity
                                    FROM Events e
                                    INNER JOIN OrderItems oi ON e.EventId = oi.EventId
                                    INNER JOIN Orders o ON oi.OrderId = o.OrderId
                                    WHERE o.TransactionRef = @Ref AND oi.ItemType = 'Event'", conn, tx))
                                {
                                    cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                                    cmd.ExecuteNonQuery();
                                }
                                break;

                            case "Membership":
                                // Activate membership — look up MembershipTypeId by name if NULL
                                using (SqlCommand cmd = new SqlCommand(@"
                                    INSERT INTO UserMemberships (UserId, MembershipTypeId, OrderId, StartDate, EndDate, Status)
                                    SELECT o.UserId, 
                                           COALESCE(oi.MembershipTypeId, mt.MembershipTypeId),
                                           o.OrderId,
                                           ISNULL(oi.VisitDate, GETDATE()), 
                                           DATEADD(YEAR, 1, ISNULL(oi.VisitDate, GETDATE())), 
                                           'Active'
                                    FROM Orders o
                                    INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
                                    LEFT JOIN MembershipTypes mt ON mt.Name LIKE '%' + oi.ItemName + '%'
                                    WHERE o.TransactionRef = @Ref AND oi.ItemType = 'Membership'", conn, tx))
                                {
                                    cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                                    cmd.ExecuteNonQuery();
                                }
                                break;
                        }

                        // 3. Update PaymentLog
                        using (SqlCommand cmd = new SqlCommand("UPDATE PaymentLog SET Status = 'Success' WHERE TransactionRef = @Ref AND Status = 'Pending'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                            cmd.ExecuteNonQuery();
                        }

                        // 4. Get customer info for notifications
                        string custName = ""; string custEmail = ""; string itemName = "";
                        using (SqlCommand cmd = new SqlCommand(@"SELECT u.FullName, u.Email, oi.ItemName 
                            FROM Orders o 
                            LEFT JOIN Users u ON o.UserId = u.UserId
                            INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId
                            WHERE o.TransactionRef = @Ref", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                            using var reader = cmd.ExecuteReader();
                            if (reader.Read())
                            {
                                custName = reader.IsDBNull(0) ? "Guest" : reader.GetString(0);
                                custEmail = reader.IsDBNull(1) ? "" : reader.GetString(1);
                                itemName = reader.IsDBNull(2) ? "" : reader.GetString(2);
                            }
                        }

                        // 5. Admin notification
                        string notifType = OrderType ?? "Ticket";
                        string iconClass = notifType switch
                        {
                            "Shop" => "fa-shopping-cart",
                            "Membership" => "fa-id-card",
                            "Event" => "fa-calendar",
                            _ => "fa-ticket"
                        };
                        using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Notifications 
                            (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                            VALUES ('Admin', NULL, @Title, @Msg, @Type, @Ref, @Icon)", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Title", $"New {notifType}: {TransactionRef}");
                            cmd.Parameters.AddWithValue("@Msg", $"{custName} - {itemName} (${Amount:F2}) - Ref: {TransactionRef}");
                            cmd.Parameters.AddWithValue("@Type", notifType);
                            cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                            cmd.Parameters.AddWithValue("@Icon", iconClass);
                            cmd.ExecuteNonQuery();
                        }

                        // 6. User notification
                        if (!string.IsNullOrEmpty(custEmail))
                        {
                            using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Notifications 
                                (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                                VALUES ('User', @Email, @Title, @Msg, @Type, @Ref, 'fa-check-circle')", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@Email", custEmail);
                                cmd.Parameters.AddWithValue("@Title", "Payment Successful!");
                                cmd.Parameters.AddWithValue("@Msg", $"Your {notifType.ToLower()} order (${Amount:F2}) confirmed. Ref: {TransactionRef}");
                                cmd.Parameters.AddWithValue("@Type", notifType);
                                cmd.Parameters.AddWithValue("@Ref", TransactionRef);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tx.Commit();
                        Status = "success";
                        Message = "Payment completed successfully!";
                    }
                    catch
                    {
                        tx.Rollback();
                        throw;
                    }
                }
            }
            catch (SqlException ex)
            {
                Status = "error";
                Message = $"System error: {ex.Message}";
            }
        }

        /// <summary>
        /// GET /ScanQR?handler=CheckStatus&r=TXN-xxx → Polling endpoint
        /// </summary>
        public IActionResult OnGetCheckStatus(string r)
        {
            if (string.IsNullOrEmpty(r))
                return new JsonResult(new { completed = false });

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("SELECT PaymentStatus FROM Orders WHERE TransactionRef = @Ref", conn))
                    {
                        cmd.Parameters.AddWithValue("@Ref", r);
                        var result = cmd.ExecuteScalar();
                        if (result != null && result.ToString() == "Completed")
                        {
                            return new JsonResult(new { completed = true, message = "Payment completed successfully!" });
                        }
                    }
                }
            }
            catch { }

            return new JsonResult(new { completed = false });
        }
    }
}
