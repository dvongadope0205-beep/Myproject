using AspireApp1.Web;
using Microsoft.AspNetCore.Authentication.Cookies;

var builder = WebApplication.CreateBuilder(args);

// Add service defaults & Aspire client integrations.
builder.AddServiceDefaults();

// Add services to the container.
builder.Services.AddRazorPages();
builder.Services.AddHostedService<EventExpiryWorker>();

builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Login";
        options.AccessDeniedPath = "/Index";
        options.Cookie.Path = "/";
        options.Cookie.Name = "ZooSharedAuthCookie";
        options.Cookie.HttpOnly = true;
        options.Cookie.SameSite = Microsoft.AspNetCore.Http.SameSiteMode.Lax;
        options.Cookie.SecurePolicy = Microsoft.AspNetCore.Http.CookieSecurePolicy.SameAsRequest;
    });

// CORS Policy — cho phép frontend gọi API an toàn
builder.Services.AddCors(options =>
{
    options.AddPolicy("ZooCorsPolicy", policy =>
    {
        policy.WithOrigins(
                "https://localhost:5001",
                "http://localhost:5000",
                "https://localhost:7100",
                "http://localhost:5100"
            )
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials();
    });
});

builder.Services.AddAntiforgery(options =>
{
    options.HeaderName = "RequestVerificationToken";
});

builder.Services.AddOutputCache();

builder.Services.AddHttpClient<WeatherApiClient>(client =>
    {
        // This URL uses "https+http://" to indicate HTTPS is preferred over HTTP.
        // Learn more about service discovery scheme resolution at https://aka.ms/dotnet/sdschemes.
        client.BaseAddress = new("https+http://apiservice");
    });

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseRouting();

app.UseCors("ZooCorsPolicy");

app.UseAuthentication();
app.UseAuthorization();

app.UseOutputCache();

app.MapStaticAssets();
app.MapRazorPages().WithStaticAssets();

app.MapDefaultEndpoints();

app.MapGet("/api/shop/product-settings", async (string slug, IConfiguration configuration) =>
{
    string connStr = configuration.GetConnectionString("DefaultConnection");
    if (string.IsNullOrEmpty(connStr))
    {
        return Results.Ok(new { isSizeEnabled = false, isSizeChartEnabled = false });
    }

    int productId = GetProductIdFromSlug(slug);
    if (productId == 0)
    {
        return Results.Ok(new { isSizeEnabled = false, isSizeChartEnabled = false });
    }

    bool isSizeEnabled = false;
    bool isSizeChartEnabled = false;

    using (var conn = new Microsoft.Data.SqlClient.SqlConnection(connStr))
    {
        await conn.OpenAsync();
        using (var cmd = new Microsoft.Data.SqlClient.SqlCommand(
            "SELECT IsSizeEnabled, IsSizeChartEnabled FROM ShopProducts WHERE ProductId = @Id", conn))
        {
            cmd.Parameters.AddWithValue("@Id", productId);
            using (var reader = await cmd.ExecuteReaderAsync())
            {
                if (await reader.ReadAsync())
                {
                    isSizeEnabled = !reader.IsDBNull(0) && reader.GetBoolean(0);
                    isSizeChartEnabled = !reader.IsDBNull(1) && reader.GetBoolean(1);
                }
            }
        }
    }

    return Results.Ok(new { isSizeEnabled, isSizeChartEnabled });
});

app.Run();

static int GetProductIdFromSlug(string slug)
{
    slug = slug?.ToLower().Trim();
    if (string.IsNullOrEmpty(slug)) return 0;
    
    // Remove query string if present
    if (slug.Contains("?")) slug = slug.Split('?')[0];
    if (slug.EndsWith(".cshtml")) slug = slug.Substring(0, slug.Length - 7);
    
    // Get last segment if it's a full path
    if (slug.Contains("/"))
    {
        var parts = slug.Split('/');
        slug = parts[parts.Length - 1];
    }
    
    return slug switch
    {
        "albie-pin" => 35,
        "albie-plush" => 18,
        "ashley-pin" => 36,
        "axolotl-tee" => 26,
        "batrick-crewneck" => 23,
        "batrick-hoodie" => 24,
        "batrick-plush" => 13,
        "batrick-tee" => 25,
        "board-game" => 50,
        "bro-plush" => 22,
        "chris-plush" => 20,
        "emily-plush" => 15,
        "jason-pin" => 37,
        "jason-plush" => 19,
        "kevin-backpack" => 33,
        "kevin-pin" => 38,
        "kevin-plush" => 14,
        "lisa-pin" => 39,
        "lisa-plush" => 17,
        "lisa-tee" => 27,
        "lizard-pin" => 40,
        "mouth-plush" => 16,
        "nh-fall-hoodie" => 30,
        "nh-lineart-hoodie" => 31,
        "nh-notebook" => 41,
        "nh-sticker" => 42,
        "nh-tee" => 29,
        "robert-plush" => 21,
        "robert-tee" => 28,
        "summer-hoodie" => 32,
        "summer-tote-bag" => 34,
        _ => 0
    };
}


