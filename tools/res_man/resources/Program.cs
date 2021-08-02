using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Text;

namespace resources
{
    class Program
    {
        static List<Color> palette = new List<Color>(256);

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
                                var filename = reader.ReadLine();
                                if (filename != null && File.Exists(filename))
                                {
                                    var outputFile = Path.GetFileNameWithoutExtension(filename) + ".bin";
                                    ProcessFile(filename, outputFile);
                                }
                            }
                        }

                        var sb = new StringBuilder();
                        sb.AppendLine($"        ;Palette of {palette.Count} colors");
                        sb.AppendLine($"        db  {palette.Count}");
                        foreach (var color in palette)
                        {
                            sb.AppendFormat("        db  0x{0:X2}, 0x{1:X2}, 0x{2:X2}, 0x00", color.B, color.G, color.R);
                            sb.AppendLine();
                        }

                        var outputPaletteFile = Path.GetFileNameWithoutExtension(args[0]) + "_pal.asm";
                        File.WriteAllText(outputPaletteFile, sb.ToString());
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
                Console.WriteLine("Usage: resources.exe file.txt");
            }
        }

        static void ProcessFile(string file, string outfile)
        {
            //var img = Image.FromFile(file);
            var counter = 0;
            var lenght = 0;
            var resultFileName = GetFileName(outfile, counter++);
            Bitmap bmp = new Bitmap(file);
            BinaryWriter writer = null;
            try
            {
                writer = new BinaryWriter(File.Open(resultFileName, FileMode.Create));
                MergePalettes(bmp.Palette);

                for (int y = 0; y < bmp.Height; y++)
                {
                    //Не допускаем висящие строки спрайта в разных страницах - вся строка должна размещаться в пределах одной страницы
                    if (lenght + bmp.Width > 16384)
                    {
                        lenght = 0;
                        writer.Flush();
                        writer.Close();
                        resultFileName = GetFileName(outfile, counter++);
                        writer = new BinaryWriter(File.Open(resultFileName, FileMode.Create));
                    }

                    for (int x = 0; x < bmp.Width; x++)
                    {
                        var color = bmp.GetPixel(x, y);
                        if (color.A != 255)
                        {
                            Debug.WriteLine(color.A);
                        }
                        var index = color.A == 255 ? 
                            AddColorIfNotExists(color) :
                            // (byte) palette.IndexOf(color) : 
                            (byte) 255;
                        writer.Write(index);
                        lenght++;
                    }
                }

            }
            finally
            {
                writer?.Flush();
                writer?.Close();
            }
        }

        static string GetFileName(string file, int counter)
        {
            if (counter == 0)
                return file;
            var extension = Path.GetExtension(file);
            var dir = Path.GetDirectoryName(file);
            var name = Path.GetFileNameWithoutExtension(file);
            return Path.Combine(dir, name + "." + (extension.Length > 1 ? extension[1] : 'b') + (counter - 1).ToString("00"));
        }

        static byte AddColorIfNotExists(Color color)
        {
            if (!palette.Contains(color))
            {
                if (palette.Count >= 255)
                    throw new Exception("The size of the palette table is exceeded");
                palette.Add(color);
            }

            return (byte)palette.IndexOf(color);
        }

        static void MergePalettes(ColorPalette local)
        {
            foreach (var color in local.Entries)
            {
                if (color.A != 255)
                    continue;

                if (!palette.Contains(color))
                    palette.Add(color);
            }

            if (palette.Count > 256)
                throw new Exception("The size of the palette table is exceeded");
        }
    }
}