using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.IO;
using System;
using System.Linq;

namespace WebApps.Pages
{
    [Authorize(Roles = "Admin")]
    public class AdminDashboardModel : PageModel
    {
        private readonly IConfiguration _configuration;
        private readonly IWebHostEnvironment _env;
        private readonly IMemoryCache _cache;

        public AdminDashboardModel(IConfiguration configuration, IWebHostEnvironment env, IMemoryCache cache)
        {
            _configuration = configuration;
            _env = env;
            _cache = cache;
        }

        // ── Events ───────────────────────────────────────────────────────────
        public class DashboardFormField
        {
            public string Id { get; set; }
            public string Name { get; set; }
            public string Label { get; set; }
            public string Type { get; set; } // "text", "number", "datetime-local", "textarea", "file", "select", "checkbox"
            public string Placeholder { get; set; }
            public bool IsRequired { get; set; }
            public string Step { get; set; }
            public string Min { get; set; }
            public string Value { get; set; }
            public string Rows { get; set; }
        }

        public List<DashboardFormField> EventFormFields { get; set; } = new List<DashboardFormField>
        {
            new DashboardFormField { Id = "EvtTitle", Name = "CurrentEvent.Title", Label = "Event Name *", Type = "text", Placeholder = "Enter event name...", IsRequired = true },
            new DashboardFormField { Id = "ImageUpload", Name = "ImageUpload", Label = "Event Image", Type = "file", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "EventDate", Name = "CurrentEvent.EventDate", Label = "Date & Time *", Type = "datetime-local", Placeholder = "", IsRequired = true },
            new DashboardFormField { Id = "Capacity", Name = "CurrentEvent.Capacity", Label = "Capacity *", Type = "number", Placeholder = "", IsRequired = true, Min = "0", Value = "100" },
            new DashboardFormField { Id = "BasePrice", Name = "CurrentEvent.BasePrice", Label = "Ticket Price ($) *", Type = "number", Placeholder = "", IsRequired = true, Min = "0", Step = "0.01", Value = "0.00" },
            new DashboardFormField { Id = "EvtLocation", Name = "CurrentEvent.Location", Label = "Location", Type = "text", Placeholder = "Enter location...", IsRequired = false },
            new DashboardFormField { Id = "EvtStatus", Name = "CurrentEvent.Status", Label = "Status", Type = "select", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "EvtDescription", Name = "CurrentEvent.Description", Label = "Description", Type = "textarea", Placeholder = "Short description of the event...", IsRequired = false, Rows = "2" },
            new DashboardFormField { Id = "EvtWhatToExpect", Name = "CurrentEvent.WhatToExpect", Label = "What to Expect", Type = "textarea", Placeholder = "What visitors can expect...", IsRequired = false, Rows = "3" },
            new DashboardFormField { Id = "EvtEventDetails", Name = "CurrentEvent.EventDetails", Label = "Event Details", Type = "textarea", Placeholder = "Detailed event schedule and info...", IsRequired = false, Rows = "3" },
            new DashboardFormField { Id = "EvtSponsors", Name = "CurrentEvent.Sponsors", Label = "Special Thanks to our Event Sponsors", Type = "textarea", Placeholder = "Sponsor information and thanks...", IsRequired = false, Rows = "2" }
        };

        public List<DashboardFormField> ProductFormFields { get; set; } = new List<DashboardFormField>
        {
            new DashboardFormField { Id = "ProdName", Name = "CurrentProduct.Name", Label = "Product Name *", Type = "text", Placeholder = "Enter product name...", IsRequired = true },
            new DashboardFormField { Id = "ProdCategory", Name = "CurrentProduct.CategoryName", Label = "Category", Type = "select", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "ProdPrice", Name = "CurrentProduct.Price", Label = "Price ($) *", Type = "number", Placeholder = "", IsRequired = true, Min = "0", Step = "0.01", Value = "0.00" },
            new DashboardFormField { Id = "ProdStock", Name = "CurrentProduct.StockQuantity", Label = "Stock *", Type = "number", Placeholder = "", IsRequired = true, Min = "0", Value = "50" },
            new DashboardFormField { Id = "ProdInformation", Name = "CurrentProduct.ProductInformation", Label = "Product Information", Type = "textarea", Placeholder = "Brief product overview...", IsRequired = false, Rows = "3" },
            new DashboardFormField { Id = "ProdDetail", Name = "CurrentProduct.ProductDetail", Label = "Product Detail", Type = "textarea", Placeholder = "Detailed product descriptions...", IsRequired = false, Rows = "3" },
            new DashboardFormField { Id = "ProdMaterialAndCare", Name = "CurrentProduct.MaterialAndCare", Label = "Material and Care", Type = "textarea", Placeholder = "Materials, dimensions, care instructions...", IsRequired = false, Rows = "3" },
            new DashboardFormField { Id = "ProdIsSizeEnabled", Name = "CurrentProduct.IsSizeEnabled", Label = "Enable Size Selection", Type = "checkbox", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "ProdIsSizeChartEnabled", Name = "CurrentProduct.IsSizeChartEnabled", Label = "Enable Size Chart Guide", Type = "checkbox", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "ProdIsFeatured", Name = "CurrentProduct.IsFeatured", Label = "Is Featured Product", Type = "checkbox", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "ProdIsNew", Name = "CurrentProduct.IsNew", Label = "Is New Product", Type = "checkbox", Placeholder = "", IsRequired = false },
            new DashboardFormField { Id = "ProductImageUpload", Name = "ProductImageUploads", Label = "Product Images (Select multiple files to make slide gallery)", Type = "file", Placeholder = "", IsRequired = false }
        };

        public List<AdminEventDto> Events { get; set; } = new List<AdminEventDto>();

        [BindProperty]
        public AdminEventDto CurrentEvent { get; set; } = new AdminEventDto();

        // ── Shop Products ────────────────────────────────────────────────────
        public List<AdminProductDto> Products { get; set; } = new List<AdminProductDto>();
        public List<AdminProductDto> Shop2Products { get; set; } = new List<AdminProductDto>();
        public List<AdminCategoryDto> ShopCategories { get; set; } = new List<AdminCategoryDto>();

        [BindProperty]
        public AdminProductDto CurrentProduct { get; set; } = new AdminProductDto();

        // ── Overview Stats ───────────────────────────────────────────────────
        [BindProperty(SupportsGet = true)]
        public int Days { get; set; } = 30;

        public int TotalShopOrders { get; set; }
        public decimal TotalShopRevenue { get; set; }
        public int TotalTicketsSold { get; set; }
        public decimal TotalTicketRevenue { get; set; }
        public int TotalMemberships { get; set; }
        public decimal TotalMembershipRevenue { get; set; }
        public decimal TotalRevenue { get; set; }
        public int TotalEvents { get; set; }
        public int TotalProducts { get; set; }
        public int TotalShop2Products { get; set; }

        // Pending Orders Properties
        public int TotalPendingOrders { get; set; }
        public List<AdminPendingOrderDto> PendingOrders { get; set; } = new List<AdminPendingOrderDto>();

        // Payments, Refunds, and Contacts Properties
        public List<PendingPaymentDto> PendingPayments { get; set; } = new List<PendingPaymentDto>();
        public List<RefundRequestDto> RefundRequests { get; set; } = new List<RefundRequestDto>();
        public List<ContactMessageDto> ContactMessages { get; set; } = new List<ContactMessageDto>();
        public List<DonationDto> Donations { get; set; } = new List<DonationDto>();

        public void OnGet()
        {
            LoadEvents();
            LoadProducts();
            LoadShop2Products();
            LoadStats();
            LoadPendingOrders();
            LoadPendingPayments();
            LoadRefundRequests();
            LoadContactMessages();
            LoadDonations();
            SyncProductsToJs();
        }

        // ════════════════════════════════════════════════════════════════════
        // DATA LOADING
        // ════════════════════════════════════════════════════════════════════

        private void LoadStats()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            // Validate days range
            int days = Days > 0 ? Days : 30;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Shop orders count & revenue (filtered by days)
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand(
                            @"SELECT ISNULL(COUNT(*),0), ISNULL(SUM(TotalAmount),0)
                              FROM Orders
                              WHERE OrderType='Shop' AND PaymentStatus='Completed'
                                AND OrderDate >= DATEADD(day, -@Days, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Days", days);
                            using (SqlDataReader r = cmd.ExecuteReader())
                                if (r.Read()) { TotalShopOrders = r.GetInt32(0); TotalShopRevenue = r.GetDecimal(1); }
                        }
                    }
                    catch { }

                    // Ticket stats from OrderItems & Orders tables (filtered by days)
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand(
                            @"SELECT ISNULL(SUM(oi.Quantity),0), ISNULL(SUM(oi.Quantity * oi.UnitPrice),0)
                              FROM OrderItems oi
                              INNER JOIN Orders o ON oi.OrderId = o.OrderId
                              WHERE o.OrderType='Ticket' AND o.PaymentStatus='Completed'
                                AND o.OrderDate >= DATEADD(day, -@Days, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Days", days);
                            using (SqlDataReader r = cmd.ExecuteReader())
                                if (r.Read()) { TotalTicketsSold = r.GetInt32(0); TotalTicketRevenue = r.GetDecimal(1); }
                        }
                    }
                    catch { }

                    // Membership stats (filtered by days via Orders)
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand(
                            @"SELECT ISNULL(COUNT(*),0), ISNULL(SUM(mt.Price),0)
                              FROM UserMemberships um
                              JOIN MembershipTypes mt ON um.MembershipTypeId = mt.MembershipTypeId
                              WHERE um.StartDate >= DATEADD(day, -@Days, GETDATE())", conn))
                        {
                            cmd.Parameters.AddWithValue("@Days", days);
                            using (SqlDataReader r = cmd.ExecuteReader())
                                if (r.Read()) { TotalMemberships = r.GetInt32(0); TotalMembershipRevenue = r.GetDecimal(1); }
                        }
                    }
                    catch { }

                    // Total events (not date-filtered — shows all)
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand("SELECT COUNT(*) FROM Events", conn))
                        {
                            var r = cmd.ExecuteScalar();
                            if (r != null) TotalEvents = (int)r;
                        }
                    }
                    catch { }

                    // Total active products for Shop 1 (not date-filtered)
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand("SELECT COUNT(*) FROM ShopProducts WHERE IsActive=1 AND IsShop2=0", conn))
                        {
                            var r = cmd.ExecuteScalar();
                            if (r != null) TotalProducts = (int)r;
                        }
                    }
                    catch { }

                    // Total active products for Shop 2 (not date-filtered)
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand("SELECT COUNT(*) FROM ShopProducts WHERE IsActive=1 AND IsShop2=1", conn))
                        {
                            var r = cmd.ExecuteScalar();
                            if (r != null) TotalShop2Products = (int)r;
                        }
                    }
                    catch { }
                    // Subtract completed refunds from category revenues
                    decimal shopRefunds = 0;
                    decimal ticketRefunds = 0;
                    decimal memberRefunds = 0;
                    try
                    {
                        using (SqlCommand cmd = new SqlCommand(
                            @"SELECT 
                                 CASE 
                                     WHEN o.OrderType = 'Shop' THEN 'shop'
                                     WHEN o.OrderType = 'Membership' THEN 'member'
                                     ELSE 'ticket'
                                 END AS Type, 
                                 SUM(r.RefundAmount) 
                             FROM Refunds r
                             INNER JOIN Orders o ON r.OrderId = o.OrderId
                             WHERE r.Status = 'Completed' AND r.RequestedAt >= DATEADD(day, -@Days, GETDATE()) 
                             GROUP BY o.OrderType", conn))
                        {
                            cmd.Parameters.AddWithValue("@Days", days);
                            using (SqlDataReader r = cmd.ExecuteReader())
                            {
                                while (r.Read())
                                {
                                    string rType = r.GetString(0).ToLower();
                                    decimal amt = r.GetDecimal(1);
                                    if (rType == "shop") shopRefunds = amt;
                                    else if (rType == "ticket") ticketRefunds = amt;
                                    else if (rType == "member" || rType == "membership") memberRefunds = amt;
                                }
                            }
                        }
                    }
                    catch { }

                    TotalShopRevenue -= shopRefunds;
                    TotalTicketRevenue -= ticketRefunds;
                    TotalMembershipRevenue -= memberRefunds;
                }
            }
            catch { }

            TotalRevenue = TotalShopRevenue + TotalTicketRevenue + TotalMembershipRevenue;
        }

        private void LoadEvents()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = "SELECT EventId, Title, Description, EventDate, Capacity, BasePrice, ImagePath, WhatToExpect, EventDetails, Sponsors, Location, Status FROM Events ORDER BY EventDate DESC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        conn.Open();
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                Events.Add(new AdminEventDto
                                {
                                    EventId = reader.GetInt32(0),
                                    Title = reader.GetString(1),
                                    Description = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                    EventDate = reader.GetDateTime(3),
                                    Capacity = reader.IsDBNull(4) ? 0 : reader.GetInt32(4),
                                    BasePrice = reader.IsDBNull(5) ? 0 : reader.GetDecimal(5),
                                    ImagePath = reader.IsDBNull(6) ? "" : reader.GetString(6),
                                    WhatToExpect = reader.IsDBNull(7) ? "" : reader.GetString(7),
                                    EventDetails = reader.IsDBNull(8) ? "" : reader.GetString(8),
                                    Sponsors = reader.IsDBNull(9) ? "" : reader.GetString(9),
                                    Location = reader.IsDBNull(10) ? "" : reader.GetString(10),
                                    Status = reader.IsDBNull(11) ? "Active" : reader.GetString(11)
                                });
                            }
                        }
                    }
                }
            }
            catch { }
        }

        private void LoadProducts()
        {
            // Cache categories
            string catCacheKey = "ShopCategories_Cache";
            if (!_cache.TryGetValue(catCacheKey, out List<AdminCategoryDto> cachedCats))
            {
                cachedCats = new List<AdminCategoryDto>();
                string connStr = _configuration.GetConnectionString("DefaultConnection");
                if (!string.IsNullOrEmpty(connStr))
                {
                    try
                    {
                        using (SqlConnection conn = new SqlConnection(connStr))
                        {
                            conn.Open();
                            using (SqlCommand cmd = new SqlCommand(
                                "SELECT CategoryId, Name FROM ShopCategories WHERE IsActive=1 ORDER BY SortOrder", conn))
                            using (SqlDataReader r = cmd.ExecuteReader())
                            {
                                while (r.Read())
                                    cachedCats.Add(new AdminCategoryDto { CategoryId = r.GetInt32(0), Name = r.GetString(1) });
                            }
                        }
                    }
                    catch { }
                }
                _cache.Set(catCacheKey, cachedCats, TimeSpan.FromMinutes(10));
            }
            ShopCategories = cachedCats;

            // Cache Shop 1 products
            string p1CacheKey = "Shop1Products_Cache";
            if (!_cache.TryGetValue(p1CacheKey, out List<AdminProductDto> cachedP1))
            {
                cachedP1 = new List<AdminProductDto>();
                string connStr = _configuration.GetConnectionString("DefaultConnection");
                if (!string.IsNullOrEmpty(connStr))
                {
                    try
                    {
                        using (SqlConnection conn = new SqlConnection(connStr))
                        {
                            conn.Open();
                            string sql = @"SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, 
                                                  ISNULL(c.Name, 'Uncategorized'), ISNULL(p.ImagePath, ''),
                                                  ISNULL(p.ProductInformation, ''), ISNULL(p.ProductDetail, ''), 
                                                  ISNULL(p.MaterialAndCare, ''), ISNULL(p.AdditionalImages, ''),
                                                  p.IsSizeEnabled, p.IsSizeChartEnabled, p.IsFeatured, p.IsNew
                                           FROM ShopProducts p
                                           LEFT JOIN ShopCategories c ON p.CategoryId = c.CategoryId
                                           WHERE p.IsActive = 1 AND p.IsShop2 = 0
                                           ORDER BY p.Name";
                            using (SqlCommand cmd = new SqlCommand(sql, conn))
                            using (SqlDataReader r = cmd.ExecuteReader())
                            {
                                while (r.Read())
                                {
                                    cachedP1.Add(new AdminProductDto
                                    {
                                        ProductId = r.GetInt32(0),
                                        Name = r.GetString(1),
                                        Description = r.IsDBNull(2) ? "" : r.GetString(2),
                                        Price = r.GetDecimal(3),
                                        StockQuantity = r.IsDBNull(4) ? 0 : r.GetInt32(4),
                                        CategoryName = r.GetString(5),
                                        ImagePath = r.GetString(6),
                                        ProductInformation = r.GetString(7),
                                        ProductDetail = r.GetString(8),
                                        MaterialAndCare = r.GetString(9),
                                        AdditionalImages = r.GetString(10),
                                        IsSizeEnabled = r.IsDBNull(11) ? false : r.GetBoolean(11),
                                        IsSizeChartEnabled = r.IsDBNull(12) ? false : r.GetBoolean(12),
                                        IsFeatured = r.IsDBNull(13) ? false : r.GetBoolean(13),
                                        IsNew = r.IsDBNull(14) ? false : r.GetBoolean(14)
                                    });
                                }
                            }
                        }
                    }
                    catch { }
                }
                _cache.Set(p1CacheKey, cachedP1, TimeSpan.FromMinutes(10));
            }
            Products = cachedP1;
        }

        private void LoadShop2Products()
        {
            // Cache Shop 2 products
            string p2CacheKey = "Shop2Products_Cache";
            if (!_cache.TryGetValue(p2CacheKey, out List<AdminProductDto> cachedP2))
            {
                cachedP2 = new List<AdminProductDto>();
                string connStr = _configuration.GetConnectionString("DefaultConnection");
                if (!string.IsNullOrEmpty(connStr))
                {
                    try
                    {
                        using (SqlConnection conn = new SqlConnection(connStr))
                        {
                            conn.Open();
                            string sql = @"SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, 
                                                  ISNULL(c.Name, 'Uncategorized'), ISNULL(p.ImagePath, ''),
                                                  ISNULL(p.ProductInformation, ''), ISNULL(p.ProductDetail, ''), 
                                                  ISNULL(p.MaterialAndCare, ''), ISNULL(p.AdditionalImages, ''),
                                                  p.IsSizeEnabled, p.IsSizeChartEnabled, p.IsFeatured, p.IsNew
                                           FROM ShopProducts p
                                           LEFT JOIN ShopCategories c ON p.CategoryId = c.CategoryId
                                           WHERE p.IsActive = 1 AND p.IsShop2 = 1
                                           ORDER BY p.Name";
                            using (SqlCommand cmd = new SqlCommand(sql, conn))
                            using (SqlDataReader r = cmd.ExecuteReader())
                            {
                                while (r.Read())
                                {
                                    cachedP2.Add(new AdminProductDto
                                    {
                                        ProductId = r.GetInt32(0),
                                        Name = r.GetString(1),
                                        Description = r.IsDBNull(2) ? "" : r.GetString(2),
                                        Price = r.GetDecimal(3),
                                        StockQuantity = r.IsDBNull(4) ? 0 : r.GetInt32(4),
                                        CategoryName = r.GetString(5),
                                        ImagePath = r.GetString(6),
                                        ProductInformation = r.GetString(7),
                                        ProductDetail = r.GetString(8),
                                        MaterialAndCare = r.GetString(9),
                                        AdditionalImages = r.GetString(10),
                                        IsSizeEnabled = r.IsDBNull(11) ? false : r.GetBoolean(11),
                                        IsSizeChartEnabled = r.IsDBNull(12) ? false : r.GetBoolean(12),
                                        IsFeatured = r.IsDBNull(13) ? false : r.GetBoolean(13),
                                        IsNew = r.IsDBNull(14) ? false : r.GetBoolean(14)
                                    });
                                }
                            }
                        }
                    }
                    catch { }
                }
                _cache.Set(p2CacheKey, cachedP2, TimeSpan.FromMinutes(10));
            }
            Shop2Products = cachedP2;
        }

        // ════════════════════════════════════════════════════════════════════
        // EVENT HANDLERS
        // ════════════════════════════════════════════════════════════════════

        public IActionResult OnPostDelete(int id)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = "DELETE FROM Events WHERE EventId = @Id";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", id);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException ex)
            {
                TempData["ErrorMessage"] = ex.Message.Contains("LỖI")
                    ? ex.Message
                    : "Cannot delete this event. It may have existing bookings or sales records.";
            }
            return RedirectToPage("/AdminDashboard");
        }

        public async Task<IActionResult> OnPostSaveAsync(IFormFile ImageUpload)
        {
            if (string.IsNullOrWhiteSpace(CurrentEvent.Title))
            {
                TempData["ErrorMessage"] = "Event title is required.";
                return RedirectToPage("/AdminDashboard");
            }
            if (CurrentEvent.BasePrice < 0)
            {
                TempData["ErrorMessage"] = "Base price cannot be negative.";
                return RedirectToPage("/AdminDashboard");
            }
            if (CurrentEvent.Capacity < 0)
            {
                TempData["ErrorMessage"] = "Capacity cannot be negative.";
                return RedirectToPage("/AdminDashboard");
            }

            string imagePathToSave = null;
            if (ImageUpload != null && ImageUpload.Length > 0)
            {
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
                var fileExtension = Path.GetExtension(ImageUpload.FileName).ToLowerInvariant();
                if (!allowedExtensions.Contains(fileExtension))
                {
                    TempData["ErrorMessage"] = "Invalid file type. Only image files (.jpg, .png, .webp, .gif) are allowed.";
                    return RedirectToPage("/AdminDashboard");
                }
                if (ImageUpload.Length > 5 * 1024 * 1024)
                {
                    TempData["ErrorMessage"] = "Image file size cannot exceed 5MB.";
                    return RedirectToPage("/AdminDashboard");
                }

                var uploadsFolder = Path.Combine(_env.WebRootPath, "images", "events");
                if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

                var uniqueFileName = Guid.NewGuid().ToString() + fileExtension;
                var filePath = Path.Combine(uploadsFolder, uniqueFileName);
                using (var stream = new FileStream(filePath, FileMode.Create))
                    await ImageUpload.CopyToAsync(stream);

                imagePathToSave = "/images/events/" + uniqueFileName;
            }

            string connString = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connString))
                {
                    string sql;
                    if (CurrentEvent.EventId == 0)
                        sql = @"INSERT INTO Events (Title, Description, EventDate, Capacity, BasePrice, ImagePath, WhatToExpect, EventDetails, Sponsors, Location, Status) 
                                VALUES (@Title, @Description, @EventDate, @Capacity, @BasePrice, @ImagePath, @WhatToExpect, @EventDetails, @Sponsors, @Location, @Status)";
                    else if (imagePathToSave != null)
                        sql = @"UPDATE Events SET Title=@Title, Description=@Description, EventDate=@EventDate, 
                                Capacity=@Capacity, BasePrice=@BasePrice, ImagePath=@ImagePath,
                                WhatToExpect=@WhatToExpect, EventDetails=@EventDetails, Sponsors=@Sponsors,
                                Location=@Location, Status=@Status WHERE EventId=@EventId";
                    else
                        sql = @"UPDATE Events SET Title=@Title, Description=@Description, EventDate=@EventDate, 
                                Capacity=@Capacity, BasePrice=@BasePrice,
                                WhatToExpect=@WhatToExpect, EventDetails=@EventDetails, Sponsors=@Sponsors,
                                Location=@Location, Status=@Status WHERE EventId=@EventId";

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        if (CurrentEvent.EventId > 0) cmd.Parameters.AddWithValue("@EventId", CurrentEvent.EventId);
                        cmd.Parameters.AddWithValue("@Title", CurrentEvent.Title ?? "");
                        cmd.Parameters.AddWithValue("@Description", CurrentEvent.Description ?? "");
                        cmd.Parameters.AddWithValue("@EventDate", CurrentEvent.EventDate);
                        cmd.Parameters.AddWithValue("@Capacity", CurrentEvent.Capacity);
                        cmd.Parameters.AddWithValue("@BasePrice", CurrentEvent.BasePrice);
                        cmd.Parameters.AddWithValue("@WhatToExpect", CurrentEvent.WhatToExpect ?? "");
                        cmd.Parameters.AddWithValue("@EventDetails", CurrentEvent.EventDetails ?? "");
                        cmd.Parameters.AddWithValue("@Sponsors", CurrentEvent.Sponsors ?? "");
                        cmd.Parameters.AddWithValue("@Location", CurrentEvent.Location ?? "");
                        cmd.Parameters.AddWithValue("@Status", CurrentEvent.Status ?? "Active");
                        if (imagePathToSave != null || CurrentEvent.EventId == 0)
                            cmd.Parameters.AddWithValue("@ImagePath", imagePathToSave ?? (object)DBNull.Value);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                        TempData["SaveSuccess"] = CurrentEvent.EventId == 0 
                            ? "Event has been created successfully." 
                            : "Event has been updated successfully.";
                    }
                }
            }
            catch (SqlException)
            {
                TempData["ErrorMessage"] = "Unable to save event. Please check your input and try again.";
            }
            return RedirectToPage("/AdminDashboard", new { section = "events" });
        }

        // ════════════════════════════════════════════════════════════════════
        // SHOP PRODUCT HANDLERS
        // ════════════════════════════════════════════════════════════════════

        public IActionResult OnPostDeleteProduct(int id)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    using (SqlCommand cmd = new SqlCommand("UPDATE ShopProducts SET IsActive=0 WHERE ProductId=@Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", id);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException ex)
            {
                TempData["ErrorMessage"] = "Cannot delete product: " + ex.Message;
            }
            _cache.Remove("Shop1Products_Cache");
            SyncProductsToJs();
            return RedirectToPage("/AdminDashboard", new { section = "shop" });
        }

        public IActionResult OnPostDeleteProduct2(int id)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    using (SqlCommand cmd = new SqlCommand("UPDATE ShopProducts SET IsActive=0 WHERE ProductId=@Id", conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", id);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException ex)
            {
                TempData["ErrorMessage"] = "Cannot delete product: " + ex.Message;
            }
            _cache.Remove("Shop2Products_Cache");
            SyncProductsToJs();
            return RedirectToPage("/AdminDashboard", new { section = "shop2" });
        }

        public async Task<IActionResult> OnPostSaveProductAsync(IFormFileCollection ProductImageUploads)
        {
            if (string.IsNullOrWhiteSpace(CurrentProduct.Name))
            {
                TempData["ErrorMessage"] = "Product name is required.";
                return RedirectToPage("/AdminDashboard", new { section = "shop" });
            }
            if (CurrentProduct.Price < 0)
            {
                TempData["ErrorMessage"] = "Price cannot be negative.";
                return RedirectToPage("/AdminDashboard", new { section = "shop" });
            }

            string imagePathToSave = null;
            string additionalImagesToSave = null;

            if (ProductImageUploads != null && ProductImageUploads.Count > 0)
            {
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
                var uploadedPaths = new List<string>();

                foreach (var file in ProductImageUploads)
                {
                    if (file.Length > 0)
                    {
                        var fileExt = Path.GetExtension(file.FileName).ToLowerInvariant();
                        if (!allowedExtensions.Contains(fileExt))
                        {
                            TempData["ErrorMessage"] = "Invalid image type. Only image files (.jpg, .png, .webp, .gif) are allowed.";
                            return RedirectToPage("/AdminDashboard", new { section = "shop" });
                        }
                        if (file.Length > 5 * 1024 * 1024)
                        {
                            TempData["ErrorMessage"] = "Each image cannot exceed 5MB.";
                            return RedirectToPage("/AdminDashboard", new { section = "shop" });
                        }

                        var uploadsFolder = Path.Combine(_env.WebRootPath, "images", "shop");
                        if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
                        var uniqueFileName = Guid.NewGuid().ToString() + fileExt;
                        using (var stream = new FileStream(Path.Combine(uploadsFolder, uniqueFileName), FileMode.Create))
                            await file.CopyToAsync(stream);

                        uploadedPaths.Add("/images/shop/" + uniqueFileName);
                    }
                }

                if (uploadedPaths.Count > 0)
                {
                    imagePathToSave = uploadedPaths[0];
                    additionalImagesToSave = string.Join(",", uploadedPaths);
                }
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Resolve category ID
                    int catId = 1;
                    if (!string.IsNullOrEmpty(CurrentProduct.CategoryName))
                    {
                        using (SqlCommand catCmd = new SqlCommand(
                            "SELECT TOP 1 CategoryId FROM ShopCategories WHERE Name=@Name", conn))
                        {
                            catCmd.Parameters.AddWithValue("@Name", CurrentProduct.CategoryName);
                            var r = catCmd.ExecuteScalar();
                            if (r != null) catId = (int)r;
                        }
                    }

                    string sql;
                    if (CurrentProduct.ProductId == 0)
                    {
                        sql = @"INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, ImagePath, ProductInformation, ProductDetail, MaterialAndCare, AdditionalImages, IsSizeEnabled, IsSizeChartEnabled, IsFeatured, IsNew, IsActive, IsShop2, Slug, PageSlug)
                                VALUES (@CatId, @Name, @Desc, @Price, @Stock, @Image, @Info, @Detail, @Care, @AddImages, @IsSizeEnabled, @IsSizeChartEnabled, @IsFeatured, @IsNew, 1, 0, @Slug, @Slug)";
                    }
                    else
                    {
                        if (imagePathToSave != null)
                        {
                            sql = @"UPDATE ShopProducts SET CategoryId=@CatId, Name=@Name, Description=@Desc, 
                                    Price=@Price, StockQuantity=@Stock, ImagePath=@Image,
                                    ProductInformation=@Info, ProductDetail=@Detail, MaterialAndCare=@Care, AdditionalImages=@AddImages,
                                    IsSizeEnabled=@IsSizeEnabled, IsSizeChartEnabled=@IsSizeChartEnabled, IsFeatured=@IsFeatured, IsNew=@IsNew,
                                    Slug=@Slug, PageSlug=@Slug
                                    WHERE ProductId=@ProductId";
                        }
                        else
                        {
                            sql = @"UPDATE ShopProducts SET CategoryId=@CatId, Name=@Name, Description=@Desc, 
                                    Price=@Price, StockQuantity=@Stock,
                                    ProductInformation=@Info, ProductDetail=@Detail, MaterialAndCare=@Care,
                                    IsSizeEnabled=@IsSizeEnabled, IsSizeChartEnabled=@IsSizeChartEnabled, IsFeatured=@IsFeatured, IsNew=@IsNew,
                                    Slug=@Slug, PageSlug=@Slug
                                    WHERE ProductId=@ProductId";
                        }
                    }

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        if (CurrentProduct.ProductId > 0) cmd.Parameters.AddWithValue("@ProductId", CurrentProduct.ProductId);
                        cmd.Parameters.AddWithValue("@CatId", catId);
                        cmd.Parameters.AddWithValue("@Name", CurrentProduct.Name ?? "");
                        cmd.Parameters.AddWithValue("@Desc", CurrentProduct.Description ?? "");
                        cmd.Parameters.AddWithValue("@Price", CurrentProduct.Price);
                        cmd.Parameters.AddWithValue("@Stock", CurrentProduct.StockQuantity);
                        cmd.Parameters.AddWithValue("@Info", CurrentProduct.ProductInformation ?? "");
                        cmd.Parameters.AddWithValue("@Detail", CurrentProduct.ProductDetail ?? "");
                        cmd.Parameters.AddWithValue("@Care", CurrentProduct.MaterialAndCare ?? "");
                        cmd.Parameters.AddWithValue("@IsSizeEnabled", CurrentProduct.IsSizeEnabled);
                        cmd.Parameters.AddWithValue("@IsSizeChartEnabled", CurrentProduct.IsSizeChartEnabled);
                        cmd.Parameters.AddWithValue("@IsFeatured", CurrentProduct.IsFeatured);
                        cmd.Parameters.AddWithValue("@IsNew", CurrentProduct.IsNew);
                        cmd.Parameters.AddWithValue("@Slug", Slugify(CurrentProduct.Name));
                        if (imagePathToSave != null || CurrentProduct.ProductId == 0)
                        {
                            cmd.Parameters.AddWithValue("@Image", imagePathToSave ?? (object)DBNull.Value);
                            cmd.Parameters.AddWithValue("@AddImages", additionalImagesToSave ?? (object)DBNull.Value);
                        }
                        cmd.ExecuteNonQuery();
                        TempData["SaveSuccess"] = CurrentProduct.ProductId == 0
                            ? "Product has been created successfully."
                            : "Product has been updated successfully.";
                    }
                }
            }
            catch (SqlException ex)
            {
                TempData["ErrorMessage"] = "Unable to save product: " + ex.Message;
            }
            _cache.Remove("Shop1Products_Cache");
            SyncProductsToJs();
            return RedirectToPage("/AdminDashboard", new { section = "shop" });
        }

        public async Task<IActionResult> OnPostSaveProduct2Async(IFormFileCollection ProductImageUploads)
        {
            if (string.IsNullOrWhiteSpace(CurrentProduct.Name))
            {
                TempData["ErrorMessage"] = "Product name is required.";
                return RedirectToPage("/AdminDashboard", new { section = "shop2" });
            }
            if (CurrentProduct.Price < 0)
            {
                TempData["ErrorMessage"] = "Price cannot be negative.";
                return RedirectToPage("/AdminDashboard", new { section = "shop2" });
            }

            string imagePathToSave = null;
            string additionalImagesToSave = null;

            if (ProductImageUploads != null && ProductImageUploads.Count > 0)
            {
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
                var uploadedPaths = new List<string>();

                foreach (var file in ProductImageUploads)
                {
                    if (file.Length > 0)
                    {
                        var fileExt = Path.GetExtension(file.FileName).ToLowerInvariant();
                        if (!allowedExtensions.Contains(fileExt))
                        {
                            TempData["ErrorMessage"] = "Invalid image type. Only image files (.jpg, .png, .webp, .gif) are allowed.";
                            return RedirectToPage("/AdminDashboard", new { section = "shop2" });
                        }
                        if (file.Length > 5 * 1024 * 1024)
                        {
                            TempData["ErrorMessage"] = "Each image cannot exceed 5MB.";
                            return RedirectToPage("/AdminDashboard", new { section = "shop2" });
                        }

                        var uploadsFolder = Path.Combine(_env.WebRootPath, "images", "shop");
                        if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);
                        var uniqueFileName = Guid.NewGuid().ToString() + fileExt;
                        using (var stream = new FileStream(Path.Combine(uploadsFolder, uniqueFileName), FileMode.Create))
                            await file.CopyToAsync(stream);

                        uploadedPaths.Add("/images/shop/" + uniqueFileName);
                    }
                }

                if (uploadedPaths.Count > 0)
                {
                    imagePathToSave = uploadedPaths[0];
                    additionalImagesToSave = string.Join(",", uploadedPaths);
                }
            }

            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Resolve category ID
                    int catId = 1;
                    if (!string.IsNullOrEmpty(CurrentProduct.CategoryName))
                    {
                        using (SqlCommand catCmd = new SqlCommand(
                            "SELECT TOP 1 CategoryId FROM ShopCategories WHERE Name=@Name", conn))
                        {
                            catCmd.Parameters.AddWithValue("@Name", CurrentProduct.CategoryName);
                            var r = catCmd.ExecuteScalar();
                            if (r != null) catId = (int)r;
                        }
                    }

                    string sql;
                    if (CurrentProduct.ProductId == 0)
                    {
                        sql = @"INSERT INTO ShopProducts (CategoryId, Name, Description, Price, StockQuantity, ImagePath, ProductInformation, ProductDetail, MaterialAndCare, AdditionalImages, IsSizeEnabled, IsSizeChartEnabled, IsFeatured, IsNew, IsActive, IsShop2, Slug, PageSlug)
                                VALUES (@CatId, @Name, @Desc, @Price, @Stock, @Image, @Info, @Detail, @Care, @AddImages, @IsSizeEnabled, @IsSizeChartEnabled, @IsFeatured, @IsNew, 1, 1, @Slug, @Slug)";
                    }
                    else
                    {
                        if (imagePathToSave != null)
                        {
                            sql = @"UPDATE ShopProducts SET CategoryId=@CatId, Name=@Name, Description=@Desc, 
                                    Price=@Price, StockQuantity=@Stock, ImagePath=@Image,
                                    ProductInformation=@Info, ProductDetail=@Detail, MaterialAndCare=@Care, AdditionalImages=@AddImages,
                                    IsSizeEnabled=@IsSizeEnabled, IsSizeChartEnabled=@IsSizeChartEnabled, IsFeatured=@IsFeatured, IsNew=@IsNew,
                                    Slug=@Slug, PageSlug=@Slug
                                    WHERE ProductId=@ProductId";
                        }
                        else
                        {
                            sql = @"UPDATE ShopProducts SET CategoryId=@CatId, Name=@Name, Description=@Desc, 
                                    Price=@Price, StockQuantity=@Stock,
                                    ProductInformation=@Info, ProductDetail=@Detail, MaterialAndCare=@Care,
                                    IsSizeEnabled=@IsSizeEnabled, IsSizeChartEnabled=@IsSizeChartEnabled, IsFeatured=@IsFeatured, IsNew=@IsNew,
                                    Slug=@Slug, PageSlug=@Slug
                                    WHERE ProductId=@ProductId";
                        }
                    }

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        if (CurrentProduct.ProductId > 0) cmd.Parameters.AddWithValue("@ProductId", CurrentProduct.ProductId);
                        cmd.Parameters.AddWithValue("@CatId", catId);
                        cmd.Parameters.AddWithValue("@Name", CurrentProduct.Name ?? "");
                        cmd.Parameters.AddWithValue("@Desc", CurrentProduct.Description ?? "");
                        cmd.Parameters.AddWithValue("@Price", CurrentProduct.Price);
                        cmd.Parameters.AddWithValue("@Stock", CurrentProduct.StockQuantity);
                        cmd.Parameters.AddWithValue("@Info", CurrentProduct.ProductInformation ?? "");
                        cmd.Parameters.AddWithValue("@Detail", CurrentProduct.ProductDetail ?? "");
                        cmd.Parameters.AddWithValue("@Care", CurrentProduct.MaterialAndCare ?? "");
                        cmd.Parameters.AddWithValue("@IsSizeEnabled", CurrentProduct.IsSizeEnabled);
                        cmd.Parameters.AddWithValue("@IsSizeChartEnabled", CurrentProduct.IsSizeChartEnabled);
                        cmd.Parameters.AddWithValue("@IsFeatured", CurrentProduct.IsFeatured);
                        cmd.Parameters.AddWithValue("@IsNew", CurrentProduct.IsNew);
                        cmd.Parameters.AddWithValue("@Slug", Slugify(CurrentProduct.Name));
                        if (imagePathToSave != null || CurrentProduct.ProductId == 0)
                        {
                            cmd.Parameters.AddWithValue("@Image", imagePathToSave ?? (object)DBNull.Value);
                            cmd.Parameters.AddWithValue("@AddImages", additionalImagesToSave ?? (object)DBNull.Value);
                        }
                        cmd.ExecuteNonQuery();
                        TempData["SaveSuccess"] = CurrentProduct.ProductId == 0
                             ? "Product has been created successfully."
                             : "Product has been updated successfully.";
                    }
                }
            }
            catch (SqlException ex)
            {
                TempData["ErrorMessage"] = "Unable to save product: " + ex.Message;
            }
            _cache.Remove("Shop2Products_Cache");
            SyncProductsToJs();
            return RedirectToPage("/AdminDashboard", new { section = "shop2" });
        }

        public IActionResult OnPostApproveOrder(int id)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    string sql = "UPDATE Orders SET PaymentStatus = 'Completed' WHERE OrderId = @Id";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        cmd.Parameters.AddWithValue("@Id", id);
                        conn.Open();
                        cmd.ExecuteNonQuery();
                    }
                }
            }
            catch (SqlException ex)
            {
                TempData["ErrorMessage"] = "Cannot approve order: " + ex.Message;
            }
            return RedirectToPage("/AdminDashboard", new { section = "pending" });
        }

        public async Task<IActionResult> OnPostCompleteRefundAsync(int refundId)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return RedirectToPage();

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    await conn.OpenAsync();

                    int orderId = 0;
                    string txRef = "";
                    decimal amount = 0;
                    string type = "";

                    // 1. Get refund request details
                    string selectSql = @"
                        SELECT r.OrderId, r.TransactionRef, r.RefundAmount, 
                               CASE 
                                   WHEN o.OrderType = 'Shop' THEN 'shop'
                                   WHEN o.OrderType = 'Membership' THEN 'member'
                                   ELSE 'ticket'
                               END AS Type
                        FROM Refunds r
                        INNER JOIN Orders o ON r.OrderId = o.OrderId
                        WHERE r.RefundId = @RefundId";
                    using (SqlCommand cmd = new SqlCommand(selectSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@RefundId", refundId);
                        using (var reader = await cmd.ExecuteReaderAsync())
                        {
                            if (reader.Read())
                            {
                                orderId = reader.IsDBNull(0) ? 0 : reader.GetInt32(0);
                                txRef = reader.IsDBNull(1) ? "" : reader.GetString(1);
                                amount = reader.GetDecimal(2);
                                type = reader.GetString(3);
                            }
                        }
                    }

                    // 2. Update refund request to complete
                    string updateRefundSql = "UPDATE Refunds SET Status = 'Completed', CompletedAt = GETDATE(), ProcessedAt = GETDATE() WHERE RefundId = @RefundId";
                    using (SqlCommand cmd = new SqlCommand(updateRefundSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@RefundId", refundId);
                        await cmd.ExecuteNonQueryAsync();
                    }

                    // 3. Update Order PaymentStatus to 'Refunded'
                    if (orderId > 0)
                    {
                        string updateOrderSql = "UPDATE Orders SET PaymentStatus = 'Refunded' WHERE OrderId = @OrderId";
                        using (SqlCommand cmd = new SqlCommand(updateOrderSql, conn))
                        {
                            cmd.Parameters.AddWithValue("@OrderId", orderId);
                            await cmd.ExecuteNonQueryAsync();
                        }
                    }
                    else if (!string.IsNullOrEmpty(txRef))
                    {
                        string updateOrderSql = "UPDATE Orders SET PaymentStatus = 'Refunded' WHERE TransactionRef = @TxRef";
                        using (SqlCommand cmd = new SqlCommand(updateOrderSql, conn))
                        {
                            cmd.Parameters.AddWithValue("@TxRef", txRef);
                            await cmd.ExecuteNonQueryAsync();
                        }
                    }

                    // 4. Update PaymentLog Status to 'Refunded'
                    string updateLogSql = "UPDATE PaymentLog SET Status = 'Refunded' WHERE OrderId = @OrderId OR (TransactionRef = @TxRef AND @TxRef != '')";
                    using (SqlCommand cmd = new SqlCommand(updateLogSql, conn))
                    {
                        cmd.Parameters.AddWithValue("@OrderId", orderId);
                        cmd.Parameters.AddWithValue("@TxRef", txRef ?? "");
                        await cmd.ExecuteNonQueryAsync();
                    }



                    TempData["RefundSuccess"] = $"Refund of ${amount:N2} has been successfully processed.";
                }
            }
            catch { }

            return RedirectToPage("/AdminDashboard", new { section = "refunds" });
        }

        private void LoadPendingOrders()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand("SELECT COUNT(*) FROM Orders WHERE PaymentStatus = 'Pending'", conn))
                    {
                        TotalPendingOrders = (int)(cmd.ExecuteScalar() ?? 0);
                    }

                    string sql = @"
                        SELECT o.OrderId, o.OrderDate, o.TotalAmount, o.PaymentMethod, o.PaymentStatus, o.Notes,
                               COALESCE(o.CustomerName, (SELECT u.FullName FROM Users u WHERE u.UserId = o.UserId), 'Guest') AS CustomerName,
                               COALESCE(o.CustomerEmail, (SELECT u.Email FROM Users u WHERE u.UserId = o.UserId), '') AS CustomerEmail,
                               COALESCE(o.CustomerPhone, (SELECT u.Phone FROM Users u WHERE u.UserId = o.UserId), '') AS CustomerPhone,
                               COALESCE(o.CustomerAddress, (SELECT u.Address FROM Users u WHERE u.UserId = o.UserId), '') AS CustomerAddress,
                               STRING_AGG(CONCAT(oi.ItemName, ' (x', oi.Quantity, ')'), ', ') AS ItemsSummary
                        FROM Orders o
                        LEFT JOIN OrderItems oi ON o.OrderId = oi.OrderId
                        WHERE o.PaymentStatus = 'Pending'
                        GROUP BY o.OrderId, o.OrderDate, o.TotalAmount, o.PaymentMethod, o.PaymentStatus, o.Notes, o.UserId, o.CustomerName, o.CustomerEmail, o.CustomerPhone, o.CustomerAddress
                        ORDER BY o.OrderDate DESC";

                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            string custName = r.IsDBNull(6) ? "Guest" : r.GetString(6);
                            string custEmail = r.IsDBNull(7) ? "" : r.GetString(7);
                            string custPhone = r.IsDBNull(8) ? "" : r.GetString(8);
                            string custAddress = r.IsDBNull(9) ? "" : r.GetString(9);
                            string notes = r.IsDBNull(5) ? "" : r.GetString(5);

                            PendingOrders.Add(new AdminPendingOrderDto
                            {
                                OrderId = r.GetInt32(0),
                                OrderDate = r.GetDateTime(1),
                                TotalAmount = r.GetDecimal(2),
                                PaymentMethod = r.IsDBNull(3) ? "—" : r.GetString(3),
                                PaymentStatus = r.IsDBNull(4) ? "—" : r.GetString(4),
                                Notes = notes,
                                CustomerName = custName,
                                Email = custEmail,
                                Phone = custPhone,
                                Address = custAddress,
                                ItemsSummary = r.IsDBNull(10) ? "No Items" : r.GetString(10)
                            });
                        }
                    }
                }
            }
            catch
            {
                // Fallback in case STRING_AGG fails
                try
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        conn.Open();
                        string sql = @"
                            SELECT o.OrderId, o.OrderDate, o.TotalAmount, o.PaymentMethod, o.PaymentStatus, o.Notes,
                                   COALESCE(o.CustomerName, (SELECT u.FullName FROM Users u WHERE u.UserId = o.UserId), 'Guest') AS CustomerName,
                                   COALESCE(o.CustomerEmail, (SELECT u.Email FROM Users u WHERE u.UserId = o.UserId), '') AS CustomerEmail,
                                   COALESCE(o.CustomerPhone, (SELECT u.Phone FROM Users u WHERE u.UserId = o.UserId), '') AS CustomerPhone,
                                   COALESCE(o.CustomerAddress, (SELECT u.Address FROM Users u WHERE u.UserId = o.UserId), '') AS CustomerAddress
                            FROM Orders o
                            WHERE o.PaymentStatus = 'Pending'
                            ORDER BY o.OrderDate DESC";
                        using (SqlCommand cmd = new SqlCommand(sql, conn))
                        using (SqlDataReader r = cmd.ExecuteReader())
                        {
                            while (r.Read())
                            {
                                PendingOrders.Add(new AdminPendingOrderDto
                                {
                                    OrderId = r.GetInt32(0),
                                    OrderDate = r.GetDateTime(1),
                                    TotalAmount = r.GetDecimal(2),
                                    PaymentMethod = r.IsDBNull(3) ? "—" : r.GetString(3),
                                    PaymentStatus = r.IsDBNull(4) ? "—" : r.GetString(4),
                                    Notes = r.IsDBNull(5) ? "" : r.GetString(5),
                                    CustomerName = r.IsDBNull(6) ? "Guest" : r.GetString(6),
                                    Email = r.IsDBNull(7) ? "" : r.GetString(7),
                                    Phone = r.IsDBNull(8) ? "" : r.GetString(8),
                                    Address = r.IsDBNull(9) ? "" : r.GetString(9),
                                    ItemsSummary = "Items Details"
                                });
                            }
                        }
                    }
                }
                catch { }
            }
        }

        private void LoadPendingPayments()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = "SELECT PaymentLogId, OrderId, Amount, PaymentMethod, TransactionRef, PaymentDate, Status, Notes, type FROM PaymentLog WHERE Status = 'pending' ORDER BY PaymentDate DESC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                PendingPayments.Add(new PendingPaymentDto
                                {
                                    PaymentLogId = reader.GetInt32(0),
                                    OrderId = reader.IsDBNull(1) ? 0 : reader.GetInt32(1),
                                    Amount = reader.IsDBNull(2) ? 0 : reader.GetDecimal(2),
                                    PaymentMethod = reader.IsDBNull(3) ? "" : reader.GetString(3),
                                    TransactionRef = reader.IsDBNull(4) ? "" : reader.GetString(4),
                                    PaymentDate = reader.IsDBNull(5) ? DateTime.MinValue : reader.GetDateTime(5),
                                    Status = reader.IsDBNull(6) ? "" : reader.GetString(6),
                                    Notes = reader.IsDBNull(7) ? "" : reader.GetString(7),
                                    Type = reader.IsDBNull(8) ? "" : reader.GetString(8)
                                });
                            }
                        }
                    }
                }
            }
            catch { }
        }

        private void LoadRefundRequests()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"
                        SELECT r.RefundId, r.OrderId, r.UserId, r.RefundAmount, 
                               CASE 
                                   WHEN o.OrderType = 'Shop' THEN 'shop'
                                   WHEN o.OrderType = 'Membership' THEN 'member'
                                   ELSE 'ticket'
                               END AS Type, 
                               r.Status, r.RequestedAt, r.CompletedAt, r.TransactionRef,
                               u.FullName, u.Email
                        FROM Refunds r
                        INNER JOIN Orders o ON r.OrderId = o.OrderId
                        LEFT JOIN Users u ON r.UserId = u.UserId
                        WHERE r.Status = 'Requested'
                        ORDER BY r.RequestedAt DESC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                RefundRequests.Add(new RefundRequestDto
                                {
                                    RefundId = reader.GetInt32(0),
                                    OrderId = reader.IsDBNull(1) ? 0 : reader.GetInt32(1),
                                    UserId = reader.IsDBNull(2) ? 0 : reader.GetInt32(2),
                                    Amount = reader.GetDecimal(3),
                                    Type = reader.GetString(4),
                                    Status = reader.GetString(5),
                                    RequestedAt = reader.GetDateTime(6),
                                    CompletedAt = reader.IsDBNull(7) ? (DateTime?)null : reader.GetDateTime(7),
                                    TransactionRef = reader.IsDBNull(8) ? "" : reader.GetString(8),
                                    CustomerName = reader.IsDBNull(9) ? "Guest" : reader.GetString(9),
                                    Email = reader.IsDBNull(10) ? "" : reader.GetString(10)
                                });
                            }
                        }
                    }
                }
            }
            catch { }
        }

        private void LoadContactMessages()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = "SELECT ContactId, FirstName, LastName, Email, Subject, Reason, Message, CreatedAt, Source FROM contactus ORDER BY CreatedAt DESC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                ContactMessages.Add(new ContactMessageDto
                                {
                                    ContactId = reader.GetInt32(0),
                                    FirstName = reader.IsDBNull(1) ? "" : reader.GetString(1),
                                    LastName = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                    Email = reader.GetString(3),
                                    Subject = reader.IsDBNull(4) ? "" : reader.GetString(4),
                                    Reason = reader.IsDBNull(5) ? "" : reader.GetString(5),
                                    Message = reader.GetString(6),
                                    CreatedAt = reader.IsDBNull(7) ? DateTime.MinValue : reader.GetDateTime(7),
                                    Source = reader.IsDBNull(8) ? "" : reader.GetString(8)
                                });
                            }
                        }
                    }
                }
            }
            catch { }
        }

        private void LoadDonations()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"SELECT DonationId, DonorFirstName, DonorLastName, Email, Phone, Amount, 
                                          DonationFrequency, GiftPurpose, DedicationType, DedicationName, 
                                          CoverFees, TransactionRef, Status, PaymentMethod, CompletedAt 
                                   FROM Donations ORDER BY CompletedAt DESC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                Donations.Add(new DonationDto
                                {
                                    DonationId = reader.GetInt32(0),
                                    FirstName = reader.IsDBNull(1) ? "" : reader.GetString(1),
                                    LastName = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                    Email = reader.IsDBNull(3) ? "" : reader.GetString(3),
                                    Phone = reader.IsDBNull(4) ? "" : reader.GetString(4),
                                    Amount = reader.IsDBNull(5) ? 0m : reader.GetDecimal(5),
                                    Frequency = reader.IsDBNull(6) ? "" : reader.GetString(6),
                                    Purpose = reader.IsDBNull(7) ? "" : reader.GetString(7),
                                    DedicationType = reader.IsDBNull(8) ? "" : reader.GetString(8),
                                    DedicationName = reader.IsDBNull(9) ? "" : reader.GetString(9),
                                    CoverFees = !reader.IsDBNull(10) && Convert.ToBoolean(reader.GetValue(10)),
                                    TransactionRef = reader.IsDBNull(11) ? "" : reader.GetString(11),
                                    Status = reader.IsDBNull(12) ? "" : reader.GetString(12),
                                    PaymentMethod = reader.IsDBNull(13) ? "" : reader.GetString(13),
                                    DonationDate = reader.IsDBNull(14) ? DateTime.MinValue : reader.GetDateTime(14)
                                });
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(ex.ToString());
            }
        }

        private string Slugify(string name)
        {
            if (string.IsNullOrEmpty(name)) return "";
            string lower = name.ToLowerInvariant();
            var chars = lower.Select(c => (char.IsLetterOrDigit(c) || c == '-') ? c : ' ').ToArray();
            string cleaned = new string(chars).Trim();
            while (cleaned.Contains("  ")) cleaned = cleaned.Replace("  ", " ");
            return cleaned.Replace(' ', '-');
        }

        private void SyncProductsToJs()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                var productList = new List<string>();
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, 
                                         ISNULL(c.Name, 'Uncategorized'), ISNULL(p.ImagePath, ''),
                                         ISNULL(p.ProductInformation, ''), ISNULL(p.ProductDetail, ''), 
                                         ISNULL(p.MaterialAndCare, ''), ISNULL(p.AdditionalImages, ''),
                                         p.IsSizeEnabled, p.IsSizeChartEnabled,
                                         p.Slug, p.OriginalPrice, p.HoverImagePath, p.PageSlug,
                                         ISNULL(p.IsFeatured, 0), ISNULL(p.IsNew, 0)
                                  FROM ShopProducts p
                                  LEFT JOIN ShopCategories c ON p.CategoryId = c.CategoryId
                                  WHERE p.IsActive = 1 AND p.IsShop2 = 1
                                  ORDER BY p.Name";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    using (SqlDataReader r = cmd.ExecuteReader())
                    {
                        while (r.Read())
                        {
                            int productId = r.GetInt32(0);
                            string name = r.IsDBNull(1) ? "" : r.GetString(1);
                            decimal price = r.IsDBNull(3) ? 0.00m : r.GetDecimal(3);
                            string category = r.IsDBNull(5) ? "Uncategorized" : r.GetString(5);
                            string imagePath = r.IsDBNull(6) ? "" : r.GetString(6);
                            string additionalImages = r.IsDBNull(10) ? "" : r.GetString(10);
                            bool isSizeEnabled = r.IsDBNull(11) ? false : r.GetBoolean(11);
                            
                            string slug = r.IsDBNull(13) ? "" : r.GetString(13);
                            if (string.IsNullOrEmpty(slug))
                            {
                                slug = Slugify(name);
                            }

                            decimal? originalPrice = r.IsDBNull(14) ? (decimal?)null : r.GetDecimal(14);
                            string hoverImagePath = r.IsDBNull(15) ? "" : r.GetString(15);
                            if (string.IsNullOrEmpty(hoverImagePath))
                            {
                                if (!string.IsNullOrEmpty(additionalImages))
                                {
                                    var parts = additionalImages.Split(',');
                                    if (parts.Length > 1)
                                    {
                                        hoverImagePath = parts[1].Trim();
                                    }
                                }
                            }
                            if (string.IsNullOrEmpty(hoverImagePath))
                            {
                                hoverImagePath = imagePath;
                            }

                            bool isFeatured = r.IsDBNull(17) ? false : r.GetBoolean(17);
                            bool isNewProd = r.IsDBNull(18) ? false : r.GetBoolean(18);

                            string escapedName = name.Replace("'", "\\'");
                            string escapedImage = imagePath.Replace("'", "\\'");
                            string escapedHoverImage = hoverImagePath.Replace("'", "\\'");
                            string href = $"/Shop2/{slug}";
                            string compareAtPriceStr = (originalPrice.HasValue && originalPrice.Value > price) ? originalPrice.Value.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) : "null";
                            
                            productList.Add($"  {{ id: '{slug}', name: '{escapedName}', href: '{href}', image: '{escapedImage}', hoverImage: '{escapedHoverImage}', price: {price.ToString("F2", System.Globalization.CultureInfo.InvariantCulture)}, compareAtPrice: {compareAtPriceStr}, variantId: 'product-{productId}', category: '{category}', isSizeEnabled: {(isSizeEnabled ? "true" : "false")}, isSizeChartEnabled: {(r.IsDBNull(12) ? "false" : (r.GetBoolean(12) ? "true" : "false"))}, isFeatured: {(isFeatured ? "true" : "false")}, isNew: {(isNewProd ? "true" : "false")} }}");

                            // Dynamic Page Template Generation is no longer needed since we handle it dynamically via /Pages/Shop2/Product.cshtml.
                        }
                    }
                }

                string renderHelper = @"
function renderShopProducts(filter) {
    const grid = document.querySelector('.product-grid');
    if (!grid) return;
    grid.innerHTML = '';

    let filtered = ALL_PRODUCTS;
    if (filter === 'featured') {
        filtered = ALL_PRODUCTS.filter(p => p.isFeatured);
    } else if (filter === 'new') {
        filtered = ALL_PRODUCTS.filter(p => p.isNew);
    } else if (filter && filter !== 'all') {
        filtered = ALL_PRODUCTS.filter(p => p.category.toLowerCase() === filter.toLowerCase());
    }

    filtered.forEach(p => {
        const hasVariantClass = p.isSizeEnabled 
            ? (p.isSizeChartEnabled ? 'has-variant-2' : 'has-variant') 
            : '';

        let priceHtml = '';
        if (p.compareAtPrice && p.compareAtPrice > p.price) {
            priceHtml = `<span class=""evil"">£${p.compareAtPrice.toFixed(2)}</span> <span class=""good"">£${p.price.toFixed(2)}</span>`;
        } else {
            priceHtml = `<span class=""price"">£${p.price.toFixed(2)}</span>`;
        }

        let variantHtml = '';
        if (p.isSizeEnabled) {
            variantHtml = `
                <div class=""variant-selects"" data-section=""template-product-grid"" id=""variant-selects-${p.id}"">
                  <div aria-label=""Size"" class=""variant-row"" data-option-position=""1"" role=""group"">
                    <div class=""variant-values"">
                      <input checked="""" class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-XS"" name=""options[Size]"" type=""radio"" value=""XS""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""XS"" for=""Option-${p.id}-XS"" title=""XS"">XS</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-S"" name=""options[Size]"" type=""radio"" value=""S""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""S"" for=""Option-${p.id}-S"" title=""S"">S</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-M"" name=""options[Size]"" type=""radio"" value=""M""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""M"" for=""Option-${p.id}-M"" title=""M"">M</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-L"" name=""options[Size]"" type=""radio"" value=""L""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""L"" for=""Option-${p.id}-L"" title=""L"">L</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-XL"" name=""options[Size]"" type=""radio"" value=""XL""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""XL"" for=""Option-${p.id}-XL"" title=""XL"">XL</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-2XL"" name=""options[Size]"" type=""radio"" value=""2XL""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""2XL"" for=""Option-${p.id}-2XL"" title=""2XL"">2XL</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-3XL"" name=""options[Size]"" type=""radio"" value=""3XL""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""3XL"" for=""Option-${p.id}-3XL"" title=""3XL"">3XL</label>
                      
                      <input class=""variant-option-input"" data-option-position=""1"" id=""Option-${p.id}-4XL"" name=""options[Size]"" type=""radio"" value=""4XL""/>
                      <label aria-disabled=""false"" class=""variant-label"" data-option-position=""1"" data-option-value=""4XL"" for=""Option-${p.id}-4XL"" title=""4XL"">4XL</label>
                    </div>
                  </div>
                </div>`;
        } else {
            variantHtml = `<input class=""product-variant-id"" name=""id"" type=""hidden"" value=""${p.variantId}""/>`;
        }

        const li = document.createElement('li');
        li.className = 'grid-item';
        li.id = 'Slide-template';
        li.innerHTML = `
            <div class=""card-wrapper ${hasVariantClass}"">
              <div class=""card-product"">
                <div class=""card-inner-ratio"">
                  <a class=""product-card"" href=""${p.href}"" style=""text-decoration: none; color: inherit;"">
                    <div class=""card-media"">
                      <img alt=""${p.name}"" class=""product-img-primary"" src=""${p.image}""/>
                      <img alt=""${p.name} Hover"" src=""${p.hoverImage}""/>
                    </div>
                  </a>
                  <div class=""card-content"">
                    <div class=""card-information"">
                      <h3 class=""card-heading-h5"">
                        <a class=""full-unstyled-link"" href=""${p.href}"">${p.name}</a>
                      </h3>
                    </div>
                  </div>
                </div>
                <div class=""product-footer"">
                  <div class=""product-details"">
                    <div class=""product-footer-inner"">
                      <div class=""heading-rating"">
                        <h3 class=""card-heading-h5"">
                          <a class=""full-unstyled-link"" href=""${p.href}"">${p.name}</a>
                        </h3>
                      </div>
                      <div class=""labubu"">
                        ${priceHtml}
                      </div>
                    </div>
                    <div class=""quick-add-no-js"">
                      <product-form data-section-id=""template--26975595233570__related-products"">
                        <form accept-charset=""UTF-8"" action=""/cart/add"" class=""form"" data-qa-form-init=""true"" data-type=""add-to-cart-form"" enctype=""multipart/form-data"" id=""quick-add-template-${p.id}"" method=""post"" novalidate=""novalidate"">
                          <input name=""form_type"" type=""hidden"" value=""product""/>
                          <input name=""utf8"" type=""hidden"" value=""✓""/>
                          ${variantHtml}
                          <div class=""quick-add-actions"">
                            <quantity-input class=""cart-quantity"">
                              <button class=""quantity-button qty-minus"" type=""button"">−</button>
                              <input class=""quantity-input"" max=""99"" min=""1"" type=""number"" value=""1""/>
                              <button class=""quantity-button qty-plus"" type=""button"">+</button>
                            </quantity-input>
                            <button class=""quick-add-submit"" type=""button"">
                              <span class=""price-item"">ADD</span>
                            </button>
                          </div>
                        </form>
                      </product-form>
                    </div>
                  </div>
                </div>
              </div>
            </div>`;
        grid.appendChild(li);
    });
}
";

                string content = "const ALL_PRODUCTS = [\n" + string.Join(",\n", productList) + "\n];\n" + renderHelper;
                string jsPath = Path.Combine(_env.WebRootPath, "js", "shop2", "products.js");
                System.IO.File.WriteAllText(jsPath, content, System.Text.Encoding.UTF8);
            }
            catch (Exception)
            {
                // Fallback / log error
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // DTOs
    // ════════════════════════════════════════════════════════════════════════

    public class AdminPendingOrderDto
    {
        public int OrderId { get; set; }
        public string CustomerName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Phone { get; set; } = "";
        public string Address { get; set; } = "";
        public DateTime OrderDate { get; set; }
        public decimal TotalAmount { get; set; }
        public string PaymentMethod { get; set; } = "";
        public string PaymentStatus { get; set; } = "";
        public string Notes { get; set; } = "";
        public string ItemsSummary { get; set; } = "";
    }

    public class AdminEventDto
    {
        public int EventId { get; set; }
        public string Title { get; set; } = "";
        public string Description { get; set; } = "";
        public DateTime EventDate { get; set; }
        public int Capacity { get; set; }
        public decimal BasePrice { get; set; }
        public string ImagePath { get; set; } = "";
        public string WhatToExpect { get; set; } = "";
        public string EventDetails { get; set; } = "";
        public string Sponsors { get; set; } = "";
        public string Location { get; set; } = "";
        public string Status { get; set; } = "";
    }

    public class AdminProductDto
    {
        public int ProductId { get; set; }
        public string Name { get; set; } = "";
        public string Description { get; set; } = "";
        public decimal Price { get; set; }
        public int StockQuantity { get; set; }
        public string CategoryName { get; set; } = "";
        public string ImagePath { get; set; } = "";
        public string ProductInformation { get; set; } = "";
        public string ProductDetail { get; set; } = "";
        public string MaterialAndCare { get; set; } = "";
        public string AdditionalImages { get; set; } = "";
        public bool IsSizeEnabled { get; set; }
        public bool IsSizeChartEnabled { get; set; }
        public bool IsFeatured { get; set; }
        public bool IsNew { get; set; }
    }

    public class AdminCategoryDto
    {
        public int CategoryId { get; set; }
        public string Name { get; set; } = "";
    }

    public class PendingPaymentDto
    {
        public int PaymentLogId { get; set; }
        public int OrderId { get; set; }
        public decimal Amount { get; set; }
        public string PaymentMethod { get; set; } = "";
        public string TransactionRef { get; set; } = "";
        public DateTime PaymentDate { get; set; }
        public string Status { get; set; } = "";
        public string Notes { get; set; } = "";
        public string Type { get; set; } = "";
    }

    public class RefundRequestDto
    {
        public int RefundId { get; set; }
        public int OrderId { get; set; }
        public int UserId { get; set; }
        public string CustomerName { get; set; } = "";
        public string Email { get; set; } = "";
        public decimal Amount { get; set; }
        public string Type { get; set; } = "";
        public string Status { get; set; } = "";
        public DateTime RequestedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public string TransactionRef { get; set; } = "";
    }

    public class ContactMessageDto
    {
        public int ContactId { get; set; }
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Subject { get; set; } = "";
        public string Reason { get; set; } = "";
        public string Message { get; set; } = "";
        public DateTime CreatedAt { get; set; }
        public string Source { get; set; } = "";
    }

    public class DonationDto
    {
        public int DonationId { get; set; }
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string Phone { get; set; } = "";
        public decimal Amount { get; set; }
        public string Frequency { get; set; } = "";
        public string Purpose { get; set; } = "";
        public string DedicationType { get; set; } = "";
        public string DedicationName { get; set; } = "";
        public bool CoverFees { get; set; }
        public string TransactionRef { get; set; } = "";
        public string Status { get; set; } = "";
        public string PaymentMethod { get; set; } = "";
        public DateTime DonationDate { get; set; }
    }
}
