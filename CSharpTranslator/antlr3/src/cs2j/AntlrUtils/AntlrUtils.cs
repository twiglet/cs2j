using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Antlr.Runtime.Tree;

namespace RusticiSoftware.Translator.AntlrUtils
{
    public class AntlrUtils
    {
        /// <summary> DumpNodes
        /// The CommonTreeNodeStream has a tree in "flat form".  The UP and DOWN tokens represent the branches of the
        /// tree.  Dump these out in tree form to the console.
        /// </summary>
        public static void DumpNodes(CommonTreeNodeStream nodes)
        {
            Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine("Nodes");
            int spaces = 0;
            string str_spaces = "                                                                                       ";
            object o_prev = string.Empty;
            //for (int n = 0; n < nodes.Count; ++n)
            object o = nodes.NextElement();
            while (!nodes.IsEndOfFile(o))
            {
                //object o = nodes.Get(n);
                //object o = nodes[n];

                if (o.ToString() == "DOWN")
                {
                    spaces += 2;
                    if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
                        Console.Write("\r\n{0} {1}", str_spaces.Substring(0, spaces), o_prev);
                }
                else if (o.ToString() == "UP")
                {
                    spaces -= 2;
                    if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
                        Console.Write(" {0}\r\n{1}", o_prev, str_spaces.Substring(0, spaces));
                }
                else if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
                    Console.Write(" {0}", o_prev.ToString());

                o_prev = o;
                o = nodes.NextElement();
            }
            if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
                Console.WriteLine(" {0}", o_prev.ToString());
            Console.ResetColor();
        }

        public static void DumpNodesFlat(CommonTreeNodeStream nodes)
        {
            DumpNodesFlat(nodes, "Nodes");
        }

        public static void DumpNodesFlat(CommonTreeNodeStream nodes, string title)
        {
            Console.ForegroundColor = ConsoleColor.Magenta;
            Console.WriteLine(title);
            //object o_prev = string.Empty;
            object o = nodes.NextElement();
            while (!nodes.IsEndOfFile(o))
            {
                if (o.ToString() == "DOWN")
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.Write("{");
                    Console.ForegroundColor = ConsoleColor.Magenta;
                }
                else if (o.ToString() == "UP")
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.Write(" }");
                    Console.ForegroundColor = ConsoleColor.Magenta;
                }
//                 if (o.ToString() == "DOWN")
//                 {
//                     if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
//                         Console.Write("  {0}{}", o_prev);
//                 }
//                 else if (o.ToString() == "UP")
//                 {
//                     if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
//                         Console.Write("  {0} ]", o_prev);
//                 }
                else
                {
                    Console.Write(" {0}", o.ToString());
                }


                o = nodes.NextElement();
            }
//             if (o_prev.ToString() != "UP" && o_prev.ToString() != "DOWN")
//                 Console.Write(" {0}", o_prev.ToString());
            Console.WriteLine();
            Console.ResetColor();
        }

    }
}
