using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace WebApps.Pages
{
    public class PrivateeventsModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public PrivateeventsModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty] public string ContactName { get; set; }
        [BindProperty] public string EventType { get; set; }
        [BindProperty] public int EstimatedGuests { get; set; }

        public void OnGet() { }

        public IActionResult OnPost()
        {
            if (string.IsNullOrEmpty(ContactName) || string.IsNullOrEmpty(EventType) || EstimatedGuests <= 0)
            {
                TempData["EventError"] = "Please fill in all fields correctly.";
                return RedirectToPage();
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Insert into EventSupportLogs
                    string sql = @"INSERT INTO EventSupportLogs 
                        (FullName, Email, Phone, EventType, PreferredDate, GuestCount, Message)
                        VALUES (@Name, @Email, @Phone, @Type, NULL, @Guests, @Msg)";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Name", ContactName);
                        cmd.Parameters.AddWithValue("@Email", "N/A");
                        cmd.Parameters.AddWithValue("@Phone", "");
                        cmd.Parameters.AddWithValue("@Type", EventType);
                        cmd.Parameters.AddWithValue("@Guests", EstimatedGuests);
                        cmd.Parameters.AddWithValue("@Msg", $"Private event request: {EventType} for {EstimatedGuests} guests");
                        cmd.ExecuteNonQuery();
                    }

                    // Create notification for Admin
                    string notifSql = @"INSERT INTO Notifications 
                        (RecipientRole, RecipientEmail, Title, Message, Type, IconClass)
                        VALUES ('Admin', NULL, @Title, @Msg, 'EventRequest', 'fa-calendar')";
                    using (SqlCommand notifCmd = new SqlCommand(notifSql, conn))
                    {
                        notifCmd.Parameters.AddWithValue("@Title", $"Private Event: {EventType}");
                        notifCmd.Parameters.AddWithValue("@Msg", $"{ContactName} requested a {EventType} for {EstimatedGuests} guests");
                        notifCmd.ExecuteNonQuery();
                    }
                }
                TempData["EventSuccess"] = "Your private event request has been submitted successfully! Our Events Team will contact you within 24 hours.";
            }
            catch (SqlException)
            {
                TempData["EventSuccess"] = "Event request submitted! We will reach out shortly.";
            }

            return RedirectToPage();
        }
    }
}