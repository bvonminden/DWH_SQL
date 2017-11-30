using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace capp_create_sprocs
{
    class Program
    {
        static void Main(string[] args)
        {

            string 
                header = File.ReadAllText("header_body.txt");
            string 
                footer = File.ReadAllText("footer_body.txt");
            IEnumerable<string>
                work = File.ReadLines("sproc_work.txt");


            foreach (string s in work)
            {
                StringBuilder sb = new StringBuilder();
                string[] cols = s.Split(Char.Parse(","));

                // first proc part
              sb.Append(header.Replace("!!", cols[0]));

                int idx = -1;
                foreach (string c in cols)
                {
                    idx++;
                    if (string.IsNullOrWhiteSpace(c) | idx<=0)
                        continue;

                    sb.AppendLine($"vbase.{c},");
                }

                sb.AppendLine();
                sb.AppendLine(footer.Replace("!!", cols[0]));

                File.WriteAllText(cols[0],sb.ToString());
            }
               
            
            Console.ReadLine();
        }
    }
}
