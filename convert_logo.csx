using System;
using System.Drawing;
using System.Drawing.Imaging;

// Remove white background and make the logo white
string inputPath = @"c:\WEBDEV\AspireApp1\AspireApp1.Web\wwwroot\Source\General\logo.png";
string outputPath = @"c:\WEBDEV\AspireApp1\AspireApp1.Web\wwwroot\Source\General\logo-white.png";

using (Bitmap bmp = new Bitmap(inputPath))
{
    Bitmap result = new Bitmap(bmp.Width, bmp.Height, PixelFormat.Format32bppArgb);
    
    for (int x = 0; x < bmp.Width; x++)
    {
        for (int y = 0; y < bmp.Height; y++)
        {
            Color pixel = bmp.GetPixel(x, y);
            
            // Calculate how "white" this pixel is (higher = more white)
            int whiteness = (pixel.R + pixel.G + pixel.B) / 3;
            
            if (whiteness > 220)
            {
                // White/near-white background -> make transparent
                result.SetPixel(x, y, Color.FromArgb(0, 255, 255, 255));
            }
            else
            {
                // Logo content (dark green) -> make white with appropriate opacity
                int opacity = 255 - whiteness; // darker pixel = more opaque
                opacity = Math.Min(255, (int)(opacity * 1.5)); // boost opacity
                result.SetPixel(x, y, Color.FromArgb(Math.Min(255, opacity), 255, 255, 255));
            }
        }
    }
    
    result.Save(outputPath, ImageFormat.Png);
    Console.WriteLine($"Saved white logo with transparent background to: {outputPath}");
    Console.WriteLine($"Dimensions: {result.Width}x{result.Height}");
}
