using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace AspireApp1.Web
{
    public class EventExpiryWorker : BackgroundService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EventExpiryWorker> _logger;

        public EventExpiryWorker(IConfiguration configuration, ILogger<EventExpiryWorker> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Event Expiry Background Service is starting.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    _logger.LogInformation("Running daily event expiry check...");
                    await UpdateExpiredEventsAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while updating expired events.");
                }

                // Compute delay until next midnight (00:00 UTC)
                var nowUtc = DateTime.UtcNow;
                var nextMidnightUtc = nowUtc.Date.AddDays(1);
                var delay = nextMidnightUtc - nowUtc;

                _logger.LogInformation("Next event expiry check scheduled in {Delay} (Midnight UTC: {NextMidnightUtc})", delay, nextMidnightUtc);

                try
                {
                    await Task.Delay(delay, stoppingToken);
                }
                catch (TaskCanceledException)
                {
                    break;
                }
            }

            _logger.LogInformation("Event Expiry Background Service is stopping.");
        }

        private async Task UpdateExpiredEventsAsync()
        {
            string connectionString = _configuration.GetConnectionString("DefaultConnection");
            if (string.IsNullOrEmpty(connectionString))
            {
                _logger.LogWarning("DefaultConnection string is empty. Skipping daily event expiry update.");
                return;
            }

            using (var conn = new SqlConnection(connectionString))
            {
                await conn.OpenAsync();

                // Update active events that have passed in UTC time.
                // Re-enforces matching constraint and optimizes database.
                string query = @"
                    UPDATE dbo.Events 
                    SET Status = 'Expired' 
                    WHERE Status = 'Active' 
                      AND EventDate < GETUTCDATE();";

                using (var cmd = new SqlCommand(query, conn))
                {
                    int rowsUpdated = await cmd.ExecuteNonQueryAsync();
                    _logger.LogInformation("Successfully updated {Count} expired events to 'Expired' status.", rowsUpdated);
                }
            }
        }
    }
}
