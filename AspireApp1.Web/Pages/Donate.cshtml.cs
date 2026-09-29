using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using System.Text.Json;

namespace WebApps.Pages
{
    public class DonateModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public DonateModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public void OnGet() { }

        public async Task<IActionResult> OnPostAsync()
        {
            try
            {
                using var reader = new StreamReader(Request.Body);
                var body = await reader.ReadToEndAsync();
                var data = JsonSerializer.Deserialize<DonationRequest>(body, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });

                if (data == null || string.IsNullOrEmpty(data.FirstName) || 
                    string.IsNullOrEmpty(data.LastName) || string.IsNullOrEmpty(data.Email) || 
                    data.Amount <= 0)
                {
                    return new JsonResult(new { success = false, message = "Invalid donation data." });
                }

                string txRef = "DON-" + DateTime.Now.ToString("yyyyMMdd") + "-" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();
                string connStr = _configuration.GetConnectionString("DefaultConnection") ?? "";

                using (var conn = new SqlConnection(connStr))
                {
                    await conn.OpenAsync();
                    using var transaction = conn.BeginTransaction();

                    try
                    {
                        // Insert donation
                        string sql = @"INSERT INTO Donations 
                            (DonorFirstName, DonorLastName, Email, Phone, Amount, DonationFrequency, 
                             GiftPurpose, DedicationType, DedicationName, CoverFees, TransactionRef, 
                             Status, PaymentMethod, CompletedAt)
                            VALUES 
                            (@First, @Last, @Email, @Phone, @Amount, @Freq, 
                             @Purpose, @DedType, @DedName, @CoverFees, @TxRef, 
                             'Completed', 'QR', GETDATE())";

                        using (var cmd = new SqlCommand(sql, conn, transaction))
                        {
                            cmd.Parameters.AddWithValue("@First", data.FirstName);
                            cmd.Parameters.AddWithValue("@Last", data.LastName);
                            cmd.Parameters.AddWithValue("@Email", data.Email);
                            cmd.Parameters.AddWithValue("@Phone", data.Phone ?? "");
                            cmd.Parameters.AddWithValue("@Amount", data.Amount);
                            cmd.Parameters.AddWithValue("@Freq", data.Frequency ?? "OneTime");
                            cmd.Parameters.AddWithValue("@Purpose", data.Purpose ?? "GreatestNeed");
                            cmd.Parameters.AddWithValue("@DedType", data.DedicationType ?? "None");
                            cmd.Parameters.AddWithValue("@DedName", data.DedicationName ?? "");
                            cmd.Parameters.AddWithValue("@CoverFees", data.CoverFees ? 1 : 0);
                            cmd.Parameters.AddWithValue("@TxRef", txRef);
                            await cmd.ExecuteNonQueryAsync();
                        }

                        // Create notification for Admin
                        string notifSql = @"INSERT INTO Notifications 
                            (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                            VALUES 
                            ('Admin', NULL, @Title, @Msg, 'Donation', @Ref, 'fa-heart')";

                        using (var notifCmd = new SqlCommand(notifSql, conn, transaction))
                        {
                            notifCmd.Parameters.AddWithValue("@Title", $"New Donation: ${data.Amount:F2}");
                            notifCmd.Parameters.AddWithValue("@Msg", $"{data.FirstName} {data.LastName} donated ${data.Amount:F2} to {data.Purpose}");
                            notifCmd.Parameters.AddWithValue("@Ref", txRef);
                            await notifCmd.ExecuteNonQueryAsync();
                        }

                        // Create notification for User (if logged in)
                        if (User?.Identity?.IsAuthenticated == true)
                        {
                            var userEmail = User.FindFirst(System.Security.Claims.ClaimTypes.Email)?.Value;
                            if (!string.IsNullOrEmpty(userEmail))
                            {
                                string userNotifSql = @"INSERT INTO Notifications 
                                    (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                                    VALUES 
                                    ('Customer', @Email, @Title, @Msg, 'Donation', @Ref, 'fa-check-circle')";

                                using (var userNotifCmd = new SqlCommand(userNotifSql, conn, transaction))
                                {
                                    userNotifCmd.Parameters.AddWithValue("@Email", userEmail);
                                    userNotifCmd.Parameters.AddWithValue("@Title", "Donation Confirmed!");
                                    userNotifCmd.Parameters.AddWithValue("@Msg", $"Thank you! Your donation of ${data.Amount:F2} ({txRef}) has been received.");
                                    userNotifCmd.Parameters.AddWithValue("@Ref", txRef);
                                    await userNotifCmd.ExecuteNonQueryAsync();
                                }
                            }
                        }

                        transaction.Commit();
                    }
                    catch
                    {
                        transaction.Rollback();
                        throw;
                    }
                }

                return new JsonResult(new { success = true, transactionRef = txRef });
            }
            catch (Exception)
            {
                return new JsonResult(new { success = false, message = "Unable to process donation. Please try again later." });
            }
        }
    }

    public class DonationRequest
    {
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string? Phone { get; set; }
        public decimal Amount { get; set; }
        public string? Frequency { get; set; }
        public string? Purpose { get; set; }
        public string? DedicationType { get; set; }
        public string? DedicationName { get; set; }
        public bool CoverFees { get; set; }
    }
}