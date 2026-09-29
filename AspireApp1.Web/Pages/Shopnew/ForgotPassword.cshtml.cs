using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;

namespace WebApps.Pages.Shopnew
{
    public class ForgotPasswordModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ForgotPasswordModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string? ErrorMessage { get; set; }
        public string? SuccessMessage { get; set; }

        public string SubmittedEmail { get; set; } = "";
        public string SubmittedPhone { get; set; } = "";

        public void OnGet()
        {
        }

        public async Task<IActionResult> OnPostVerifyInfoAsync([FromBody] VerifyInputModel input)
        {
            if (input == null || string.IsNullOrEmpty(input.Value))
            {
                return new JsonResult(new { success = false, message = "Input value cannot be empty." });
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    await conn.OpenAsync();

                    string query = "";
                    if (input.Method == "email")
                    {
                        query = "SELECT UserId, Email FROM Users WHERE Email = @Val";
                    }
                    else
                    {
                        query = "SELECT UserId, Email FROM Users WHERE Phone = @Val";
                    }

                    int userId = 0;
                    string foundEmail = "";

                    using (SqlCommand cmd = new SqlCommand(query, conn))
                    {
                        cmd.Parameters.AddWithValue("@Val", input.Value.Trim());
                        using (var reader = await cmd.ExecuteReaderAsync())
                        {
                            if (reader.Read())
                            {
                                userId = reader.GetInt32(0);
                                foundEmail = reader.IsDBNull(1) ? "" : reader.GetString(1);
                            }
                        }
                    }

                    if (userId == 0)
                    {
                        string fieldName = input.Method == "email" ? "Email" : "Phone number";
                        return new JsonResult(new { success = false, message = $"{fieldName} is not registered in our system." });
                    }

                    // Create reset token
                    string token = Guid.NewGuid().ToString("N");
                    string updateSql = "UPDATE Users SET ResetToken = @Token, ResetTokenExpiry = DATEADD(HOUR, 2, GETDATE()) WHERE UserId = @Id";
                    using (SqlCommand cmd = new SqlCommand(updateSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Token", token);
                        cmd.Parameters.AddWithValue("@Id", userId);
                        await cmd.ExecuteNonQueryAsync();
                    }

                    return new JsonResult(new { success = true, token = token, email = foundEmail });
                }
            }
            catch (Exception ex)
            {
                return new JsonResult(new { success = false, message = "System error: " + ex.Message });
            }
        }

        public class VerifyInputModel
        {
            public string Method { get; set; }
            public string Value { get; set; }
        }

        public IActionResult OnPost(string forgotEmail, string forgotPhone)
        {
            SubmittedEmail = forgotEmail ?? "";
            SubmittedPhone = forgotPhone ?? "";

            bool hasEmail = !string.IsNullOrWhiteSpace(forgotEmail);
            bool hasPhone = !string.IsNullOrWhiteSpace(forgotPhone);

            if (!hasEmail && !hasPhone)
            {
                ErrorMessage = "Please enter your email address or phone number.";
                return Page();
            }

            string? connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                ErrorMessage = "Database connection error.";
                return Page();
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    string findSql = @"
                        SELECT UserId, Email, Phone 
                        FROM Users 
                        WHERE (@HasEmail = 1 AND Email = @Email)
                           OR (@HasPhone = 1 AND Phone = @Phone)";

                    string foundEmail = "";
                    bool userFound = false;

                    using (SqlCommand findCmd = new SqlCommand(findSql, conn))
                    {
                        findCmd.Parameters.AddWithValue("@HasEmail", hasEmail ? 1 : 0);
                        findCmd.Parameters.AddWithValue("@Email", hasEmail ? forgotEmail : "");
                        findCmd.Parameters.AddWithValue("@HasPhone", hasPhone ? 1 : 0);
                        findCmd.Parameters.AddWithValue("@Phone", hasPhone ? forgotPhone : "");

                        using (var reader = findCmd.ExecuteReader())
                        {
                            if (reader.Read())
                            {
                                userFound = true;
                                foundEmail = reader.IsDBNull(1) ? "" : reader.GetString(1);
                            }
                        }
                    }

                    if (!userFound)
                    {
                        var errors = new List<string>();
                        if (hasEmail)
                            errors.Add("Email \"" + forgotEmail + "\" is not registered");
                        if (hasPhone)
                            errors.Add("Phone \"" + forgotPhone + "\" is not registered");
                        
                        ErrorMessage = string.Join(" and ", errors) + ". Please check and try again.";
                        return Page();
                    }

                    string token = Guid.NewGuid().ToString("N");

                    string updateSql = @"
                        UPDATE Users 
                        SET ResetToken = @Token, 
                            ResetTokenExpiry = DATEADD(HOUR, 2, GETDATE())
                        WHERE (@HasEmail = 1 AND Email = @Email)
                           OR (@HasPhone = 1 AND Phone = @Phone)";

                    using (SqlCommand cmd = new SqlCommand(updateSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Token", token);
                        cmd.Parameters.AddWithValue("@HasEmail", hasEmail ? 1 : 0);
                        cmd.Parameters.AddWithValue("@Email", hasEmail ? forgotEmail : "");
                        cmd.Parameters.AddWithValue("@HasPhone", hasPhone ? 1 : 0);
                        cmd.Parameters.AddWithValue("@Phone", hasPhone ? forgotPhone : "");
                        cmd.ExecuteNonQuery();
                    }

                    return RedirectToPage("/ResetPassword", new { token = token, email = foundEmail });
                }
            }
            catch (SqlException)
            {
                ErrorMessage = "An error occurred. Please try again later.";
            }

            return Page();
        }
    }
}
