using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System.Security.Claims;

namespace WebApps.Pages
{
    public class NotificationApiModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public NotificationApiModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // GET: /NotificationApi?handler=Fetch
        public async Task<IActionResult> OnGetFetchAsync()
        {
            if (User?.Identity?.IsAuthenticated != true)
                return new JsonResult(new { notifications = new object[0], unreadCount = 0 });

            var role = User.FindFirst(ClaimTypes.Role)?.Value ?? "Customer";
            var email = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            string connStr = _configuration.GetConnectionString("DefaultConnection") ?? "";

            var notifications = new List<object>();
            int unreadCount = 0;

            using (var conn = new SqlConnection(connStr))
            {
                await conn.OpenAsync();

                string sql;
                if (role == "Admin")
                {
                    // Admin sees all admin notifications
                    sql = @"SELECT TOP 20 NotificationId, Title, Message, Type, IconClass, IsRead, CreatedAt, ReferenceId
                            FROM Notifications 
                            WHERE RecipientRole = 'Admin' 
                            ORDER BY CreatedAt DESC";
                }
                else
                {
                    // Customer sees only their own notifications
                    sql = @"SELECT TOP 20 NotificationId, Title, Message, Type, IconClass, IsRead, CreatedAt, ReferenceId
                            FROM Notifications 
                            WHERE RecipientRole = 'Customer' AND RecipientEmail = @Email
                            ORDER BY CreatedAt DESC";
                }

                using (var cmd = new SqlCommand(sql, conn))
                {
                    if (role != "Admin")
                        cmd.Parameters.AddWithValue("@Email", email);

                    using (var reader = await cmd.ExecuteReaderAsync())
                    {
                        while (await reader.ReadAsync())
                        {
                            bool isRead = reader.GetBoolean(5);
                            if (!isRead) unreadCount++;

                            notifications.Add(new
                            {
                                id = reader.GetInt32(0),
                                title = reader.GetString(1),
                                message = reader.GetString(2),
                                type = reader.GetString(3),
                                icon = reader.GetString(4),
                                isRead = isRead,
                                createdAt = reader.GetDateTime(6).ToString("MMM dd, HH:mm"),
                                referenceId = reader.IsDBNull(7) ? "" : reader.GetString(7)
                            });
                        }
                    }
                }
            }

            return new JsonResult(new { notifications, unreadCount });
        }

        // POST: /NotificationApi?handler=MarkRead&id=123
        public async Task<IActionResult> OnPostMarkReadAsync(int id)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection") ?? "";
            using (var conn = new SqlConnection(connStr))
            {
                await conn.OpenAsync();
                using (var cmd = new SqlCommand("UPDATE Notifications SET IsRead = 1 WHERE NotificationId = @Id", conn))
                {
                    cmd.Parameters.AddWithValue("@Id", id);
                    await cmd.ExecuteNonQueryAsync();
                }
            }
            return new JsonResult(new { success = true });
        }

        // POST: /NotificationApi?handler=MarkAllRead
        public async Task<IActionResult> OnPostMarkAllReadAsync()
        {
            if (User?.Identity?.IsAuthenticated != true)
                return new JsonResult(new { success = false });

            var role = User.FindFirst(ClaimTypes.Role)?.Value ?? "Customer";
            var email = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            string connStr = _configuration.GetConnectionString("DefaultConnection") ?? "";

            using (var conn = new SqlConnection(connStr))
            {
                await conn.OpenAsync();
                string sql;
                if (role == "Admin")
                    sql = "UPDATE Notifications SET IsRead = 1 WHERE RecipientRole = 'Admin' AND IsRead = 0";
                else
                    sql = "UPDATE Notifications SET IsRead = 1 WHERE RecipientRole = 'Customer' AND RecipientEmail = @Email AND IsRead = 0";

                using (var cmd = new SqlCommand(sql, conn))
                {
                    if (role != "Admin")
                        cmd.Parameters.AddWithValue("@Email", email);
                    await cmd.ExecuteNonQueryAsync();
                }
            }
            return new JsonResult(new { success = true });
        }
    }
}
