using RusticiSoftware.Translator.Utils;
using RusticiSoftware.Translator.CLR;
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
				
				// Just take last argument so that we ignore any passed options
				
                string inputFileName = args[args.Length - 1];
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
                    ITree parse_tree = (ITree)parser_rt.Tree;
                    Console.Out.WriteLine(parse_tree.ToStringTree());

                    CommonTreeNodeStream display_nodes = new CommonTreeNodeStream(parse_tree);
                    AntlrUtils.AntlrUtils.DumpNodes(display_nodes); 
                    
                    BufferedTreeNodeStream nodes = new BufferedTreeNodeStream(parse_tree);
					nodes.TokenStream = tokens;

                    TemplateExtracter templateWalker = new TemplateExtracter(nodes);
                    templateWalker.Cfg = new CS2JSettings();
                    templateWalker.AppEnv = new DirectoryHT<TypeRepTemplate>();
                    templateWalker.compilation_unit();

                }
            }
            else
                Console.Error.WriteLine("Usage: minDriver <input-file>");
        }
    }
}