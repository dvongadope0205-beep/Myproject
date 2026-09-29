using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using System.Security.Claims;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Security.Cryptography;
using System.Text;

namespace WebApps.Pages.Shopnew
{
    public class ShopLoginModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public ShopLoginModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        [BindProperty]
        public string? Email { get; set; }

        [BindProperty]
        public string? Password { get; set; }

        [BindProperty(SupportsGet = true)]
        public string? ReturnUrl { get; set; }

        public string? ErrorMessage { get; set; }
        public string? RegisterMessage { get; set; }
        
        // Flag to keep Sign Up panel active after POST
        public bool ShowSignUpPanel { get; set; } = false;

        public void OnGet()
        {
            if (string.IsNullOrEmpty(ReturnUrl))
            {
                var referer = Request.Headers["Referer"].ToString();
                if (!string.IsNullOrEmpty(referer))
                {
                    var uri = new Uri(referer);
                    ReturnUrl = uri.PathAndQuery;
                }
            }
        }

        // ============================================================
        // SIGN IN
        // ============================================================
        public async Task<IActionResult> OnPostAsync()
        {
            if (string.IsNullOrEmpty(Email) || string.IsNullOrEmpty(Password))
            {
                ErrorMessage = "Please enter both Email/Username and Password.";
                return Page();
            }

            string? connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString)) 
            {
                ErrorMessage = "Database connection error.";
                return Page();
            }
            bool isValid = false;
            string roleName = "Customer";
            string fullName = "";
            string userEmail = "";

            using (SqlConnection connection = new SqlConnection(connectionString))
            {
                // Hỗ trợ cả password plain-text (legacy) và hash (mới)
                string sql = @"SELECT u.FullName, r.RoleName, u.PasswordHash 
                               FROM Users u 
                               JOIN Roles r ON u.RoleId = r.RoleId 
                               WHERE (u.Email = @Email OR u.Username = @Email)";
                
                using (SqlCommand command = new SqlCommand(sql, connection))
                {
                    command.Parameters.AddWithValue("@Email", Email);

                    connection.Open();
                    using (SqlDataReader reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            fullName = reader.GetString(0);
                            roleName = reader.GetString(1);
                            string storedPassword = reader.GetString(2);

                            // Kiểm tra: hỗ trợ cả salted hash (mới), SHA256 không salt (cũ), và plain-text (legacy)
                            if (VerifyPassword(Password, storedPassword))
                            {
                                isValid = true;
                            }
                        }
                    }

                    // Lấy Email từ Users table
                    string emailSql = "SELECT Email FROM Users WHERE (Email = @Email2 OR Username = @Email2)";
                    using (SqlCommand emailCmd = new SqlCommand(emailSql, connection))
                    {
                        emailCmd.Parameters.AddWithValue("@Email2", Email);
                        var result = emailCmd.ExecuteScalar();
                        if (result != null) userEmail = result.ToString();
                    }
                }
            }

            if (isValid)
            {
                var claims = new List<Claim>
                {
                    new Claim(ClaimTypes.Name, fullName),
                    new Claim(ClaimTypes.Email, userEmail),
                    new Claim(ClaimTypes.Role, roleName)
                };

                var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                
                await HttpContext.SignInAsync(
                    CookieAuthenticationDefaults.AuthenticationScheme, 
                    new ClaimsPrincipal(identity));

                if (Url.IsLocalUrl(ReturnUrl))
                {
                    return LocalRedirect(ReturnUrl);
                }

                // All roles → redirect to /Shopnew
                return Redirect("/Shopnew");
            }

            ErrorMessage = "Invalid username or password.";
            return Page();
        }

        // ============================================================
        // SIGN UP / REGISTER
        // ============================================================
        public async Task<IActionResult> OnPostRegisterAsync(string regName, string regEmail, string regPassword)
        {
            ShowSignUpPanel = true; // Keep Sign Up panel visible on error

            if (string.IsNullOrEmpty(regName) || string.IsNullOrEmpty(regEmail) || string.IsNullOrEmpty(regPassword))
            {
                RegisterMessage = "Please fill in all fields.";
                return Page();
            }

            if (regPassword.Length < 6)
            {
                RegisterMessage = "Password must be at least 6 characters.";
                return Page();
            }

            string? connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                RegisterMessage = "Database connection error.";
                return Page();
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    conn.Open();

                    // Kiểm tra email đã tồn tại chưa
                    string checkEmailSql = "SELECT COUNT(*) FROM Users WHERE Email = @Email";
                    using (SqlCommand checkCmd = new SqlCommand(checkEmailSql, conn))
                    {
                        checkCmd.Parameters.AddWithValue("@Email", regEmail);
                        int count = (int)checkCmd.ExecuteScalar();
                        if (count > 0)
                        {
                            RegisterMessage = "This email is already registered. Please use a different email or sign in.";
                            ShowSignUpPanel = true;
                            return Page();
                        }
                    }

                    // Kiểm tra username đã tồn tại chưa
                    string checkUsernameSql = "SELECT COUNT(*) FROM Users WHERE Username = @Username";
                    using (SqlCommand checkCmd = new SqlCommand(checkUsernameSql, conn))
                    {
                        checkCmd.Parameters.AddWithValue("@Username", regName);
                        int count = (int)checkCmd.ExecuteScalar();
                        if (count > 0)
                        {
                            RegisterMessage = "This username is already taken. Please choose a different one.";
                            ShowSignUpPanel = true;
                            return Page();
                        }
                    }

                    // Lấy RoleId cho Customer (tạo nếu chưa có)
                    int customerRoleId = 0;
                    string roleSql = "SELECT RoleId FROM Roles WHERE RoleName = 'Customer'";
                    using (SqlCommand roleCmd = new SqlCommand(roleSql, conn))
                    {
                        var result = roleCmd.ExecuteScalar();
                        if (result != null) customerRoleId = (int)result;
                    }

                    // Nếu chưa có role Customer → tạo mới
                    if (customerRoleId == 0)
                    {
                        using (SqlCommand createRole = new SqlCommand(
                            "INSERT INTO Roles (RoleName) VALUES ('Customer'); SELECT SCOPE_IDENTITY();", conn))
                        {
                            var result = createRole.ExecuteScalar();
                            if (result != null) customerRoleId = Convert.ToInt32(result);
                        }
                    }

                    if (customerRoleId == 0)
                    {
                        RegisterMessage = "System error: Cannot create user role.";
                        return Page();
                    }

                    // regName chính là Username (người dùng tự chọn)
                    string username = regName.Trim();

                    // Hash password với SHA256 + salt
                    string salt = GenerateSalt();
                    string savedPassword = salt + ":" + HashPasswordWithSalt(regPassword, salt);

                    // INSERT vào Users — FullName = NULL, sẽ cập nhật sau qua profile popup
                    string insertUser = @"INSERT INTO Users (RoleId, Username, Email, PasswordHash, FullName, Phone, Address, IsActive, CreatedAt) 
                                          VALUES (@RoleId, @Username, @Email, @Password, NULL, NULL, NULL, 1, GETDATE());
                                          SELECT SCOPE_IDENTITY();";
                    int newUserId = 0;
                    using (SqlCommand cmd = new SqlCommand(insertUser, conn))
                    {
                        cmd.Parameters.AddWithValue("@RoleId", customerRoleId);
                        cmd.Parameters.AddWithValue("@Username", username);
                        cmd.Parameters.AddWithValue("@Email", regEmail);
                        cmd.Parameters.AddWithValue("@Password", savedPassword);
                        var result = cmd.ExecuteScalar();
                        if (result != null) newUserId = Convert.ToInt32(result);
                    }

                    if (newUserId == 0)
                    {
                        RegisterMessage = "Registration failed. Please try again.";
                        return Page();
                    }

                    // AUTO-LOGIN ngay sau khi đăng ký (dùng Username làm Name claim)
                    var claims = new List<Claim>
                    {
                        new Claim(ClaimTypes.Name, username),
                        new Claim(ClaimTypes.Email, regEmail),
                        new Claim(ClaimTypes.Role, "Customer")
                    };
                    var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
                    await HttpContext.SignInAsync(
                        CookieAuthenticationDefaults.AuthenticationScheme,
                        new ClaimsPrincipal(identity));

                    // Redirect to /Shopnew after registration
                    return Redirect("/Shopnew");
                }
            }
            catch (SqlException)
            {
                RegisterMessage = "Registration failed. Please try again later.";
                return Page();
            }
        }

        // ============================================================
        // Password Hash Helpers (SHA256 + Salt)
        // ============================================================
        
        /// <summary>Tạo salt ngẫu nhiên 16 bytes</summary>
        private static string GenerateSalt()
        {
            byte[] saltBytes = new byte[16];
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(saltBytes);
            }
            return Convert.ToBase64String(saltBytes);
        }

        /// <summary>Hash password với salt cụ thể</summary>
        private static string HashPasswordWithSalt(string password, string salt)
        {
            using (SHA256 sha256 = SHA256.Create())
            {
                byte[] bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(salt + password));
                StringBuilder sb = new StringBuilder();
                foreach (byte b in bytes)
                {
                    sb.Append(b.ToString("x2"));
                }
                return sb.ToString();
            }
        }

        /// <summary>Hash password không salt (legacy/backward compat)</summary>
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

        /// <summary>Xác minh password — hỗ trợ: salted hash, SHA256, plain-text</summary>
        private static bool VerifyPassword(string inputPassword, string storedPassword)
        {
            // Format mới: salt:hash
            if (storedPassword.Contains(':'))
            {
                string[] parts = storedPassword.Split(':', 2);
                string salt = parts[0];
                string hash = parts[1];
                return hash == HashPasswordWithSalt(inputPassword, salt);
            }
            // Format cũ: SHA256 không salt (64 hex chars)
            if (storedPassword.Length == 64 && System.Text.RegularExpressions.Regex.IsMatch(storedPassword, "^[a-f0-9]+$"))
            {
                return storedPassword == HashPassword(inputPassword);
            }
            // Legacy: plain-text
            return storedPassword == inputPassword;
        }
    }
}
