using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace capp_get_headers
{
    class Program
    {

        static void Main(string[] args)
        {
            
            string      dir         = Console.ReadLine();
            string[]    work        = Directory.GetDirectories(@"z:\");
            TextWriter  tresults    = File.CreateText("results.txt");

            Console.WriteLine($"found {work?.Count()}, press a key to start");
            Console.ReadLine();

            foreach (string  work_target in work)
            {
                string[] files  = Directory.GetFiles(work_target, "*.txt", SearchOption.AllDirectories);
                Console.WriteLine($"{files?.Count()} items found");

                foreach (string file in files)
                {

                    using (TextReader tr = File.OpenText(file))
                    {
                        Console.WriteLine($"working on {file }");
                        string header = tr.ReadLine();
                        tresults.WriteLine($"{work_target} ! {file?.Replace(work_target,"").Replace(@"\","").Replace(".txt","")} ! {header?.Replace("\t","!").Replace("|","!")}");
                    }
                }
            }

            tresults.Close();
        }
    }
}
