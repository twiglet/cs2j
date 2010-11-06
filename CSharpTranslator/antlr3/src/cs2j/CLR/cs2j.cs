using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
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
		private static DirectoryHT<TypeRepTemplate> AppEnv { get; set; }
		private static CS2JSettings cfg = new CS2JSettings();
 
        public delegate void FileProcessor(string fName);

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
			XmlTextWriter enumXmlWriter = null;			
	        AppEnv = new DirectoryHT<TypeRepTemplate>(null);
			
            // Use a try/catch block for parser exceptions
            try
            {
                // if we have at least one command-line argument
                if (args.Length > 0)
                {
			
                    if (cfg.Verbosity >= 2) Console.Error.WriteLine("Parsing Command Line Arguments...");

					OptionSet p = new OptionSet ()
						.Add ("v", v => cfg.Verbosity++)
						.Add ("debug=", v => cfg.DebugLevel = Int32.Parse(v))
						.Add ("warnings", v => cfg.Warnings = true)
						.Add ("version", v => showVersion())
    					.Add ("help|h|?", v => showUsage())
    					.Add ("dumpcsharp", v => cfg.DumpCSharp = true)
						.Add ("dumpjava", v => cfg.DumpJava = true)
						.Add ("dumpjavasyntax", v => cfg.DumpJavaSyntax = true)
						.Add ("dumptokens", v => cfg.DisplayTokens = true)
    					.Add ("D=", def => cfg.MacroDefines.Add(def)) 							
    					.Add ("dumpenums", v => cfg.DumpEnums = true)
    					.Add ("enumdir=", dir => cfg.EnumDir = Path.Combine(Directory.GetCurrentDirectory(), dir))							
    					.Add ("dumpxmls", v => cfg.DumpXmls = true)
    					.Add ("xmldir=", dir => cfg.XmlDir = Path.Combine(Directory.GetCurrentDirectory(), dir))
    					.Add ("odir=", dir => cfg.OutDir = dir)
    					.Add ("cheatdir=", dir => cfg.CheatDir = dir)
    					.Add ("netdir=", dirs => addDirectories(cfg.NetRoot, dirs))
    					.Add ("exnetdir=", dirs => addDirectories(cfg.ExNetRoot, dirs))
    					.Add ("appdir=", dirs => addDirectories(cfg.AppRoot, dirs))
    					.Add ("exappdir=", dirs => addDirectories(cfg.ExAppRoot, dirs))
    					.Add ("exclude=", dirs => addDirectories(cfg.Exclude, dirs))
						;
					
					//TODO: fix enum dump
                   	// Final argument is translation target
					remArgs = p.Parse (args);

                            
					// Load .Net templates
                    foreach (string r in cfg.NetRoot)
                        doFile(r, ".xml", addNetTranslation, cfg.ExNetRoot);

                    // Load Application Class Signatures (i.e. generate templates)
                    if (cfg.AppRoot.Count == 0)
                        // By default translation target is application root
                        cfg.AppRoot.Add(remArgs[0]);
                    foreach (string r in cfg.AppRoot)
                        doFile(r, ".cs", addAppSigTranslation, cfg.ExAppRoot); // parse it
					if (cfg.DumpEnums) {
						 enumXmlWriter = new XmlTextWriter(cfg.EnumDir, System.Text.Encoding.UTF8);
					}
                    if (cfg.DumpXmls)
                    {
                        // Get package name and convert to directory name
                        foreach (KeyValuePair<string,TypeRepTemplate> de in AppEnv)
                        {
                            String xmlFName = Path.Combine(cfg.XmlDir,
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
                    doFile(remArgs[0], ".cs", translateFile, cfg.Exclude); // parse it
                    if (cfg.DumpEnums)
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
            if (cfg.Verbosity >= 1)
            {
                System.Console.Out.WriteLine("");
                System.Console.Out.WriteLine("");
                System.Console.Out.WriteLine("Total run time was {0} seconds.", elapsedTime);
            }
        }


        // Call processFile on all files below f that have the given extension 
        public static void doFile(string root, string ext, FileProcessor processFile, IList<string> excludes)
        {
			string canonicalPath = Path.GetFullPath(root);
            // If this is a directory, walk each file/dir in that directory
            if (!excludes.Contains(canonicalPath.ToLower()))
            {
                if (Directory.Exists(canonicalPath))
                {
                    string[] files = Directory.GetFileSystemEntries(canonicalPath);
                    for (int i = 0; i < files.Length; i++)
                        doFile(Path.Combine(canonicalPath, files[i]), ext, processFile, excludes);
                }
                else if ((Path.GetFileName(canonicalPath).Length > ext.Length) && canonicalPath.Substring(canonicalPath.Length - ext.Length).Equals(ext))
                {
                    if (cfg.Verbosity >= 2) Console.WriteLine("   " + canonicalPath);
                    try
                    {
                        
                        processFile(canonicalPath);
                    }
                    catch (Exception e)
                    {
                        Console.Error.WriteLine("\nCannot process file: " + canonicalPath);
                        Console.Error.WriteLine("exception: " + e);
                    }
                }
            }
        }

        public static CommonTreeNodeStream parseFile(string fullName)
        {
            
            if (cfg.Verbosity > 2) Console.WriteLine("Parsing " + Path.GetFileName(fullName));
            
			ICharStream input = new ANTLRFileStream(fullName);

			PreProcessor lex = new PreProcessor();
			lex.AddDefine(cfg.MacroDefines);
            lex.CharStream = input;
			lex.TraceDestination = Console.Error;

            CommonTokenStream tokens = new CommonTokenStream(lex);
            csParser p = new csParser(tokens);
			p.TraceDestination = Console.Error;
			
            csParser.compilation_unit_return parser_rt = p.compilation_unit();

            if (parser_rt == null || parser_rt.Tree == null)
            {
                if (lex.FoundMeat)
                {
                    Console.WriteLine("No Tree returned from parsing! (Your rule did not parse correctly)");
                }
                else
                {
                    // the file was empty, this is not an error.
                }
                return null;
            }

            CommonTreeNodeStream nodes = new CommonTreeNodeStream(parser_rt.Tree);            
			nodes.TokenStream = tokens;
			
			return nodes;

        }
      // Here's where we do the real work...
        public static void addNetTranslation(string fullName)
        {
            Stream s = new FileStream(fullName, FileMode.Open, FileAccess.Read);
			TypeRepTemplate t = TypeRepTemplate.newInstance(s);
            AppEnv[t.TypeName] = t;
        }

        // Here's where we do the real work...
        public static void addAppSigTranslation(string fullName)
        {
			if (cfg.DebugLevel > 3) Console.Out.WriteLine("Extracting type info from file {0}", fullName);
            ITreeNodeStream csTree = parseFile(fullName);
            if (csTree != null)
            {
 
                    TemplateExtracter templateWalker = new TemplateExtracter(csTree);
                    templateWalker.Filename = fullName;
					templateWalker.TraceDestination = Console.Error;
				
                    templateWalker.compilation_unit(cfg, AppEnv);
            }
        }

        // Here's where we do the real work...		
        public static void translateFile(string fullName)
        {
			if (cfg.DebugLevel > 3) Console.Out.WriteLine("Translating file {0}", fullName);
			CommonTreeNodeStream csTree = parseFile(fullName);
			if (cfg.DumpCSharp && csTree != null) AntlrUtils.AntlrUtils.DumpNodes(csTree);
			
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

         //      }

        //        double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
        //        //System.Console.Out.WriteLine(writer.ToString());
        //        System.Console.Out.WriteLine("");
        //        System.Console.Out.WriteLine("");
        //        System.Console.Out.WriteLine("Pretty-printed {0} in: {1} seconds.", f, elapsedTime);
        //    }
        }
    }
}
