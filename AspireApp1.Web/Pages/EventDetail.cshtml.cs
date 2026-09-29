using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Security.Claims;

namespace WebApps.Pages
{
    public class EventDetailModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public EventDetailModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public class ZooEvent
        {
            public int EventId { get; set; }
            public string Id { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public string LongDescription { get; set; }
            public string ImageUrl { get; set; }
            public string DateStr { get; set; }
            public string TimeStr { get; set; }
            public List<string> Pricing { get; set; } = new List<string>();
            public decimal BasePrice { get; set; }
            public int Capacity { get; set; }
            public string WhatToExpect { get; set; }
            public string EventDetails { get; set; }
            public string Sponsors { get; set; }
            public string Location { get; set; } = "Main Zoo Grounds";
            public string Status { get; set; } = "Active";
        }

        public class EventCartDto
        {
            public int EventId { get; set; }
            public int Quantity { get; set; }
            public string TicketType { get; set; } // "Adult", "Child", "Member"
        }

        public class ConfirmPaymentDto
        {
            public string TransactionRef { get; set; }
        }

        public ZooEvent CurrentEvent { get; set; }
        public List<ZooEvent> SuggestedEvents { get; set; } = new List<ZooEvent>();

        public void OnGet(string id)
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr))
            {
                LoadFallbackData(id);
                return;
            }

            try
            {
                var allEvents = new List<ZooEvent>();
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"SELECT EventId, Title, Description, EventDate, ImagePath, Capacity, BasePrice, WhatToExpect, EventDetails, Sponsors, Location, Status 
                                   FROM Events WHERE Status = 'Active' ORDER BY EventDate ASC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                var evt = new ZooEvent
                                {
                                    EventId = reader.GetInt32(0),
                                    Title = reader.GetString(1),
                                    Description = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                    ImageUrl = reader.IsDBNull(4) ? "/Source/General/1.jpg" : reader.GetString(4),
                                    Capacity = reader.IsDBNull(5) ? 100 : reader.GetInt32(5),
                                    BasePrice = reader.IsDBNull(6) ? 0 : reader.GetDecimal(6),
                                    WhatToExpect = reader.IsDBNull(7) ? "" : reader.GetString(7),
                                    EventDetails = reader.IsDBNull(8) ? "" : reader.GetString(8),
                                    Sponsors = reader.IsDBNull(9) ? "" : reader.GetString(9),
                                    Location = reader.IsDBNull(10) ? "Main Zoo Grounds" : reader.GetString(10),
                                    Status = reader.IsDBNull(11) ? "Active" : reader.GetString(11)
                                };

                                var date = reader.GetDateTime(3);
                                evt.Id = evt.EventId.ToString();
                                evt.DateStr = date.ToString("dddd, MMMM dd");
                                evt.TimeStr = date.ToString("h:mm tt") + " - " + date.AddHours(3).ToString("h:mm tt");
                                evt.LongDescription = evt.Description;

                                evt.Pricing = new List<string>
                                {
                                    $"Adult (12+) - ${evt.BasePrice:F0}",
                                    $"Child (2-11) - ${(evt.BasePrice * 0.6m):F0}",
                                    $"Member Adult - ${(evt.BasePrice * 0.8m):F0}",
                                    "Under 2 - Free"
                                };

                                allEvents.Add(evt);
                            }
                        }
                    }
                }

                if (int.TryParse(id, out int eventId))
                {
                    CurrentEvent = allEvents.FirstOrDefault(e => e.EventId == eventId);
                }
                
                if (CurrentEvent == null && !string.IsNullOrEmpty(id))
                {
                    CurrentEvent = allEvents.FirstOrDefault(e => 
                        e.Title.Replace(" ", "").ToLower().Contains(id.ToLower()));
                }

                CurrentEvent ??= allEvents.FirstOrDefault();

                if (CurrentEvent != null)
                {
                    SuggestedEvents = allEvents.Where(e => e.EventId != CurrentEvent.EventId).Take(3).ToList();
                }
                else
                {
                    LoadFallbackData(id);
                }
            }
            catch (SqlException)
            {
                LoadFallbackData(id);
            }
        }

        public class EventCheckoutRequestDto
        {
            public int EventId { get; set; }
            public int Quantity { get; set; }
            public string TicketType { get; set; }
            public string PaymentMethod { get; set; }
            public string GuestName { get; set; }
            public string GuestEmail { get; set; }
            public string GuestPhone { get; set; }
            public string GuestAddress { get; set; }
        }

        // ============================================================
        // POST: InitEventPayment
        // ============================================================
        public async Task<IActionResult> OnPostInitEventPaymentAsync()
        {
            using var reader = new System.IO.StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            EventCheckoutRequestDto checkoutReq;
            try { checkoutReq = JsonSerializer.Deserialize<EventCheckoutRequestDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }); }
            catch { return new JsonResult(new { success = false, message = "Invalid data." }); }

            if (checkoutReq == null || checkoutReq.Quantity <= 0)
                return new JsonResult(new { success = false, message = "Please select quantity." });

            string connStr = _configuration.GetConnectionString("DefaultConnection");

            // Resolve customer info
            int? userId = null;
            string customerName = "";
            string customerEmail = "";
            string customerPhone = "";
            string customerAddress = "";

            bool isLoggedIn = User.Identity?.IsAuthenticated == true;
            if (isLoggedIn)
            {
                string loggedInName = User.FindFirst(ClaimTypes.Name)?.Value ?? User.Identity.Name;
                string userSql = "SELECT UserId, FullName, Email, Phone, Address FROM Users WHERE FullName = @Name OR Username = @Name";
                try
                {
                    using (SqlConnection conn = new SqlConnection(connStr))
                    {
                        conn.Open();
                        using (SqlCommand userCmd = new SqlCommand(userSql, conn))
                        {
                            userCmd.Parameters.AddWithValue("@Name", loggedInName);
                            using (var r = userCmd.ExecuteReader())
                            {
                                if (r.Read())
                                {
                                    userId = r.GetInt32(0);
                                    customerName = r.IsDBNull(1) ? "" : r.GetString(1);
                                    customerEmail = r.IsDBNull(2) ? "" : r.GetString(2);
                                    customerPhone = r.IsDBNull(3) ? "" : r.GetString(3);
                                    customerAddress = r.IsDBNull(4) ? "" : r.GetString(4);
                                }
                            }
                        }
                    }
                }
                catch { }

                if (string.IsNullOrEmpty(customerName)) customerName = loggedInName;
                if (string.IsNullOrEmpty(customerEmail)) customerEmail = User.FindFirst(ClaimTypes.Email)?.Value ?? "";
            }
            else
            {
                customerName = checkoutReq.GuestName ?? "Guest";
                customerEmail = checkoutReq.GuestEmail ?? "";
                customerPhone = checkoutReq.GuestPhone ?? "";
                customerAddress = checkoutReq.GuestAddress ?? "";
            }

            string paymentMethod = checkoutReq.PaymentMethod ?? "QR Code";
            string paymentStatus = "Pending";
            string txRef = "TXN-EVT-" + DateTime.Now.ToString("yyyyMMdd") + "-" + Guid.NewGuid().ToString("N").Substring(0, 8).ToUpper();

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using var tx = conn.BeginTransaction();
                    try
                    {
                        // Get event info + check capacity
                        string evtTitle = ""; decimal evtPrice = 0; int capacity = 0;
                        DateTime evtDate = DateTime.Today;
                        using (SqlCommand cmd = new SqlCommand("SELECT Title, BasePrice, Capacity, EventDate FROM Events WHERE EventId = @Id", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Id", checkoutReq.EventId);
                            using (var r = cmd.ExecuteReader())
                            {
                                if (r.Read()) { evtTitle = r.GetString(0); evtPrice = r.GetDecimal(1); capacity = r.GetInt32(2); evtDate = r.GetDateTime(3); }
                                else { tx.Rollback(); return new JsonResult(new { success = false, message = "Event not found." }); }
                            }
                        }

                        // Adjust price for ticket type
                        decimal unitPrice = evtPrice;
                        string ticketLabel = checkoutReq.TicketType ?? "Adult";
                        if (ticketLabel == "Child") unitPrice = evtPrice * 0.6m;
                        else if (ticketLabel == "Member") unitPrice = evtPrice * 0.8m;

                        decimal totalAmount = unitPrice * checkoutReq.Quantity;

                        if (capacity < checkoutReq.Quantity)
                        {
                            tx.Rollback();
                            return new JsonResult(new { success = false, message = $"Only {capacity} seats remaining." });
                        }

                        // Create Order
                        int orderId = 0;
                        using (SqlCommand cmd = new SqlCommand(@"
                            INSERT INTO Orders (UserId, OrderType, TotalAmount, PaymentMethod, PaymentStatus, TransactionRef, Notes, CustomerName, CustomerEmail, CustomerPhone, CustomerAddress)
                            VALUES (@UserId, 'Event', @Total, @PaymentMethod, @PaymentStatus, @TxRef, @Notes, @CustomerName, @CustomerEmail, @CustomerPhone, @CustomerAddress);
                            SELECT SCOPE_IDENTITY();", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@UserId", userId.HasValue ? (object)userId.Value : DBNull.Value);
                            cmd.Parameters.AddWithValue("@Total", totalAmount);
                            cmd.Parameters.AddWithValue("@PaymentMethod", paymentMethod);
                            cmd.Parameters.AddWithValue("@PaymentStatus", paymentStatus);
                            cmd.Parameters.AddWithValue("@TxRef", txRef);
                            cmd.Parameters.AddWithValue("@Notes", $"{evtTitle} - {customerName}");
                            cmd.Parameters.AddWithValue("@CustomerName", string.IsNullOrEmpty(customerName) ? (object)DBNull.Value : customerName);
                            cmd.Parameters.AddWithValue("@CustomerEmail", string.IsNullOrEmpty(customerEmail) ? (object)DBNull.Value : customerEmail);
                            cmd.Parameters.AddWithValue("@CustomerPhone", string.IsNullOrEmpty(customerPhone) ? (object)DBNull.Value : customerPhone);
                            cmd.Parameters.AddWithValue("@CustomerAddress", string.IsNullOrEmpty(customerAddress) ? (object)DBNull.Value : customerAddress);
                            
                            var r = cmd.ExecuteScalar();
                            if (r != null) orderId = Convert.ToInt32(r);
                        }

                        if (orderId == 0) { tx.Rollback(); return new JsonResult(new { success = false, message = "Failed." }); }

                        // Insert OrderItem
                        using (SqlCommand cmd = new SqlCommand(@"INSERT INTO OrderItems (OrderId, ItemType, ItemName, EventId, Quantity, UnitPrice, VisitDate)
                                               VALUES (@OrderId, 'Event', @ItemName, @EventId, @Qty, @Price, @VisitDate)", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@OrderId", orderId);
                            cmd.Parameters.AddWithValue("@ItemName", $"{evtTitle} ({ticketLabel})");
                            cmd.Parameters.AddWithValue("@EventId", checkoutReq.EventId);
                            cmd.Parameters.AddWithValue("@Qty", checkoutReq.Quantity);
                            cmd.Parameters.AddWithValue("@Price", unitPrice);
                            cmd.Parameters.AddWithValue("@VisitDate", evtDate);
                            cmd.ExecuteNonQuery();
                        }

                        tx.Commit();
                        return new JsonResult(new { 
                            success = true, 
                            transactionRef = txRef, 
                            totalAmount, 
                            ticketCount = checkoutReq.Quantity, 
                            customerName, 
                            eventTitle = evtTitle,
                            paymentMethod = paymentMethod
                        });
                    }
                    catch { tx.Rollback(); throw; }
                }
            }
            catch (SqlException ex) { return new JsonResult(new { success = false, message = $"Unable to process payment: {ex.Message}" }); }
        }

        // ============================================================
        // POST: ConfirmEventPayment
        // ============================================================
        public async Task<IActionResult> OnPostConfirmEventPaymentAsync()
        {
            using var reader = new System.IO.StreamReader(Request.Body);
            var body = await reader.ReadToEndAsync();

            ConfirmPaymentDto data;
            try { data = JsonSerializer.Deserialize<ConfirmPaymentDto>(body, new JsonSerializerOptions { PropertyNameCaseInsensitive = true }); }
            catch { return new JsonResult(new { success = false, message = "Invalid data." }); }

            if (data == null || string.IsNullOrEmpty(data.TransactionRef))
                return new JsonResult(new { success = false, message = "Transaction ref required." });

            string connStr = _configuration.GetConnectionString("DefaultConnection");

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using var tx = conn.BeginTransaction();
                    try
                    {
                        // === CHECK QR SCAN ===
                        using (SqlCommand scanCheck = new SqlCommand("SELECT QRScannedAt FROM Orders WHERE TransactionRef = @Ref AND PaymentStatus = 'Pending'", conn, tx))
                        {
                            scanCheck.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            var scanResult = scanCheck.ExecuteScalar();
                            if (scanResult == null || scanResult == DBNull.Value)
                            {
                                tx.Rollback();
                                return new JsonResult(new { success = false, message = "QR chưa được quét. Vui lòng quét mã QR bằng ứng dụng ngân hàng trước.", notScanned = true });
                            }
                        }

                        int rows = 0;
                        using (SqlCommand cmd = new SqlCommand("UPDATE Orders SET PaymentStatus = 'Completed' WHERE TransactionRef = @Ref AND PaymentStatus = 'Pending'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            rows = cmd.ExecuteNonQuery();
                        }

                        if (rows == 0) { tx.Rollback(); return new JsonResult(new { success = false, message = "No pending payment." }); }

                        // Decrease event capacity
                        string capSql = @"UPDATE e SET e.Capacity = e.Capacity - oi.Quantity
                                          FROM Events e
                                          INNER JOIN OrderItems oi ON e.EventId = oi.EventId
                                          INNER JOIN Orders o ON oi.OrderId = o.OrderId
                                          WHERE o.TransactionRef = @Ref AND oi.ItemType = 'Event'";
                        using (SqlCommand cmd = new SqlCommand(capSql, conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            cmd.ExecuteNonQuery();
                        }

                        // PaymentLog
                        using (SqlCommand cmd = new SqlCommand("UPDATE PaymentLog SET Status = 'Success' WHERE TransactionRef = @Ref AND Status = 'Pending'", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            cmd.ExecuteNonQuery();
                        }

                        // Get info for notifications from Orders table
                        string customerName = "Guest";
                        string customerEmail = "";
                        decimal totalAmount = 0; string evtTitle = "";
                        using (SqlCommand cmd = new SqlCommand(@"SELECT o.TotalAmount, oi.ItemName, o.CustomerName, o.CustomerEmail FROM Orders o 
                            INNER JOIN OrderItems oi ON o.OrderId = oi.OrderId 
                            WHERE o.TransactionRef = @Ref", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            using var r = cmd.ExecuteReader();
                            if (r.Read()) { 
                                totalAmount = r.GetDecimal(0); 
                                evtTitle = r.GetString(1); 
                                customerName = r.IsDBNull(2) ? "Guest" : r.GetString(2);
                                customerEmail = r.IsDBNull(3) ? "" : r.GetString(3);
                            }
                        }

                        // === Notifications ===
                        using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Notifications 
                            (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                            VALUES ('Admin', NULL, @Title, @Msg, 'Ticket', @Ref, 'fa-calendar')", conn, tx))
                        {
                            cmd.Parameters.AddWithValue("@Title", $"New Event Booking: {data.TransactionRef}");
                            cmd.Parameters.AddWithValue("@Msg", $"{customerName} booked {evtTitle} (${totalAmount:F2}) - Ref: {data.TransactionRef}");
                            cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                            cmd.ExecuteNonQuery();
                        }
                        if (!string.IsNullOrEmpty(customerEmail))
                        {
                            using (SqlCommand cmd = new SqlCommand(@"INSERT INTO Notifications 
                                (RecipientRole, RecipientEmail, Title, Message, Type, ReferenceId, IconClass)
                                VALUES ('User', @Email, @Title, @Msg, 'Ticket', @Ref, 'fa-check-circle')", conn, tx))
                            {
                                cmd.Parameters.AddWithValue("@Email", customerEmail);
                                cmd.Parameters.AddWithValue("@Title", "Event Booking Confirmed!");
                                cmd.Parameters.AddWithValue("@Msg", $"Your booking for {evtTitle} (${totalAmount:F2}) is confirmed. Ref: {data.TransactionRef}");
                                cmd.Parameters.AddWithValue("@Ref", data.TransactionRef);
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tx.Commit();
                        return new JsonResult(new { success = true, message = $"Payment confirmed! {rows} order(s) completed." });
                    }
                    catch { tx.Rollback(); throw; }
                }
            }
            catch (SqlException) { return new JsonResult(new { success = false, message = "Unable to confirm payment. Please try again." }); }
        }

        /// <summary>
        /// Fallback dữ liệu tĩnh khi DB không khả dụng
        /// </summary>
        private void LoadFallbackData(string id)
        {
            var fallback = new List<ZooEvent>
            {
                new ZooEvent { Id = "zoolights", EventId = 1, Title = "ZooLights Winter Festival", 
                    Description = "Experience the magic of winter at our breathtaking ZooLights Winter Festival! Watch as the entire zoo transforms into a spectacular winter wonderland illuminated by over one million sparkling LED lights.",
                    LongDescription = "Experience the magic of winter at our breathtaking ZooLights Winter Festival! Watch as the entire zoo transforms into a spectacular winter wonderland illuminated by over one million sparkling LED lights, featuring stunning light sculptures of your favorite animals crafted by world-class lighting designers. Stroll along glowing pathways lined with enchanting light tunnels and animated displays that bring the holiday spirit to life around every corner. Warm up with complimentary hot cocoa, fresh-baked cookies, and gourmet seasonal treats from our holiday food village. Enjoy live carolers performing classic holiday songs, a visit from Santa in his arctic-themed workshop, ice sculpture demonstrations by professional carvers, a snow play area for children, and a dazzling fireworks finale every Saturday evening. This beloved annual tradition is the perfect family outing to create lasting holiday memories together!",
                    ImageUrl = "/Source/General/15.jpg", DateStr = "Friday, November 15", TimeStr = "5:00 PM - 9:00 PM",
                    BasePrice = 25,
                    Pricing = new List<string> { "Adult (12+) - $25", "Child (2-11) - $15", "Member Adult - $20", "Under 2 - Free" }},
                new ZooEvent { Id = "brew", EventId = 2, Title = "Brew at the Zoo", 
                    Description = "Join us for our annual beer festival supporting wildlife conservation! This exciting adults-only event (21+) features live music, craft beer tastings from over 40 breweries, and exclusive after-hours animal encounters.",
                    LongDescription = "Get ready to raise your glass for a wild cause at Brew at the Zoo! This beloved annual tradition brings together craft beer enthusiasts and wildlife lovers for an unforgettable evening of tastings, live entertainment, and exclusive animal experiences. Sample exceptional craft beers and hard seltzers from over 40 carefully curated regional and national breweries, each paired with gourmet food options from our award-winning culinary partners. Enjoy live performances from top local bands on our main stage while exploring the zoo grounds under the stars. VIP ticket holders receive early entry, access to a private tasting lounge with rare and limited-edition brews, a commemorative tasting glass, and an exclusive behind-the-scenes animal encounter. Every ticket purchase directly supports our conservation programs protecting endangered species around the world.",
                    ImageUrl = "/Source/General/7.jpg", DateStr = "Saturday, June 20", TimeStr = "6:30 PM - 10:00 PM",
                    BasePrice = 55,
                    Pricing = new List<string> { "VIP Admission - $85", "General Admission - $55", "Designated Driver - $30" }},
                new ZooEvent { Id = "keeper", EventId = 3, Title = "Keeper Talk Series", 
                    Description = "Learn straight from the experts in our exclusive Keeper Talk Series! Join our specialized zookeepers for intimate, behind-the-scenes presentations about daily animal care routines and behavioral observations.",
                    LongDescription = "Discover the fascinating world of professional animal care in our exclusive Keeper Talk Series! These intimate, small-group sessions give you unprecedented access to our passionate and knowledgeable zookeepers as they share the stories, challenges, and triumphs of caring for hundreds of exotic species every single day. Each talk focuses on a specific animal group — from the powerful big cats and gentle elephants to the colorful tropical birds and mysterious nocturnal creatures. Learn about specialized diet preparation, behavioral enrichment techniques that stimulate natural behaviors, veterinary health monitoring, and the intricate social dynamics within animal groups. Guests will observe real training sessions and discover the trust-based relationship between keepers and their animals. Each session concludes with an exclusive Q&A where you can ask anything about zoo careers, conservation efforts, and the unique personalities of our beloved animal residents.",
                    ImageUrl = "/Source/General/12.jpg", DateStr = "Saturday, August 10", TimeStr = "9:00 AM - 11:30 AM",
                    BasePrice = 35,
                    Pricing = new List<string> { "General Admission - $35", "Members - $25", "Student (with ID) - $20" }},
                new ZooEvent { Id = "safari", EventId = 4, Title = "Spring Break Safari Event", 
                    Description = "Celebrate the arrival of spring with our spectacular Spring Break Safari Event! This exclusive access bundle includes standard zoo admission, unlimited zoo train rides, and interactive keeper talks.",
                    LongDescription = "Make this Spring Break unforgettable with our action-packed Safari Event! This exclusive access bundle includes standard zoo admission, unlimited zoo train rides through our scenic wildlife trails, and a special souvenir cup to commemorate your adventure. During this limited-time event, families can enjoy interactive keeper talks, a scavenger hunt throughout the park, face painting stations, and live wildlife demonstrations featuring our ambassador animals. Children will love the hands-on discovery stations where they can learn about animal tracks, feathers, and habitats. Our Safari Photo Booth lets you capture memories with life-sized animal cutouts. Gourmet food trucks and refreshment stands are positioned throughout the zoo grounds. This event sells out quickly every year — reserve your timed-entry tickets online to guarantee your spot for the ultimate spring wildlife adventure!",
                    ImageUrl = "/Source/General/14.jpg", DateStr = "Wednesday, March 25", TimeStr = "9:00 AM - 5:00 PM",
                    BasePrice = 35,
                    Pricing = new List<string> { "Safari Family 4-Pack - $120", "Individual Safari Pass - $35", "Member Add-on - $15/person" }},
                new ZooEvent { Id = "gala", EventId = 5, Title = "Annual Conservation Gala", 
                    Description = "Join us for our most prestigious evening — the Annual Conservation Gala! This elegant black-tie fundraising event brings together passionate wildlife advocates and conservation scientists.",
                    LongDescription = "Step into an evening of elegance, impact, and purpose at our Annual Conservation Gala! This prestigious black-tie fundraising event brings together passionate wildlife advocates, philanthropists, distinguished community leaders, and conservation scientists for an unforgettable night dedicated to protecting endangered species worldwide. The evening begins with a sophisticated cocktail reception featuring live jazz music and gourmet hors d'oeuvres, followed by a five-course plated dinner prepared by our award-winning executive chef using locally sourced, sustainable ingredients. Throughout the evening, guests will enjoy a live and silent auction featuring exclusive wildlife experiences, luxury travel packages, original wildlife artwork, and rare collectibles. Keynote speakers include renowned conservation biologists sharing groundbreaking field research and success stories. Every dollar raised directly funds our global wildlife protection programs, habitat restoration initiatives, and breeding programs for critically endangered species.",
                    ImageUrl = "/Source/General/13.jpg", DateStr = "Saturday, October 12", TimeStr = "7:00 PM - 11:00 PM",
                    BasePrice = 250,
                    Pricing = new List<string> { "Gala Ticket - $250", "VIP Table (Seat 8) - $2,500", "Conservation Sponsor - $5,000" }}
            };

            CurrentEvent = fallback.FirstOrDefault(e => e.Id == id) ?? fallback.First();
            SuggestedEvents = fallback.Where(e => e.Id != CurrentEvent.Id).Take(3).ToList();
        }
    }
}
