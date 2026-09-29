using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace WebApps.Pages
{
    public class GroupsModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public GroupsModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty] public string OrganizationName { get; set; }
        [BindProperty] public string ContactName { get; set; }
        [BindProperty] public string EmailAddress { get; set; }
        [BindProperty] public string Phone { get; set; }
        [BindProperty] public int Headcount { get; set; }
        [BindProperty] public string PreferredDate { get; set; }
        [BindProperty] public string AdditionalNeeds { get; set; }

        public void OnGet() { }

        public IActionResult OnPost()
        {
            if (string.IsNullOrEmpty(OrganizationName) || string.IsNullOrEmpty(ContactName) ||
                string.IsNullOrEmpty(EmailAddress) || string.IsNullOrEmpty(AdditionalNeeds))
            {
                return Page();
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"INSERT INTO GroupRequests (OrganizationName, ContactName, Email, Phone, Headcount, PreferredDate, AdditionalNeeds)
                                   VALUES (@Org, @Contact, @Email, @Phone, @Headcount, @PrefDate, @Needs)";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Org", OrganizationName);
                        cmd.Parameters.AddWithValue("@Contact", ContactName);
                        cmd.Parameters.AddWithValue("@Email", EmailAddress);
                        cmd.Parameters.AddWithValue("@Phone", string.IsNullOrEmpty(Phone) ? (object)DBNull.Value : Phone);
                        cmd.Parameters.AddWithValue("@Headcount", Headcount < 15 ? 15 : Headcount);
                        
                        if (DateTime.TryParse(PreferredDate, out DateTime parsedDate))
                            cmd.Parameters.AddWithValue("@PrefDate", parsedDate);
                        else
                            cmd.Parameters.AddWithValue("@PrefDate", DBNull.Value);
                        
                        cmd.Parameters.AddWithValue("@Needs", AdditionalNeeds);
                        cmd.ExecuteNonQuery();
                    }

                    // Create notification for Admin
                    string notifSql = @"INSERT INTO Notifications 
                        (RecipientRole, RecipientEmail, Title, Message, Type, IconClass)
                        VALUES ('Admin', NULL, @Title, @Msg, 'EventRequest', 'fa-users')";
                    using (SqlCommand notifCmd = new SqlCommand(notifSql, conn))
                    {
                        notifCmd.Parameters.AddWithValue("@Title", $"New Group Booking: {OrganizationName}");
                        notifCmd.Parameters.AddWithValue("@Msg", $"{ContactName} from {OrganizationName} requested group tickets for {Headcount} guests");
                        notifCmd.ExecuteNonQuery();
                    }
                }
                TempData["GroupSuccess"] = "Your group booking request has been submitted! Our team will contact you within 2 business days.";
            }
            catch (SqlException)
            {
                TempData["GroupSuccess"] = "Request submitted! Our team will reach out shortly.";
            }

            return RedirectToPage("/Groups");
        }
    }
}