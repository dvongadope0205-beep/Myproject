using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Security.Claims;

namespace WebProject.Pages
{
    [Authorize]
    public class ShopPurchaseHistoryModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ShopPurchaseHistoryModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public List<OrderHistoryDto> TicketPurchases { get; set; } = new();
        public List<OrderHistoryDto> MembershipPurchases { get; set; } = new();
        public List<OrderHistoryDto> ShopPurchases { get; set; } = new();

        [BindProperty(SupportsGet = true)]
        public string Tab { get; set; } = "tickets"; // default active tab

        public class OrderHistoryDto
        {
            public int OrderId { get; set; }
            public string ItemName { get; set; } = "";
            public string OrderType { get; set; } = "";
            public int Quantity { get; set; }
            public decimal UnitPrice { get; set; }
            public decimal TotalAmount { get; set; }
            public string OrderDate { get; set; } = "";
            public string PaymentMethod { get; set; } = "";
            public string PaymentStatus { get; set; } = "";
            public string TransactionRef { get; set; } = "";
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

                    string query = @"
                        SELECT o.OrderId, o.OrderType,
                               ISNULL(oi.ItemName, 'Order #' + CAST(o.OrderId AS VARCHAR)) AS ItemName,
                               ISNULL(oi.Quantity, 1) AS Quantity,
                               ISNULL(oi.UnitPrice, o.TotalAmount) AS UnitPrice,
                               o.TotalAmount, o.OrderDate, o.PaymentMethod, o.PaymentStatus, 
                               ISNULL(o.TransactionRef, '—') AS TransactionRef
                        FROM Orders o
                        LEFT JOIN OrderItems oi ON o.OrderId = oi.OrderId
                        LEFT JOIN Users u ON o.UserId = u.UserId
                        WHERE u.FullName = @FullName OR u.Email = @Email OR u.Username = @FullName
                        ORDER BY o.OrderDate DESC";

                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@FullName", userFullName);
                        cmd.Parameters.AddWithValue("@Email", string.IsNullOrEmpty(userEmail) ? (object)DBNull.Value : userEmail);

                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var type = reader.GetString(1);
                                var item = new OrderHistoryDto
                                {
                                    OrderId = reader.GetInt32(0),
                                    OrderType = type,
                                    ItemName = reader.GetString(2),
                                    Quantity = reader.GetInt32(3),
                                    UnitPrice = reader.GetDecimal(4),
                                    TotalAmount = reader.GetDecimal(5),
                                    OrderDate = reader.GetDateTime(6).ToString("dd/MM/yyyy HH:mm"),
                                    PaymentMethod = reader.IsDBNull(7) ? "—" : reader.GetString(7),
                                    PaymentStatus = reader.IsDBNull(8) ? "—" : reader.GetString(8),
                                    TransactionRef = reader.GetString(9)
                                };

                                if (type.Equals("Ticket", StringComparison.OrdinalIgnoreCase) || type.Equals("Event", StringComparison.OrdinalIgnoreCase))
                                {
                                    TicketPurchases.Add(item);
                                }
                                else if (type.Equals("Membership", StringComparison.OrdinalIgnoreCase))
                                {
                                    MembershipPurchases.Add(item);
                                }
                                else if (type.Equals("Shop", StringComparison.OrdinalIgnoreCase))
                                {
                                    ShopPurchases.Add(item);
                                }
                            }
                        }
                    }
                }
            }
            catch (SqlException)
            {
                // handle silently
            }
        }
    }
}
