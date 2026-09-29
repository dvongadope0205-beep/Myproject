using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace WebProject.Pages
{
    public class CheckoutModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public CheckoutModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string UserFullName { get; set; } = "";
        public string UserEmail { get; set; } = "";
        public string UserPhone { get; set; } = "";
        public string UserAddress { get; set; } = "";

        public void OnGet()
        {
            if (User.Identity?.IsAuthenticated == true)
            {
                string userFullName = User.FindFirst(ClaimTypes.Name)?.Value ?? "";
                string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";

                string connStr = _configuration.GetConnectionString("DefaultConnection");
                if (!string.IsNullOrEmpty(connStr))
                {
                    try
                    {
                        using (var conn = new SqlConnection(connStr))
                        {
                            conn.Open();
                            string sql = "SELECT FullName, Email, Phone, Address FROM Users WHERE FullName = @FullName OR Email = @Email OR Username = @FullName";
                            using (var cmd = new SqlCommand(sql, conn))
                            {
                                cmd.Parameters.AddWithValue("@FullName", userFullName);
                                cmd.Parameters.AddWithValue("@Email", string.IsNullOrEmpty(userEmail) ? (object)DBNull.Value : userEmail);
                                using (var reader = cmd.ExecuteReader())
                                {
                                    if (reader.Read())
                                    {
                                        UserFullName = reader.IsDBNull(0) ? userFullName : reader.GetString(0);
                                        UserEmail = reader.IsDBNull(1) ? userEmail : reader.GetString(1);
                                        UserPhone = reader.IsDBNull(2) ? "" : reader.GetString(2);
                                        UserAddress = reader.IsDBNull(3) ? "" : reader.GetString(3);
                                    }
                                    else
                                    {
                                        UserFullName = userFullName;
                                        UserEmail = userEmail;
                                    }
                                }
                            }
                        }
                    }
                    catch
                    {
                        UserFullName = userFullName;
                        UserEmail = userEmail;
                    }
                }
            }
        }

        public async Task<IActionResult> OnPostPlaceOrderAsync([FromBody] OrderInputModel input)
        {
            if (input == null)
            {
                return new JsonResult(new { success = false, message = "Invalid order data." });
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr))
            {
                return new JsonResult(new { success = false, message = "Database connection error." });
            }

            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Get UserId if authenticated
                    int? userId = null;
                    if (User.Identity?.IsAuthenticated == true)
                    {
                        string userEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
                        string userFullName = User.FindFirst(ClaimTypes.Name)?.Value ?? "";
                        using (var cmd = new SqlCommand("SELECT UserId FROM Users WHERE Email = @Email OR Username = @Name OR FullName = @Name", conn))
                        {
                            cmd.Parameters.AddWithValue("@Email", userEmail);
                            cmd.Parameters.AddWithValue("@Name", userFullName);
                            var res = cmd.ExecuteScalar();
                            if (res != null) userId = (int)res;
                        }
                    }

                    using (var tx = conn.BeginTransaction())
                    {
                        try
                        {
                            // Insert into Orders with dedicated customer columns
                            string orderSql = @"
                                INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, OrderDate,
                                                    CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
                                VALUES (@UserId, 'Shop', @TotalAmount, @PaymentMethod, @PaymentStatus, @TransactionRef, @Notes, GETDATE(),
                                        @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
                                SELECT SCOPE_IDENTITY();";

                            int orderId = 0;
                            using (var cmd = new SqlCommand(orderSql, conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@UserId", userId.HasValue ? (object)userId.Value : DBNull.Value);
                                cmd.Parameters.AddWithValue("@TotalAmount", input.TotalAmount);
                                cmd.Parameters.AddWithValue("@PaymentMethod", input.PaymentMethod);
                                cmd.Parameters.AddWithValue("@PaymentStatus", input.PaymentStatus); // "Pending" or "Completed"
                                cmd.Parameters.AddWithValue("@TransactionRef", input.TransactionRef ?? "");
                                cmd.Parameters.AddWithValue("@Notes", $"Recipient: {input.FullName}, Phone: {input.Phone}, Address: {input.Address}");
                                cmd.Parameters.AddWithValue("@CustomerName", input.FullName ?? "");
                                cmd.Parameters.AddWithValue("@CustomerEmail", input.Email ?? "");
                                cmd.Parameters.AddWithValue("@CustomerPhone", input.Phone ?? "");
                                cmd.Parameters.AddWithValue("@CustomerAddress", input.Address ?? "");
                                
                                var res = cmd.ExecuteScalar();
                                if (res != null) orderId = Convert.ToInt32(res);
                            }

                            // Insert into OrderItems
                            if (input.Items != null)
                            {
                                foreach (var item in input.Items)
                                {
                                    string itemSql = @"
                                        INSERT INTO OrderItems (OrderId, ItemType, ItemName, Quantity, UnitPrice)
                                        VALUES (@OrderId, 'Shop', @ItemName, @Quantity, @UnitPrice)";
                                    using (var cmd = new SqlCommand(itemSql, conn, tx))
                                    {
                                        cmd.Parameters.AddWithValue("@OrderId", orderId);
                                        cmd.Parameters.AddWithValue("@ItemName", item.Name ?? "");
                                        cmd.Parameters.AddWithValue("@Quantity", item.Qty);
                                        cmd.Parameters.AddWithValue("@UnitPrice", item.Price);
                                        cmd.ExecuteNonQuery();
                                    }
                                }
                            }

                            tx.Commit();
                            return new JsonResult(new { success = true, orderId = orderId });
                        }
                        catch (Exception ex)
                        {
                            tx.Rollback();
                            return new JsonResult(new { success = false, message = "Transaction error: " + ex.Message });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                return new JsonResult(new { success = false, message = "Database error: " + ex.Message });
            }
        }
    }

    public class OrderInputModel
    {
        public string FullName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Phone { get; set; } = "";
        public string Address { get; set; } = "";
        public decimal TotalAmount { get; set; }
        public string PaymentMethod { get; set; } = "";
        public string PaymentStatus { get; set; } = "";
        public string TransactionRef { get; set; } = "";
        public List<OrderItemInputModel>? Items { get; set; }
    }

    public class OrderItemInputModel
    {
        public string Name { get; set; } = "";
        public int Qty { get; set; }
        public decimal Price { get; set; }
    }
}
