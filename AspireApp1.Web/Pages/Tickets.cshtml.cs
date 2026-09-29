using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Security.Claims;

namespace WebApps.Pages
{
    public class TicketsModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public TicketsModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public class EventDto
        {
            public int EventId { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public string EventDateStr { get; set; }
            public string EventDateUtc { get; set; }
            public decimal BasePrice { get; set; }
            public string ImageUrl { get; set; }
        }

        public List<EventDto> EventList { get; set; } = new List<EventDto>();

        public void OnGet()
        {
            string connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    string query = "SELECT EventId, Title, Description, EventDate, BasePrice, ImagePath FROM Events WHERE Status = 'Active' ORDER BY EventDate ASC";
                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    using (SqlDataReader reader = cmd.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var date = reader.GetDateTime(3);
                            var utcDate = DateTime.SpecifyKind(date, DateTimeKind.Utc);
                            var evt = new EventDto
                            {
                                EventId = reader.GetInt32(0),
                                Title = reader.GetString(1),
                                Description = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                BasePrice = reader.GetDecimal(4),
                                ImageUrl = reader.IsDBNull(5) ? "/Source/Picture/encounter.jpg" : reader.GetString(5),
                                EventDateStr = utcDate.ToString("yyyy-MM-dd"),
                                EventDateUtc = utcDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
                            };
                            if (string.IsNullOrEmpty(evt.ImageUrl)) evt.ImageUrl = "/Source/Picture/encounter.jpg";
                            EventList.Add(evt);
                        }
                    }
                }
            }
            catch (SqlException) { }
        }

                // ============================================================
        // DTOs for Payment
        // ============================================================
        public class CartItemDto
        {
            public string TicketType { get; set; }   // "Adult", "Child", "Senior"
            public int Quantity { get; set; }
            public decimal UnitPrice { get; set; }
        }

        public class ConfirmPaymentDto
        {
            public string TransactionRef { get; set; }
        }

        public class CheckoutRequestDto
        {
            public List<CartItemDto> CartItems { get; set; }
            public string PaymentMethod { get; set; }
            public string GuestName { get; set; }
            public string GuestEmail { get; set; }
            public string GuestPhone { get; set; }
            public string GuestAddress { get; set; }
        }

        // ============================================================
        // POST: InitPayment — Create Pending records, return QR info
        // ============================================================
        public async Task<IActionResult> OnPostInitPaymentAsync()
        {
            using var reader = new System.IO.StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            CheckoutRequestDto checkoutReq;
            try
            {
                checkoutReq = JsonSerializer.Deserialize<CheckoutRequestDto>(body, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
            }
            catch
            {
                return new JsonResult(new { success = false, message = "Invalid checkout data." });
            }

            if (checkoutReq == null || checkoutReq.CartItems == null || checkoutReq.CartItems.Count == 0)
                return new JsonResult(new { success = false, message = "Cart is empty." });

            string connectionString = _configuration.GetConnectionString("DefaultConnection");

            // Resolve customer info
            int? userId = null;
            string customerName = "";
            string customerEmail = "";
            string customerPhone = "";
            string customerAddress = "";

            bool isLoggedIn = User.Identity?.IsAuthenticated == true;
            if (isLoggedIn)
            {
                string loggedInName = User.FindFirst(ClaimTypes.Name)?.Value ?? User.Identity.Name;
                string userSql = "SELECT UserId, FullName, Email, Phone, Address FROM Users WHERE FullName = @Name OR Username = @Name";
                try
                {
                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        conn.Open();
                        using (SqlCommand userCmd = new SqlCommand(userSql, conn))
                        {
                            userCmd.Parameters.AddWithValue("@Name", loggedInName);
                            using (var r = userCmd.ExecuteReader())
                            {
                                if (r.Read())
                                {
                                    userId = r.GetInt32(0);
                                    customerName = r.IsDBNull(1) ? "" : r.GetString(1);
                                    customerEmail = r.IsDBNull(2) ? "" : r.GetString(2);
                                    customerPhone = r.IsDBNull(3) ? "" : r.GetString(3);
                                    customerAddress = r.IsDBNull(4) ? "" : r.GetString(4);
                                }
                            }
                        }
                    }
                }
                catch { }

                if (string.IsNullOrEmpty(customerName)) customerName = loggedInName;
                if (string.IsNullOrEmpty(customerEmail)) customerEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            }
            else
            {
                customerName = checkoutReq.GuestName ?? "Guest";
                customerEmail = checkoutReq.GuestEmail ?? "";
                customerPhone = checkoutReq.GuestPhone ?? "";
                customerAddress = checkoutReq.GuestAddress ?? "";
            }

            string paymentMethod = checkoutReq.PaymentMethod ?? "QR Code";
            string paymentStatus = "Pending";

            // Generate a collision-proof transaction reference using Guid
            string txRef = "TXN-" + DateTime.Now.ToString("yyyyMMdd") + "-" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    using var transaction = conn.BeginTransaction();

                    try
                    {
                        string orderType = "Ticket";

                        // Create a single Order
                        string createOrderSql = @"
                            INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
                            VALUES (@UserId, @OrderType, 0, @PaymentMethod, @PaymentStatus, @TxRef, @Notes, @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
                            SELECT SCOPE_IDENTITY();";

                        int orderId = 0;
                        using (SqlCommand orderCmd = new SqlCommand(createOrderSql, conn, transaction))
                        {
                            orderCmd.Parameters.AddWithValue("@UserId", userId.HasValue ? (object)userId.Value : DBNull.Value);
                            orderCmd.Parameters.AddWithValue("@OrderType", orderType);
                            orderCmd.Parameters.AddWithValue("@PaymentMethod", paymentMethod);
                            orderCmd.Parameters.AddWithValue("@PaymentStatus", paymentStatus);
                            orderCmd.Parameters.AddWithValue("@TxRef", txRef);
                            orderCmd.Parameters.AddWithValue("@Notes", customerName);
                            orderCmd.Parameters.AddWithValue("@CustomerName", string.IsNullOrEmpty(customerName) ? (object)DBNull.Value : customerName);
                            orderCmd.Parameters.AddWithValue("@CustomerEmail", string.IsNullOrEmpty(customerEmail) ? (object)DBNull.Value : customerEmail);
                            orderCmd.Parameters.AddWithValue("@CustomerPhone", string.IsNullOrEmpty(customerPhone) ? (object)DBNull.Value : customerPhone);
                            orderCmd.Parameters.AddWithValue("@CustomerAddress", string.IsNullOrEmpty(customerAddress) ? (object)DBNull.Value : customerAddress);
                            
                            var orderResult = orderCmd.ExecuteScalar();
                            if (orderResult != null) orderId = Convert.ToInt32(orderResult);
                        }

                        if (orderId == 0)
                        {
                            transaction.Rollback();
                            return new JsonResult(new { success = false, message = "Failed to create order." });
                        }

                        int totalInserted = 0;
                        decimal totalAmount = 0;

                        foreach (var item in checkoutReq.CartItems)
                        {
                            if (item.Quantity <= 0) continue;

                            // Get TicketTypeId
                            int ticketTypeId = 0;
                            string ttSql = "SELECT TicketTypeId FROM TicketTypes WHERE Name = @Name";
                            using (SqlCommand ttCmd = new SqlCommand(ttSql, conn, transaction))
                            {
                                ttCmd.Parameters.AddWithValue("@Name", item.TicketType);
                                var ttResult = ttCmd.ExecuteScalar();
                                if (ttResult != null) ticketTypeId = (int)ttResult;
                            }

                            if (ticketTypeId == 0) continue;

                            // INSERT OrderItem
                            string itemName = item.TicketType + " Ticket";
                            string insertItemSql = @"
                                INSERT INTO OrderItems (OrderId, ItemType, ItemName, TicketTypeId, Quantity, UnitPrice)
                                VALUES (@OrderId, 'Ticket', @ItemName, @TicketTypeId, @Quantity, @UnitPrice)";

                            using (SqlCommand cmd = new SqlCommand(insertItemSql, conn, transaction))
                            {
                                cmd.Parameters.AddWithValue("@OrderId", orderId);
                                cmd.Parameters.AddWithValue("@ItemName", itemName);
                                cmd.Parameters.AddWithValue("@TicketTypeId", ticketTypeId);
                                cmd.Parameters.AddWithValue("@Quantity", item.Quantity);
                                cmd.Parameters.AddWithValue("@UnitPrice", item.UnitPrice);

                                cmd.ExecuteNonQuery();
                                totalInserted++;
                                totalAmount += item.Quantity * item.UnitPrice;
                            }
                        }

                        // Update Order total
                        string updateTotalSql = "UPDATE Orders SET TotalAmount = @Total WHERE OrderId = @OrderId";
                        using (SqlCommand totalCmd = new SqlCommand(updateTotalSql, conn, transaction))
                        {
                            totalCmd.Parameters.AddWithValue("@Total", totalAmount);
                            totalCmd.Parameters.AddWithValue("@OrderId", orderId);
                            totalCmd.ExecuteNonQuery();
                        }

                        transaction.Commit();

                        return new JsonResult(new
                        {
                            success = true,
                            transactionRef = txRef,
                            totalAmount = totalAmount,
                            ticketCount = totalInserted,
                            customerName = customerName,
                            paymentMethod = paymentMethod,
                            message = $"Payment initiated. {totalInserted} ticket(s) pending."
                        });
                    }
                    catch
                    {
                        transaction.Rollback();
                        throw;
                    }
                }
            }
            catch (SqlException ex)
            {
                return new JsonResult(new { success = false, message = $"Unable to process payment: {ex.Message}" });
            }
        }

        // ============================================================
        // POST: ConfirmPayment — Update Pending → Completed
        // ============================================================
        public async Task<IActionResult> OnPostConfirmPaymentAsync()
        {
            using var reader = new System.IO.StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            ConfirmPaymentDto confirmData;
            try
            {
                confirmData = JsonSerializer.Deserialize<ConfirmPaymentDto>(body, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
            }
            catch
            {
                return new JsonResult(new { success = false, message = "Invalid payment data." });
            }

            if (confirmData == null || string.IsNullOrEmpty(confirmData.TransactionRef))
                return new JsonResult(new { success = false, message = "Transaction reference is required." });

            string connectionString = _configuration.GetConnectionString("DefaultConnection");

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();
                    using var transaction = conn.BeginTransaction();

                    try
                    {
                        // === CHECK QR SCAN ===
                        using (SqlCommand scanCheck = new SqlCommand("SELECT QRScannedAt FROM Orders WHERE TransactionRef = @TxRef AND PaymentStatus = 'Pending'", conn, transaction))
                        {
                            scanCheck.Parameters.AddWithValue("@TxRef", confirmData.TransactionRef);
                            var scanResult = scanCheck.ExecuteScalar();
                            if (scanResult == null || scanResult == DBNull.Value)
                            {
                                transaction.Rollback();
                                return new JsonResult(new { success = false, message = "QR chưa được quét. Vui lòng quét mã QR bằng ứng dụng ngân hàng trước.", notScanned = true });
                            }
                        }

                        // Update Orders: Pending → Completed
                        string updateSql = @"
                            UPDATE Orders 
                            SET PaymentStatus = 'Completed' 
                            WHERE TransactionRef = @TxRef AND PaymentStatus = 'Pending'";

                        int rowsUpdated = 0;
                        using (SqlCommand cmd = new SqlCommand(updateSql, conn, transaction))
                        {
                            cmd.Parameters.AddWithValue("@TxRef", confirmData.TransactionRef);
                            rowsUpdated = cmd.ExecuteNonQuery();
                        }

                        if (rowsUpdated == 0)
                        {
                            transaction.Rollback();
                            return new JsonResult(new { success = false, message = "No pending payment found for this transaction." });
                        }

                        // PaymentLog is auto-created by trigger trg_Orders_AutoPaymentLog
                        // Update any existing pending PaymentLog entries
                        string logUpdateSql = @"
                            UPDATE PaymentLog 
                            SET Status = 'Success', Notes = ISNULL(Notes, '') + ' | QR Payment confirmed at ' + CONVERT(VARCHAR, GETDATE(), 120)
                            WHERE TransactionRef = @TxRef AND Status = 'Pending'";

                        using (SqlCommand logCmd = new SqlCommand(logUpdateSql, conn, transaction))
                        {
                            logCmd.Parameters.AddWithValue("@TxRef", confirmData.TransactionRef);
                            logCmd.ExecuteNonQuery();
                        }

                        // === Create Notifications ===
                        string customerName = "Guest";
                        string customerEmail = "";
                        string orderInfoSql = "SELECT CustomerName, CustomerEmail FROM Orders WHERE TransactionRef = @TxRef";
                        using (SqlCommand orderInfoCmd = new SqlCommand(orderInfoSql, conn, transaction))
                        {
                            orderInfoCmd.Parameters.AddWithValue("@TxRef", confirmData.TransactionRef);
                            using (var r = orderInfoCmd.ExecuteReader())
                            {
                                if (r.Read())
                                {
                                    customerName = r.IsDBNull(0) ? "Guest" : r.GetString(0);
                                    customerEmail = r.IsDBNull(1) ? "" : r.GetString(1);
                                }
                            }
                        }


                        // Notification for Admin
                        string adminNotifSql = @"INSERT INTO Notifications 
                            (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                            VALUES ('Admin', NULL, @Title, @Msg, 'Ticket', @Ref, 'fa-ticket')";
                        using (SqlCommand adminCmd = new SqlCommand(adminNotifSql, conn, transaction))
                        {
                            adminCmd.Parameters.AddWithValue("@Title", $"New Ticket Purchase: {confirmData.TransactionRef}");
                            adminCmd.Parameters.AddWithValue("@Msg", $"{customerName} purchased {rowsUpdated} ticket(s) - Ref: {confirmData.TransactionRef}");
                            adminCmd.Parameters.AddWithValue("@Ref", confirmData.TransactionRef);
                            adminCmd.ExecuteNonQuery();
                        }

                        // Notification for Customer
                        if (!string.IsNullOrEmpty(customerEmail))
                        {
                            string userNotifSql = @"INSERT INTO Notifications 
                                (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                                VALUES ('User', @Email, @Title, @Msg, 'Ticket', @Ref, 'fa-check-circle')";
                            using (SqlCommand userCmd = new SqlCommand(userNotifSql, conn, transaction))
                            {
                                userCmd.Parameters.AddWithValue("@Email", customerEmail);
                                userCmd.Parameters.AddWithValue("@Title", "Order Confirmed!");
                                userCmd.Parameters.AddWithValue("@Msg", $"Your order {confirmData.TransactionRef} with {rowsUpdated} ticket(s) has been confirmed.");
                                userCmd.Parameters.AddWithValue("@Ref", confirmData.TransactionRef);
                                userCmd.ExecuteNonQuery();
                            }
                        }

                        transaction.Commit();

                        return new JsonResult(new
                        {
                            success = true,
                            message = $"Payment confirmed! {rowsUpdated} ticket(s) successfully purchased.",
                            ticketsConfirmed = rowsUpdated
                        });
                    }
                    catch
                    {
                        transaction.Rollback();
                        throw;
                    }
                }
            }
            catch (SqlException ex)
            {
                return new JsonResult(new { success = false, message = $"Unable to confirm payment: {ex.Message}" });
            }
        }
    }
}