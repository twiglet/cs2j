using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Collections;
using System.Xml;
using Antlr.Runtime.Tree;
using Antlr.Runtime;
using System.Xml.Serialization;

using NDesk.Options;

using RusticiSoftware.Translator.Utils;
using RusticiSoftware.Translator.AntlrUtils;
using RusticiSoftware.Translator.CLR;

namespace RusticiSoftware.Translator.CSharp
{
    class CS2J
    {
        private const string VERSION = "2009.1.1.x";

        public delegate void FileProcessor(string fName, Stream s);

        // show gui explorer of parse tree
        internal static bool showTree = false;
        internal static bool showCSharp = false;
        internal static bool showJavaSyntax = false;
        internal static bool showJava = false;
        internal static bool displayTokens = false;

        // dump parse tree to stdout
        internal static bool dumpCSharp = false;
        internal static bool dumpJavaSyntax = false;
        internal static bool dumpJava = false;

        internal static bool dumpXmls = false;
        internal static bool dumpEnums = false;
        internal static string outDir = ".";
        internal static string cheatDir = "";
        internal static IList<string> netRoot = new List<string>();
        internal static IList<string> exNetRoot = new List<string>();
        internal static IList<string> appRoot = new List<string>();
        internal static IList<string> exAppRoot = new List<string>();
        internal static IList<string> exclude = new List<string>();
        internal static DirectoryHT appEnv = new DirectoryHT(null);
        internal static IList<string> macroDefines = new List<string>();
        internal static XmlTextWriter enumXmlWriter = new XmlTextWriter(Path.Combine(Directory.GetCurrentDirectory(), "enums"), System.Text.Encoding.UTF8);
        internal static string xmldumpDir = Path.Combine(".", "tmpXMLs");
        internal static int verbosity = 0;

        private static void showVersion()
        {
            Console.Out.WriteLine(Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]) + ": " + VERSION);
        }

        private static void showUsage()
        {
            Console.Out.WriteLine("Usage: " + Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]));
            Console.Out.WriteLine(" [-help]                                                                     (this usage message)");
            Console.Out.WriteLine(" [-v]                                                                        (be [somewhat more] verbose, repeat for more verbosity)");
            Console.Out.WriteLine(" [-D <macroVariable>]                                                        (define <macroVariable>, option can be repeated)");
            Console.Out.WriteLine(" [-showtokens]                                                               (the lexer prints the tokenized input to the console)");
            Console.Out.WriteLine(" [-showtree] [-showcsharp] [-showjavasyntax] [-showjava]                      (show parse tree at various stages of the translation)");
            Console.Out.WriteLine(" [-dumpcsharp] [-dumpjavasyntax] [-dumpjava]                      (show parse tree at various stages of the translation)");
            Console.Out.WriteLine(" [-dumpxml] [-xmldir <directory to dump xml database>]                       (dump the translation repository as xml files)");
            Console.Out.WriteLine(" [-dumpenums <enum xml file>]                                                (create an xml file documenting enums)");
            Console.Out.WriteLine(" [-odir <root of translated classes>]");
            Console.Out.WriteLine(" [-cheatdir <root of translation 'cheat' files>]");
            Console.Out.WriteLine(" [-netdir <root of .NET Framework Class Library translations>+]              (can be multiple directories, separated by semi-colons)");
            Console.Out.WriteLine(" [-exnetdir <directories/files to be excluded from translation repository>+] (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-appdir <root of C# application>]");
            Console.Out.WriteLine(" [-exappdir <directories/files to be excluded from translation repository>+] (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-exclude <directories/files to be excluded from translation>+]             (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" <directory or file name to be translated>");
            Environment.Exit(0);
        }
		
		private static void addDirectories(IList<string> strs, string rawStr) {
            string[] argDirs = rawStr.Split(';');
            for (int i = 0; i < argDirs.Length; i++)
                strs.Add(Path.GetFullPath(argDirs[i]).ToLower());
		}
		
        public static void CS2JMain(string[] args)
        {
            long startTime = DateTime.Now.Ticks;
			IList<string> remArgs = new List<string>();
            // Use a try/catch block for parser exceptions
            try
            {
                // if we have at least one command-line argument
                if (args.Length > 0)
                {
			
                    if (verbosity >= 2) Console.Error.WriteLine("Parsing Command Line Arguments...");

					OptionSet p = new OptionSet ()
						.Add ("v", v => verbosity++)
						.Add ("version", v => showVersion())
    					.Add ("help|h|?", v => showUsage())
    					.Add ("showtree", v => showTree = true)
    					.Add ("showcsharp", v => showCSharp = true)
						.Add ("showjava", v => showJava = true)
						.Add ("showjavasyntax", v => showJavaSyntax = true)
    					.Add ("dumpcsharp", v => dumpCSharp = true)
						.Add ("dumpjava", v => dumpJava = true)
						.Add ("dumpjavasyntax", v => dumpJavaSyntax = true)
						.Add ("tokens", v => displayTokens = true)
    					.Add ("D=", def => macroDefines.Add(def)) 							
    					.Add ("dumpenums", v => dumpEnums = true)
    					.Add ("enumdir=", dir => enumXmlWriter = new XmlTextWriter(dir, System.Text.Encoding.UTF8))							
    					.Add ("dumpxmls", v => dumpXmls = true)
    					.Add ("xmldir=", dir => xmldumpDir = Path.Combine(Directory.GetCurrentDirectory(), dir))
    					.Add ("odir=", dir => outDir = dir)
    					.Add ("cheatdir=", dir => cheatDir = dir)
    					.Add ("netdir=", dirs => addDirectories(netRoot, dirs))
    					.Add ("exnetdir=", dirs => addDirectories(exNetRoot, dirs))
    					.Add ("appdir=", dirs => addDirectories(appRoot, dirs))
    					.Add ("exappdir=", dirs => addDirectories(exAppRoot, dirs))
    					.Add ("exclude=", dirs => addDirectories(exclude, dirs))
						;

                   	// Final argument is translation target
					remArgs = p.Parse (args);

                            
					// Load .Net templates
                    foreach (string r in netRoot)
                        doFile(new FileInfo(r), ".xml", addNetTranslation, exNetRoot);

                    // Load Application Class Signatures (i.e. generate templates)
                    if (appRoot.Count == 0)
                        // By default translation target is application root
                        appRoot.Add(remArgs[0]);
                    foreach (string r in appRoot)
                        doFile(new FileInfo(r), ".cs", addAppSigTranslation, exAppRoot); // parse it
                    if (dumpXmls)
                    {
                        // Get package name and convert to directory name
                        foreach (DictionaryEntry de in appEnv)
                        {
                            String xmlFName = Path.Combine(xmldumpDir,
                                                          ((string)de.Key).Replace('.', Path.DirectorySeparatorChar) + ".xml");
                            String xmlFDir = Path.GetDirectoryName(xmlFName);
                            if (!Directory.Exists(xmlFDir))
                            {
                                Directory.CreateDirectory(xmlFDir);
                            }
                            XmlSerializer s = new XmlSerializer(de.Value.GetType());
                            TextWriter w = new StreamWriter(xmlFName);
                            s.Serialize(w, de.Value);
                            w.Close();
                        }
                    }
                    // keving: comment out for now   doFile(new FileInfo(args[i]), ".cs", translateFile, exclude); // parse it
                    if (enumXmlWriter != null)
                    {
                        enumXmlWriter.WriteEndElement();
                        enumXmlWriter.Close();
                    }
                }
                else
                {
                    showUsage();
                }
            }
            catch (System.Exception e)
            {
                Console.Error.WriteLine("exception: " + e);
                Console.Error.WriteLine(e.StackTrace); // so we can get stack trace
            }
            double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
            if (verbosity >= 1)
            {
                System.Console.Out.WriteLine("");
                System.Console.Out.WriteLine("");
                System.Console.Out.WriteLine("Total run time was {0} seconds.", elapsedTime);
            }
        }


        // Call processFile on all files below f that have the given extension 
        public static void doFile(FileInfo f, string ext, FileProcessor processFile, IList<string> excludes)
        {
            // If this is a directory, walk each file/dir in that directory
            if (!excludes.Contains(Path.GetFullPath(f.FullName).ToLower()))
            {
                if (Directory.Exists(f.FullName))
                {
                    string[] files = Directory.GetFileSystemEntries(f.FullName);
                    for (int i = 0; i < files.Length; i++)
                        doFile(new FileInfo(Path.Combine(f.FullName, files[i])), ext, processFile, excludes);
                }
                else if ((f.Name.Length > ext.Length) && f.Name.Substring(f.Name.Length - ext.Length).Equals(ext))
                {
                    FileStream fs = null;
                    if (verbosity >= 2) Console.WriteLine("   " + f.FullName);
                    try
                    {
                        Stream s = new FileStream(f.FullName, FileMode.Open, FileAccess.Read);
                        processFile(f.FullName, s);
                    }
                    catch (Exception e)
                    {
                        Console.Error.WriteLine("\nCannot process file: " + f.FullName);
                        Console.Error.WriteLine("exception: " + e);
                    }
                    finally
                    {
                        if (fs != null) fs.Close();
                    }
                }
            }
        }

        public static CommonTreeNodeStream parseFile(string fullName, Stream s)
        {
            CommonTokenStream tokens = null;

            Console.WriteLine("Parsing " + Path.GetFileName(fullName));
            PreProcessor lex = new PreProcessor();
            lex.AddDefine(macroDefines);

            ICharStream input = new ANTLRFileStream(fullName);
            lex.CharStream = input;

            tokens = new CommonTokenStream(lex);
            csParser p = new csParser(tokens);
            object parser_rt = p.compilation_unit();

            // Sometimes ANTLR returns a CommonErrorNode if we can't parse the file
            if (parser_rt is CommonErrorNode)
            {
                Console.WriteLine(((CommonErrorNode)parser_rt).trappedException.Message);
                return null;
            }

            CommonTree tree = (CommonTree)((RuleReturnScope)parser_rt).Tree;
            // Check if we didn't get an AST
            // This often happens if your grammar and tree grammar don't match
            if (tree == null)
            {
                if (tokens.Count > 0)
                {
                    Console.WriteLine("No Tree returned from parsing! (Your rule did not parse correctly)");
                }
                else
                {
                    // the file was empty, this is not an error.
                }
                return null;
            }

            // Get the AST stream
            CommonTreeNodeStream nodes = new CommonTreeNodeStream(tree);
            // Add the tokens for DumpNodes, otherwise there are no token names to print out.
            nodes.TokenStream = tokens;

            // Dump the tree nodes if -dumpcsharp is passed on the command line.
            if (dumpCSharp)
            {
                AntlrUtils.AntlrUtils.DumpNodes(nodes);
            }

            return nodes;

        }

        // Here's where we do the real work...
        public static void addNetTranslation(string fullName, Stream s)
        {
            TypeRepTemplate t = TypeRepTemplate.newInstance(s);
            appEnv[t.TypeName] = t;
        }

        // Here's where we do the real work...
        public static void addAppSigTranslation(string fullName, Stream s)
        {
            CommonTreeNodeStream t = parseFile(fullName, s);
            if (t != null)
            {
                // A prescan of all files to build an environment mapping qualified name to typereptemplate
                //    CSharpEnvBuilder envBuilder = new CSharpEnvBuilder();
                //    envBuilder.compilationUnit(t, null, appEnv);
            }
        }

        // Here's where we do the real work...		
        //public static void translateFile(string fullName, ICharStream s)
        //{
        //    string f = Path.GetFileName(fullName);

        //    ASTNode t = parseFile(f, s);
        //    if (t != null)
        //    {
        //        if (showTree)
        //        {
        //            ASTNode r = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
        //            r.setFirstChild(t);
        //            ASTFrame frame = new ASTFrame("C# AST for file [" + f + "]", r);
        //            frame.ShowDialog();
        //            //frame.Visible = true;
        //            // System.out.println(t.toStringList());
        //        }
        //        ASTNode r1 = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
        //        r1.setFirstChild(t);
        //        ASTFrame frame1 = new ASTFrame("C# AST for file [" + f + "]", r1);
        //        if (showCSharp)
        //            frame1.ShowDialog();

        //        CSharpTranslator transformer = new CSharpTranslator();
        //        transformer.setASTNodeClass(typeof(ASTNode).FullName);
        //        transformer.setASTFactory(new ASTNodeFactory());
        //        CSharpTranslator.initializeASTFactory(transformer.getASTFactory());

        //        long startTime = DateTime.Now.Ticks;
        //        transformer.compilationUnit(t, null);

        //        //BaseAST.setVerboseStringConversion(true, tokenNames);
        //        ASTNode r2 = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
        //        r2.setFirstChild(transformer.getAST());
        //        ASTFrame frame2 = new ASTFrame("Java syntax AST for file [" + f + "]", r2);
        //        if (showJavaSyntax)
        //            frame2.ShowDialog();

        //        // Take each java compilation unit (each class defn) and write it to the appropriate file 
        //        IEnumerator enumCU = transformer.getAST().findAllPartial((ASTNode)transformer.getASTFactory().create(CSharpParser.COMPILATION_UNIT));
        //        while (enumCU.MoveNext())
        //        {
        //            ASTNode javaCU = (ASTNode)enumCU.Current;

        //            // Extract class/interface name
        //            String claName = JavaTreeParser.getClassName(javaCU);

        //            // Get package name and convert to directory name
        //            String nsDir = "";
        //            foreach (String nsc in JavaTreeParser.getPackageName(javaCU))
        //            {
        //                nsDir = Path.Combine(nsDir, nsc);
        //            }

        //            // Build destination filename for this class
        //            String fName = Path.Combine(Path.Combine(outDir, nsDir), claName + ".java");

        //            if (cheatDir != "")
        //            {
        //                String cheatFile = Path.Combine(cheatDir, Path.Combine(nsDir, claName + ".java"));
        //                if (File.Exists(cheatFile))
        //                {
        //                    // the old switcheroo
        //                    File.Copy(cheatFile, fName, true);
        //                    continue;
        //                }

        //                String ignoreMarker = Path.Combine(cheatDir, Path.Combine(nsDir, claName + ".none"));
        //                if (File.Exists(ignoreMarker))
        //                {
        //                    // Don't generate this class
        //                    continue;
        //                }
        //            }

        //            NetTranslator netTx = new NetTranslator();
        //            netTx.setASTNodeClass(typeof(ASTNode).FullName);
        //            netTx.setASTFactory(new ASTNodeFactory());
        //            NetTranslator.initializeASTFactory(netTx.getASTFactory());
        //            netTx.compilationUnit(javaCU, null, appEnv);

        //            //BaseAST.setVerboseStringConversion(true, tokenNames);
        //            ASTNode r3 = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
        //            r3.setFirstChild(netTx.getAST());
        //            ASTFrame frame3 = new ASTFrame("Java AST for file [" + f + "]", r3);
        //            if (showJava)
        //                frame3.ShowDialog();

        //            Console.WriteLine(fName);

        //            String fDir = Path.GetDirectoryName(fName);
        //            if (!Directory.Exists(fDir))
        //            {
        //                Directory.CreateDirectory(fDir);
        //            }
        //            FileInfo outF = new FileInfo(fName);
        //            StreamWriter w = new StreamWriter(outF.Create());
        //            JavaPrettyPrinter writer = new JavaPrettyPrinter();
        //            writer.compilationUnit(netTx.getAST(), w, enumXmlWriter, filter);
        //            w.Close();

        //        }

        //        double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
        //        //System.Console.Out.WriteLine(writer.ToString());
        //        System.Console.Out.WriteLine("");
        //        System.Console.Out.WriteLine("");
        //        System.Console.Out.WriteLine("Pretty-printed {0} in: {1} seconds.", f, elapsedTime);
        //    }
        //}
    }
}
