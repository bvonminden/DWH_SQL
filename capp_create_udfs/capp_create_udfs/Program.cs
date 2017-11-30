using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;

namespace capp_create_udfs
{
    class Program
    {
        static void Main(string[] args)
        {

            if (File.Exists("output.sql"))
                File.Delete("output.sql"); 

            List<worker> items = new List<worker>();
            IEnumerable<string> pseudo_work = File.ReadAllLines("pseudo_work.txt");

            foreach (string s in pseudo_work)
                items.Add(new worker(s));

            string udf_template = File.ReadAllText("udf_template.txt");

            IEnumerable<string> udfs = (from x in items
                        select x.survey_name).Distinct();

            foreach (string current_udf in udfs)
            {
                IEnumerable<string> pseudos = (from x in items
                                               where x.survey_name == current_udf
                                              select x.pseudo);
                int count = (from x in items
                             where x.survey_name == current_udf
                             select x.pseudo).Count();
                int counter = 0;

                string current_udf_name = (from x in items where x.survey_name==current_udf select x.clean_name).First();
                StringBuilder template = new StringBuilder(udf_template);
                StringBuilder table_lines = new StringBuilder();
                StringBuilder select_lines = new StringBuilder();

                foreach (string pseudo in pseudos)
                {
                    counter++;

                    if (counter < count)
                    {
                        table_lines.AppendLine($"{pseudo} varchar(256),");
                        select_lines.AppendLine($"max(case sq.pseudonym when '{pseudo}' then  secured_value else null end) as {pseudo},");
                    }
                    else
                    {
                        table_lines.AppendLine($"{pseudo} varchar(256)");
                        select_lines.AppendLine($"max(case sq.pseudonym when '{pseudo}' then  secured_value else null end) as {pseudo}");
                    }
                }

                template.Replace("(UDFNAME)", current_udf_name);
                template.Replace("(PSEUDOLIST_TABLE)", table_lines.ToString());
                template.Replace("(PSEUDO_SELECT)", select_lines.ToString());
                template.Replace("(SURVEY_NAME)", current_udf);

                File.AppendAllText("output.sql",template.ToString());


            }


            Console.ReadLine();
        }





        public class worker {
            public string survey_name { get; set; }
            public string clean_name { get; set; }
            public string pseudo { get; set; }

            public worker(string line)
            {
                string[] line_work = line.Split(char.Parse(","));

                survey_name = line_work[0].Trim();
                clean_name = line_work[1].Trim();
                pseudo = line_work[2].Trim();
            }

        }
    }
}
