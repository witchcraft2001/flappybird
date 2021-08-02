using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

namespace ImageCutter
{
    class Program
    {
        static void Main(string[] args)
        {
            if (args.Length > 0)
            {
                try
                {
                    if (File.Exists(args[0]))
                    {
                        using (var reader = new StreamReader(args[0]))
                        {
                            while (!reader.EndOfStream)
                            {
                                var line = reader.ReadLine();
                                if (line != null)
                                {
                                    var lineArgs = line.Split(" ");
                                    if (lineArgs.Length == 6 && 
                                        File.Exists(lineArgs[0]) && 
                                        Int16.TryParse(lineArgs[2], out var x) &&
                                        Int16.TryParse(lineArgs[3], out var y) &&
                                        Int16.TryParse(lineArgs[4], out var width) &&
                                        Int16.TryParse(lineArgs[5], out var height) && 
                                        width > 0 && height > 0)
                                    {
                                        ProcessFile(lineArgs[0], lineArgs[1], x, y, width, height);
                                    }
                                }
                            }
                        }
                    }
                }
                catch (Exception e)
                {
                    Console.WriteLine(e.Message);
                    Environment.Exit(-1);
                }
            }
            else
            {
                Console.WriteLine("Usage: ImageCutter.exe file.txt");
            }
        }

        private static void ProcessFile(string file, string outputFile, in short x, in short y, in short width, in short height)
        {
            Bitmap bmp = new Bitmap(file);
            if (bmp.Width >= x + width && bmp.Height >= y + height)
            {
                var newBmp = new Bitmap(width, height);
                for (int i = 0; i < width; i++)
                {
                    for (int j = 0; j < height; j++)
                    {
                        var color = bmp.GetPixel(i + x, j + y);
                        newBmp.SetPixel(i, j, color);
                    }
                }
                if (File.Exists(outputFile))
                    File.Delete(outputFile);

                newBmp.Save(outputFile, ImageFormat.Png);
            }
        }
    }
}
