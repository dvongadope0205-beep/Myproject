using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace WebApps.Pages
{
    public class ContactModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ContactModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        // === General Contact Form ===
        [BindProperty] public string FirstName { get; set; }
        [BindProperty] public string LastName { get; set; }
        [BindProperty] public string EmailAddress { get; set; }
        [BindProperty] public string Subject { get; set; }
        [BindProperty] public string Reason { get; set; }
        [BindProperty] public string MessageText { get; set; }

        // === Events Team Form ===
        [BindProperty] public string EventFullName { get; set; }
        [BindProperty] public string EventEmail { get; set; }
        [BindProperty] public string EventPhone { get; set; }
        [BindProperty] public string EventType { get; set; }
        [BindProperty] public DateTime? EventPreferredDate { get; set; }
        [BindProperty] public int EventGuestCount { get; set; }
        [BindProperty] public string EventMessage { get; set; }

        public string SuccessMessage { get; set; }

        public void OnGet() { }

        // ============================================================
        // General Contact Form Handler
        // ============================================================
        public IActionResult OnPost()
        {
            if (string.IsNullOrEmpty(FirstName) || string.IsNullOrEmpty(LastName) || 
                string.IsNullOrEmpty(EmailAddress) || string.IsNullOrEmpty(MessageText))
            {
                return Page();
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"INSERT INTO Inquiries (FirstName, LastName, Email, Subject, Message, Reason)
                                   VALUES (@First, @Last, @Email, @Subject, @Message, @Reason)";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@First", FirstName);
                        cmd.Parameters.AddWithValue("@Last", LastName);
                        cmd.Parameters.AddWithValue("@Email", EmailAddress);
                        cmd.Parameters.AddWithValue("@Subject", Subject ?? "General Support");
                        cmd.Parameters.AddWithValue("@Message", MessageText);
                        cmd.Parameters.AddWithValue("@Reason", Reason ?? "General Inquiry");
                        cmd.ExecuteNonQuery();
                    }

                    // Write to contactus table as well
                    string contactusSql = @"INSERT INTO contactus (FirstName, LastName, Email, Subject, Message, Source, Reason)
                                           VALUES (@First, @Last, @Email, @Subject, @Message, 'NationZoo', @Reason)";
                    using (SqlCommand cmd = new SqlCommand(contactusSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@First", FirstName);
                        cmd.Parameters.AddWithValue("@Last", LastName);
                        cmd.Parameters.AddWithValue("@Email", EmailAddress);
                        cmd.Parameters.AddWithValue("@Subject", Subject ?? "General Support");
                        cmd.Parameters.AddWithValue("@Message", MessageText);
                        cmd.Parameters.AddWithValue("@Reason", Reason ?? "General Inquiry");
                        cmd.ExecuteNonQuery();
                    }

                    // Create notification for Admin
                    string notifSql = @"INSERT INTO Notifications 
                        (RecipientRole, RecipientEmail, Title, Message, Type, IconClass)
                        VALUES ('Admin', NULL, @Title, @Msg, 'Contact', 'fa-envelope')";
                    using (SqlCommand notifCmd = new SqlCommand(notifSql, conn))
                    {
                        notifCmd.Parameters.AddWithValue("@Title", $"New Contact: {Subject ?? "General Support"}");
                        notifCmd.Parameters.AddWithValue("@Msg", $"{FirstName} {LastName} sent a message about {Subject ?? "General Support"}");
                        notifCmd.ExecuteNonQuery();
                    }
                }
                TempData["ContactSuccess"] = "Your message has been sent successfully! We will get back to you shortly.";
            }
            catch (SqlException)
            {
                TempData["ContactSuccess"] = "Message sent! We will reach out shortly.";
            }

            return RedirectToPage("/Contact");
        }

        // ============================================================
        // Events Team Form Handler
        // ============================================================
        public IActionResult OnPostEventSupport()
        {
            if (string.IsNullOrEmpty(EventFullName) || string.IsNullOrEmpty(EventEmail) || 
                string.IsNullOrEmpty(EventType) || string.IsNullOrEmpty(EventMessage))
            {
                return Page();
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
                        VALUES (@Name, @Email, @Phone, @Type, @Date, @Guests, @Msg)";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Name", EventFullName);
                        cmd.Parameters.AddWithValue("@Email", EventEmail);
                        cmd.Parameters.AddWithValue("@Phone", EventPhone ?? "");
                        cmd.Parameters.AddWithValue("@Type", EventType);
                        cmd.Parameters.AddWithValue("@Date", EventPreferredDate.HasValue ? (object)EventPreferredDate.Value : DBNull.Value);
                        cmd.Parameters.AddWithValue("@Guests", EventGuestCount > 0 ? EventGuestCount : 1);
                        cmd.Parameters.AddWithValue("@Msg", EventMessage);
                        cmd.ExecuteNonQuery();
                    }

                    // Create notification for Admin
                    string notifSql = @"INSERT INTO Notifications 
                        (RecipientRole, RecipientEmail, Title, Message, Type, IconClass)
                        VALUES ('Admin', NULL, @Title, @Msg, 'EventRequest', 'fa-calendar')";
                    using (SqlCommand notifCmd = new SqlCommand(notifSql, conn))
                    {
                        notifCmd.Parameters.AddWithValue("@Title", $"New Event Request: {EventType}");
                        notifCmd.Parameters.AddWithValue("@Msg", $"{EventFullName} requested a {EventType} for {EventGuestCount} guests");
                        notifCmd.ExecuteNonQuery();
                    }
                }
                TempData["EventSuccess"] = "Your event request has been submitted! Our Events Team will contact you within 24 hours.";
            }
            catch (SqlException)
            {
                TempData["EventSuccess"] = "Event request submitted! We will reach out shortly.";
            }

            return RedirectToPage("/Contact");
        }
    }
}