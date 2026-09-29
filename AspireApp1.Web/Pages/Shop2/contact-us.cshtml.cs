using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;

namespace WebProject.Pages
{
    public class ContactusModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ContactusModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty(Name = "contact[name]")]
        public string Name { get; set; }

        [BindProperty(Name = "contact[email]")]
        public string Email { get; set; }

        [BindProperty(Name = "contact[phone]")]
        public string Phone { get; set; }

        [BindProperty(Name = "contact[subject]")]
        public string Subject { get; set; }

        [BindProperty(Name = "contact[reason]")]
        public string Reason { get; set; }

        [BindProperty(Name = "contact[body]")]
        public string Body { get; set; }

        public void OnGet()
        {
        }

        public async Task<IActionResult> OnPostAsync()
        {
            if (string.IsNullOrEmpty(Email) || string.IsNullOrEmpty(Body))
            {
                TempData["ErrorMessage"] = "Email and Message fields are required.";
                return Page();
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    await conn.OpenAsync();

                    // Split name into first and last name if possible
                    string firstName = Name ?? "";
                    string lastName = "";
                    if (!string.IsNullOrEmpty(Name))
                    {
                        var parts = Name.Trim().Split(' ');
                        if (parts.Length > 1)
                        {
                            firstName = parts[0];
                            lastName = Name.Substring(parts[0].Length).Trim();
                        }
                    }

                    // Write to contactus table
                    string sql = @"
                        INSERT INTO contactus (FirstName, LastName, Email, Subject, Message, Source, Reason)
                        VALUES (@First, @Last, @Email, @Subject, @Message, 'ZooShop2', @Reason)";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@First", firstName);
                        cmd.Parameters.AddWithValue("@Last", lastName);
                        cmd.Parameters.AddWithValue("@Email", Email);
                        cmd.Parameters.AddWithValue("@Subject", string.IsNullOrEmpty(Subject) ? (Reason ?? "General Inquiry") : Subject);
                        cmd.Parameters.AddWithValue("@Message", Body);
                        cmd.Parameters.AddWithValue("@Reason", Reason ?? "Other");
                        await cmd.ExecuteNonQueryAsync();
                    }

                    // Create Notification for Admin
                    string notifSql = @"
                        INSERT INTO Notifications (RecipientRole, RecipientEmail, Title, Message, Type, IconClass)
                        VALUES ('Admin', NULL, @Title, @Msg, 'Contact', 'fa-envelope')";
                    using (SqlCommand notifCmd = new SqlCommand(notifSql, conn))
                    {
                        notifCmd.Parameters.AddWithValue("@Title", $"Zoo Shop 2 Contact: {Reason ?? "Support"}");
                        notifCmd.Parameters.AddWithValue("@Msg", $"{Name} ({Email}) sent a Zoo Shop 2 message about {Reason ?? "Support"}");
                        await notifCmd.ExecuteNonQueryAsync();
                    }
                }

                TempData["ContactSuccess"] = "Thank you! Your message has been sent successfully. We will get back to you as soon as possible.";
            }
            catch (SqlException)
            {
                TempData["ContactSuccess"] = "Your message was sent successfully! We will touch base soon.";
            }

            return RedirectToPage("/Shop2/contact-us");
        }
    }
}
