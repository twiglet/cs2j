namespace RusticiSoftware.Translator.CSharp
{
    using System;
    using Path = System.IO.Path;
    using Antlr.Runtime;
    using RusticiSoftware.Translator.CSharp;
    using System.IO;
    using Antlr.Runtime.Tree;

    public class MinDriver
    {

        public static void MinDriverMain(string[] args)
        {
            if (args.Length > 0)
            {
                string inputFileName = args[1];
                if (!Path.IsPathRooted(inputFileName))
                {
                    inputFileName = Path.Combine(Environment.CurrentDirectory, inputFileName);
                }
                if (!File.Exists(inputFileName))
                {
                    Console.Error.WriteLine("Error: Can't find file " + inputFileName);
                }
                else
                {
                    CommonTokenStream tokens = null;

                    Console.WriteLine("Parsing " + Path.GetFileName(inputFileName));
                    PreProcessor lex = new PreProcessor();;

                    ICharStream input = new ANTLRFileStream(inputFileName);
                    lex.CharStream = input;

                    tokens = new CommonTokenStream(lex);
                    csParser p = new csParser(tokens);
                    csParser.compilation_unit_return parser_rt;

                    parser_rt = p.compilation_unit();

                    Console.Out.WriteLine(((ITree)parser_rt.Tree).ToStringTree());
                }
            }
            else
                Console.Error.WriteLine("Usage: minDriver <input-file>");
        }
    }
}