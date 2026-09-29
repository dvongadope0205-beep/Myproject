using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Data.SqlClient;

namespace SyncTool
{
    class Program
    {
        static void Main(string[] args)
        {
            string connStr = "Server=(localdb)\\MSSQLLocalDB;Database=ZooDatabase;Trusted_Connection=True;";
            string webRootPath = @"C:\WEBDEV\AspireApp1\AspireApp1.Web\wwwroot";
            string contentRootPath = @"C:\WEBDEV\AspireApp1\AspireApp1.Web";

            Console.WriteLine("Starting synchronization of Shop 2 products...");

            try
            {
                var productList = new List<string>();
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    string sql = @"SELECT p.ProductId, p.Name, p.Description, p.Price, p.OriginalPrice, p.ImagePath, p.AdditionalImages, 
                                          p.IsSizeEnabled, p.IsSizeChartEnabled,
                                          p.Slug, p.OriginalPrice, p.HoverImagePath, p.PageSlug,
                                          ISNULL(p.IsFeatured, 0), ISNULL(p.IsNew, 0),
                                          ISNULL(c.Name, 'Uncategorized')
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
                            string imagePath = r.IsDBNull(5) ? "" : r.GetString(5);
                            string additionalImages = r.IsDBNull(6) ? "" : r.GetString(6);
                            bool isSizeEnabled = r.IsDBNull(7) ? false : r.GetBoolean(7);
                            bool isSizeChartEnabled = r.IsDBNull(8) ? false : r.GetBoolean(8);

                            string slug = r.IsDBNull(9) ? "" : r.GetString(9);
                            if (string.IsNullOrEmpty(slug))
                            {
                                slug = Slugify(name);
                            }

                            decimal? originalPrice = r.IsDBNull(10) ? (decimal?)null : r.GetDecimal(10);
                            string hoverImagePath = r.IsDBNull(11) ? "" : r.GetString(11);
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

                            bool isFeatured = r.GetBoolean(13);
                            bool isNewProd = r.GetBoolean(14);
                            string category = r.GetString(15);

                            string escapedName = name.Replace("'", "\\'");
                            string escapedImage = imagePath.Replace("'", "\\'");
                            string escapedHoverImage = hoverImagePath.Replace("'", "\\'");
                            string href = $"/Shop2/{slug}";
                            string compareAtPriceStr = (originalPrice.HasValue && originalPrice.Value > price) ? originalPrice.Value.ToString("F2", System.Globalization.CultureInfo.InvariantCulture) : "null";

                            productList.Add($"  {{ id: '{slug}', name: '{escapedName}', href: '{href}', image: '{escapedImage}', hoverImage: '{escapedHoverImage}', price: {price.ToString("F2", System.Globalization.CultureInfo.InvariantCulture)}, compareAtPrice: {compareAtPriceStr}, variantId: 'product-{productId}', category: '{category}', isSizeEnabled: {(isSizeEnabled ? "true" : "false")}, isSizeChartEnabled: {(isSizeChartEnabled ? "true" : "false")}, isFeatured: {(isFeatured ? "true" : "false")}, isNew: {(isNewProd ? "true" : "false")} }}");

                            // Dynamic Page Template Generation
                            string templateName = isSizeEnabled 
                                ? "ProductTemplateSizes.txt" 
                                : "ProductTemplateNormal.txt";
                            try
                            {
                                string templatePath = Path.Combine(contentRootPath, "Pages", "Shop2", "Shared", templateName);
                                if (File.Exists(templatePath))
                                {
                                    string templateContent = File.ReadAllText(templatePath);
                                    string finalContent = templateContent.Replace("{SLUG}", slug);
                                    string pagePath = Path.Combine(contentRootPath, "Pages", "Shop2", $"{slug}.cshtml");
                                    File.WriteAllText(pagePath, finalContent, System.Text.Encoding.UTF8);
                                    Console.WriteLine($"Generated page: {slug}.cshtml using {templateName}");
                                }
                                else
                                {
                                    Console.WriteLine($"Template not found: {templatePath}");
                                }
                            }
                            catch (Exception ex)
                            {
                                Console.WriteLine($"Error writing page for {slug}: {ex.Message}");
                            }
                        }
                    }
                }

                // Generates products.js
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
                string jsPath = Path.Combine(webRootPath, "js", "shop2", "products.js");
                File.WriteAllText(jsPath, content, System.Text.Encoding.UTF8);
                Console.WriteLine("Successfully synced products.js");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Fatal error: {ex.Message}");
            }
        }

        static string Slugify(string name)
        {
            if (string.IsNullOrEmpty(name)) return "";
            string lower = name.ToLowerInvariant();
            var chars = lower.Select(c => (char.IsLetterOrDigit(c) || c == '-') ? c : ' ').ToArray();
            string cleaned = new string(chars).Trim();
            while (cleaned.Contains("  ")) cleaned = cleaned.Replace("  ", " ");
            return cleaned.Replace(' ', '-');
        }
    }
}
