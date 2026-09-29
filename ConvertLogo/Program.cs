using SkiaSharp;

string inputPath = @"c:\WEBDEV\AspireApp1\AspireApp1.Web\wwwroot\Source\General\logo.png";
string outputPath = @"c:\WEBDEV\AspireApp1\AspireApp1.Web\wwwroot\Source\General\logo-white.png";

using var inputStream = File.OpenRead(inputPath);
using var bitmap = SKBitmap.Decode(inputStream);
using var result = new SKBitmap(bitmap.Width, bitmap.Height, SKColorType.Rgba8888, SKAlphaType.Premul);

for (int x = 0; x < bitmap.Width; x++)
{
    for (int y = 0; y < bitmap.Height; y++)
    {
        var pixel = bitmap.GetPixel(x, y);
        
        // Calculate luminance/whiteness
        int whiteness = (pixel.Red + pixel.Green + pixel.Blue) / 3;
        
        if (whiteness > 230)
        {
            // White/near-white → transparent
            result.SetPixel(x, y, new SKColor(255, 255, 255, 0));
        }
        else
        {
            // Dark content → make white with opacity based on darkness
            byte opacity = (byte)Math.Min(255, (255 - whiteness) * 2);
            result.SetPixel(x, y, new SKColor(255, 255, 255, opacity));
        }
    }
}

using var image = SKImage.FromBitmap(result);
using var data = image.Encode(SKEncodedImageFormat.Png, 100);
using var outputStream = File.OpenWrite(outputPath);
data.SaveTo(outputStream);

Console.WriteLine($"✅ Saved white logo with transparent background");
Console.WriteLine($"   Input:  {inputPath}");
Console.WriteLine($"   Output: {outputPath}");
Console.WriteLine($"   Size:   {bitmap.Width}x{bitmap.Height}");
