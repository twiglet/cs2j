namespace RusticiSoftware.Translator.CSharp
{
    using System;
    using Path = System.IO.Path;
    using Antlr.Runtime;
    using RusticiSoftware.Translator.CSharp;

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
                ICharStream input = new ANTLRFileStream(inputFileName);
                PreProcessor lex = new PreProcessor(input);
                ITokenStream tokens = new TokenRewriteStream(lex);
                csParser parser = new csParser(tokens);
                parser.compilation_unit();
                Console.Out.WriteLine(tokens);
            }
            else
                Console.Error.WriteLine("Usage: minDriver <input-file>");
        }
    }
}