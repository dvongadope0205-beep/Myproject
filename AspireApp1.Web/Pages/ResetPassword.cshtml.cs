using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Security.Cryptography;
using System.Text;

namespace WebApps.Pages
{
    public class ResetPasswordModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ResetPasswordModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty(SupportsGet = true)]
        public string? Token { get; set; }

        [BindProperty(SupportsGet = true)]
        public string? Email { get; set; }

        [BindProperty]
        public string? NewPassword { get; set; }

        [BindProperty]
        public string? ConfirmPassword { get; set; }

        public string? ErrorMessage { get; set; }
        public string? SuccessMessage { get; set; }

        public void OnGet()
        {
            if (string.IsNullOrEmpty(Token) || string.IsNullOrEmpty(Email))
            {
                ErrorMessage = "Invalid password reset link.";
            }
        }

        public IActionResult OnPost()
        {
            if (string.IsNullOrEmpty(Token) || string.IsNullOrEmpty(Email))
            {
                ErrorMessage = "Invalid password reset link.";
                return Page();
            }

            if (string.IsNullOrEmpty(NewPassword) || NewPassword.Length < 6)
            {
                ErrorMessage = "Password must be at least 6 characters.";
                return Page();
            }

            if (NewPassword != ConfirmPassword)
            {
                ErrorMessage = "Passwords do not match.";
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

                    // Kiểm tra token có hợp lệ và chưa hết hạn không
                    string checkSql = @"
                        SELECT UserId FROM Users 
                        WHERE Email = @Email 
                          AND ResetToken = @Token 
                          AND ResetTokenExpiry > GETDATE()";

                    int? userId = null;
                    using (SqlCommand checkCmd = new SqlCommand(checkSql, conn))
                    {
                        checkCmd.Parameters.AddWithValue("@Email", Email);
                        checkCmd.Parameters.AddWithValue("@Token", Token);
                        
                        var result = checkCmd.ExecuteScalar();
                        if (result != null)
                        {
                            userId = (int)result;
                        }
                    }

                    if (userId == null)
                    {
                        ErrorMessage = "Invalid or expired reset token. Please request a new link.";
                        return Page();
                    }

                    // Reset password & clear token
                    string hashedPassword = HashPassword(NewPassword);
                    string updateSql = @"
                        UPDATE Users 
                        SET PasswordHash = @Password, 
                            ResetToken = NULL, 
                            ResetTokenExpiry = NULL 
                        WHERE UserId = @UserId";

                    using (SqlCommand updateCmd = new SqlCommand(updateSql, conn))
                    {
                        updateCmd.Parameters.AddWithValue("@Password", hashedPassword);
                        updateCmd.Parameters.AddWithValue("@UserId", userId.Value);
                        updateCmd.ExecuteNonQuery();
                    }

                    SuccessMessage = "Password reset successfully! You can now log in with your new password.";
                }
            }
            catch (SqlException)
            {
                ErrorMessage = "An error occurred while resetting your password. Please try again later.";
            }

            return Page();
        }

        private static string HashPassword(string password)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
                StringBuilder sb = new StringBuilder();
                foreach (byte b in bytes)
                {
                    sb.Append(b.ToString("x2"));
                }
                return sb.ToString();
            }
        }
    }
}
