using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;

namespace WebApps.Pages
{
    public class EventsModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public EventsModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public class EventCard
        {
            public int EventId { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public DateTime EventDate { get; set; }
            public string ImagePath { get; set; }
            public int Capacity { get; set; }
            public decimal BasePrice { get; set; }
        }

        public List<EventCard> EventList { get; set; } = new List<EventCard>();

        public void OnGet()
        {
            string connStr = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connStr)) return;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"SELECT EventId, Title, Description, EventDate, ImagePath, Capacity, BasePrice 
                                   FROM Events 
                                   ORDER BY EventDate ASC";
                    using (SqlCommand cmd = new SqlCommand(sql, conn))
                    {
                        using (SqlDataReader reader = cmd.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                EventList.Add(new EventCard
                                {
                                    EventId = reader.GetInt32(0),
                                    Title = reader.GetString(1),
                                    Description = reader.IsDBNull(2) ? "" : reader.GetString(2),
                                    EventDate = reader.GetDateTime(3),
                                    ImagePath = reader.IsDBNull(4) ? "/Source/General/1.jpg" : reader.GetString(4),
                                    Capacity = reader.IsDBNull(5) ? 0 : reader.GetInt32(5),
                                    BasePrice = reader.IsDBNull(6) ? 0 : reader.GetDecimal(6)
                                });
                            }
                        }
                    }
                }
            }
            catch (SqlException)
            {
                // Failsafe — load empty if DB unavailable
            }
        }
    }
}