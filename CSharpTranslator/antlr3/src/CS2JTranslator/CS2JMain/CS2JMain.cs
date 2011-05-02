/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using System.Xml;
using Antlr.Runtime.Tree;
using Antlr.Runtime;
using System.Xml.Serialization;

using System.Security.Cryptography;
using System.Security.Cryptography.Xml;

using Antlr.StringTemplate;

using NDesk.Options;

using AntlrCSharp;

using Twiglet.CS2J.Translator.Utils;
using Twiglet.CS2J.Translator.Transform;
using Twiglet.CS2J.Translator.TypeRep;

using CS2JConstants = Twiglet.CS2J.Translator.Utils.Constants;
using Twiglet.CS2J.Translator.Extract;

namespace Twiglet.CS2J.Translator
{
    class CS2J
    {
       private const string VERSION = "2011.1.1";
       private static DirectoryHT<TypeRepTemplate> AppEnv { get; set; }
       private static CS2JSettings cfg = new CS2JSettings();
       private static StringTemplateGroup templates = null;

       private static RSACryptoServiceProvider RsaKey = null;
       private static int badXmlTxCountTrigger = 3 + 4 - 2;
       private static int badXmlTxCount = badXmlTxCountTrigger;
		
       private static String[] newLines = new String[] { "\n", Environment.NewLine };
       private static int numLines = (10 * 10) + 50 - 30;
		
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
            Console.Out.WriteLine(" [-showcsharp] [-showjavasyntax] [-showjava]                                 (show parse tree at various stages of the translation)");
            Console.Out.WriteLine(" [-dumpxml] [-xmldir <directory to dump xml database>]                       (dump the translation repository as xml files)");
            Console.Out.WriteLine(" [-dumpenums <enum xml file>]                                                (create an xml file documenting enums)");
            Console.Out.WriteLine(" [-netdir <root of .NET Framework Class Library translations>+]              (can be multiple directories, separated by semi-colons)");
            Console.Out.WriteLine(" [-exnetdir <directories/files to be excluded from translation repository>+] (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-appdir <root of C# application>]");
            Console.Out.WriteLine(" [-exappdir <directories/files to be excluded from translation repository>+] (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-csdir <directories/files to be translated>+]                              (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-excsdir <directories/files to be excluded from translation>+]             (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-odir <root of translated classes>]");
            Console.Out.WriteLine(" [-cheatdir <root of translation 'cheat' files>]");
            Console.Out.WriteLine(" [-debug <level>]                                                            (set debug level, default 0)");
            Console.Out.WriteLine(" [-debug-template-extraction <true/false>]                                   (show debug messages during template extraction, default true)");
            Console.Out.WriteLine(" [-warnings <true/false>]                                                    (show warnings, default true)");
            Console.Out.WriteLine(" [-warning-resolve-failures <true/false>]                                    (show warnings for resolve failures, default true)");
            Console.Out.WriteLine(" [-translator-keep-parens <true/false>]                                      (keep parens from source, default true)");
            Console.Out.WriteLine(" <directory or file name to be translated>");
            Environment.Exit(0);
        }
		
        private static void addDirectories(IList<string> strs, string rawStr) {
            string[] argDirs = rawStr.Split(';');
            for (int i = 0; i < argDirs.Length; i++)
                strs.Add(Path.GetFullPath(argDirs[i]));
        }
		
        public static void CS2JMain(string[] args)
        {
            long startTime = DateTime.Now.Ticks;
            IList<string> csDir = new List<string>();
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
                        .Add ("debug-template-extraction=", v => cfg.DebugTemplateExtraction = Boolean.Parse(v))
                        .Add ("warnings=", v => cfg.Warnings = Boolean.Parse(v))
                        .Add ("warnings-resolve-failures=", v => cfg.WarningsFailedResolves = Boolean.Parse(v))
                        .Add ("version", v => showVersion())
                        .Add ("help|h|?", v => showUsage())
                        .Add ("showcsharp", v => cfg.DumpCSharp = true)
                        .Add ("showjava", v => cfg.DumpJava = true)
                        .Add ("showjavasyntax", v => cfg.DumpJavaSyntax = true)
                        .Add ("showtokens", v => cfg.DisplayTokens = true)
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
                        .Add ("csdir=", dirs => addDirectories(csDir, dirs))
                        .Add ("excsdir=", dirs => addDirectories(cfg.Exclude, dirs))
                        .Add ("keyfile=", v => cfg.KeyFile = v)
                        .Add ("translator-keep-parens=", v => cfg.TranslatorKeepParens = Boolean.Parse(v))
                        .Add ("translator-timestamp-files=", v => cfg.TranslatorAddTimeStamp = Boolean.Parse(v))
                        .Add ("translator-exception-is-throwable=", v => cfg.TranslatorExceptionIsThrowable = Boolean.Parse(v))
                        .Add ("experimental-transforms=", v => cfg.ExperimentalTransforms = Boolean.Parse(v))
                        .Add ("internal-isjavaish", v => cfg.InternalIsJavaish = true)
                        ;
					
                    //TODO: fix enum dump
                    // Final argument is translation target
                    foreach (string s in p.Parse (args))
                    {
                       addDirectories(csDir, s);
                    }

                    if (csDir == null || csDir.Count == 0)
                        // No work
                        Environment.Exit(0);
 

                    // Initialise RSA signing key so that we can verify signatures
                    RsaKey = new RSACryptoServiceProvider();
                    string rsaPubXml = RSAPubKey.PubKey;
// Comment out code to read pub key from a file. To easy to re-sign xml files and import your own key!
//                    if (!String.IsNullOrEmpty(cfg.KeyFile))
//                    {
//                       XmlReader reader =  XmlReader.Create(cfg.KeyFile);
//                       reader.MoveToContent();
//                       rsaPubXml = reader.ReadOuterXml();
//                    }
                    RsaKey.FromXmlString(rsaPubXml);

                    // Load .Net templates
                    foreach (string r in cfg.NetRoot)
                        doFile(r, ".xml", addNetTranslation, cfg.ExNetRoot);

                    // Load Application Class Signatures (i.e. generate templates)
                    if (cfg.AppRoot.Count == 0)
                    {
                        // By default translation target is application root
                       foreach (string s in csDir)
                       {
                          cfg.AppRoot.Add(s);
                       }
                    }
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
                            XmlSerializer s = new XmlSerializer(de.Value.GetType(), CS2JConstants.TranslationTemplateNamespace);
                            TextWriter w = new StreamWriter(xmlFName);
                            s.Serialize(w, de.Value);
                            w.Close();
                        }
                    }

                    // load in T.stg template group, put in templates variable
                    string templateLocation = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, Path.Combine("templates", "java.stg"));
                    if (File.Exists(templateLocation)) {
                       TextReader groupFileR = new StreamReader(templateLocation);
                       templates = new StringTemplateGroup(groupFileR);
                       groupFileR.Close();
                    }
                    else {
                        templates = new StringTemplateGroup(new StringReader(Templates.JavaTemplateGroup));
                    }

                    foreach (string r in csDir)
                        doFile(r, ".cs", translateFile, cfg.Exclude); // translate it

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
                System.Console.Out.WriteLine("Total run time was {0} seconds.", elapsedTime);
            }
        }


        // Call processFile on all files below f that have the given extension 
        public static void doFile(string root, string ext, FileProcessor processFile, IList<string> excludes)
        {
            string canonicalPath = Path.GetFullPath(root);
            // If this is a directory, walk each file/dir in that directory
            if (!excludes.Contains(canonicalPath))
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
//            if (tokens.LT(1).Type == TokenTypes.EndOfFile)
//            {
//                Console.WriteLine("File is empty");
//                return null;
//            }
            csParser p = new csParser(tokens);
            p.TraceDestination = Console.Error;
            p.IsJavaish = cfg.InternalIsJavaish;
			
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


       // Verify the signature of an XML file against an asymmetric 
       // algorithm and return the result.
       public static Boolean VerifyXml(XmlDocument Doc, RSA Key)
       {
          // Check arguments.
          if (Doc == null)
             throw new ArgumentException("Doc");
          if (Key == null)
             throw new ArgumentException("Key");
			
          // Add the namespace.
          XmlNamespaceManager nsmgr = new XmlNamespaceManager(Doc.NameTable);
          nsmgr.AddNamespace("ss", "http://www.w3.org/2000/09/xmldsig#");

          XmlNode root = Doc.DocumentElement;
          XmlNodeList nodeList = root.SelectNodes("/*/ss:Signature", nsmgr);
          // fail if no signature was found.
          if (nodeList.Count != 1)
          {
             return false;
          }

          // Create a new SignedXml object and pass it
          // the XML document class.
          SignedXml signedXml = new SignedXml(Doc);


          // Load the first <signature> node.  
          signedXml.LoadXml((XmlElement)nodeList[0]);

          // Check the signature and return the result.
          return signedXml.CheckSignature(Key);
       }

        // Here's where we do the real work...
        public static void addNetTranslation(string fullName)
        {
			
			// Suck in translation file
            Stream txStream = new FileStream(fullName, FileMode.Open, FileAccess.Read);

             if (numLines < numLines - 1)
             {
                // TRIAL ONLY
                // Create a new XML document.
                XmlDocument xmlDoc = new XmlDocument();

                // Load an XML file into the XmlDocument object.
                xmlDoc.PreserveWhitespace = true;
                xmlDoc.Load(txStream);

                // Verify the signature of the signed XML.
                if (!VerifyXml(xmlDoc, RsaKey))
                {
		   Console.Out.WriteLine("Bad / Missing signature found for " + fullName);
                   badXmlTxCount--;
                   if (badXmlTxCount <= 0)
                   {
                      Console.Out.WriteLine("\n  This is a trial version of CS2J. It is to be used for evaluation purposes only.");
                      Console.Out.WriteLine("  The .Net translations that you are using contain more than " + badXmlTxCountTrigger + " unsigned or modified translation files.");
                      Console.Out.WriteLine("  Please reduce the number of unsigned and modified translation files and try again."); 
                      Console.Out.WriteLine("\n  Contact Twiglet Software at info@twigletsoftware.com (http://www.twigletsoftware.com) for licensing details."); 
                      Environment.Exit(1);
                   }
                }

                txStream.Seek(0, SeekOrigin.Begin);
             }
             TypeRepTemplate t = TypeRepTemplate.newInstance(txStream);
            // Fullname has form: <path>/<key>.xml
            AppEnv[t.TypeName+(t.TypeParams != null && t.TypeParams.Length > 0 ? "'" + t.TypeParams.Length.ToString() : "")] = t;
        }

        // Here's where we do the real work...
        public static void addAppSigTranslation(string fullName)
        {
                
            int saveDebugLevel = cfg.DebugLevel;
            if (!cfg.DebugTemplateExtraction)
            {
                cfg.DebugLevel = 0; 
            }
            if (cfg.DebugLevel > 3) Console.Out.WriteLine("Extracting type info from file {0}", fullName);
            ITreeNodeStream csTree = parseFile(fullName);
            if (csTree != null)
            {
 
                TemplateExtracter templateWalker = new TemplateExtracter(csTree);
                templateWalker.Filename = fullName;
                templateWalker.TraceDestination = Console.Error;

                templateWalker.Cfg = cfg;
                templateWalker.AppEnv = AppEnv;

                templateWalker.compilation_unit();
            }
            cfg.DebugLevel = saveDebugLevel;
        }
		
		private static string limit(string inp) {
			if (numLines > numLines - 1)
			    return inp;
                        // TRIAL ONLY
			String[] lines = inp.Split(newLines, numLines+1, StringSplitOptions.None);
			if (lines.Length <= numLines) {
				return inp;
			}
		    String[] res = new String[numLines+1];
			Array.Copy(lines, res, numLines);
			res[numLines] = "";
			return String.Join(Environment.NewLine, res);
		}

        // Here's where we do the real work...		
        public static void translateFile(string fullName)
        {
            long startTime = DateTime.Now.Ticks;
            if (cfg.DebugLevel > 3) Console.Out.WriteLine("Translating file {0}", fullName);
            if (cfg.DebugLevel > 5) Console.Out.WriteLine("Parsing file {0}", fullName);
            CommonTreeNodeStream csTree = parseFile(fullName);
            if (cfg.DumpCSharp && csTree != null)
            {
                AntlrUtils.DumpNodesFlat(csTree, "C Sharp Parse Tree");
                csTree.Reset();
            }

            if (csTree != null)
            {
                // Make java compilation units from C# file
                JavaMaker javaMaker = new JavaMaker(csTree);
                javaMaker.Filename = fullName;
                javaMaker.TraceDestination = Console.Error;

                javaMaker.Cfg = cfg;
                javaMaker.CUMap = new Dictionary<string, CUnit>();
                javaMaker.CUKeys = new List<string>();
                javaMaker.IsJavaish = cfg.InternalIsJavaish;
	    
                if (cfg.DebugLevel >= 1) Console.Out.WriteLine("Translating {0} to Java", fullName);
                
                javaMaker.compilation_unit();
                
                int saveEmittedCommentTokenIdx = 0;
                for (int i = 0; i < javaMaker.CUKeys.Count; i++)
                {
                    string typeName = javaMaker.CUKeys[i];
                    CommonTree typeAST = javaMaker.CUMap[typeName].Tree;

                    if (cfg.DebugLevel >= 10)
                    {
                        Console.Out.WriteLine("Namepace Search Path:");    
                        foreach (String ns in javaMaker.CUMap[typeName].SearchPath)
                        {
                            Console.Out.WriteLine(ns);    
                        }
                        Console.Out.WriteLine("Namepace Alias Map:");    
                        for (int j = 0; j < javaMaker.CUMap[typeName].NameSpaceAliasKeys.Count; j++)
                        {
                            Console.Out.WriteLine("{0} => {1}", javaMaker.CUMap[typeName].NameSpaceAliasKeys[j], javaMaker.CUMap[typeName].NameSpaceAliasValues[j]);    
                        }
                    }

                    string claName = typeName.Substring(typeName.LastIndexOf('.')+1); 
                    string nsDir = typeName.Substring(0,typeName.LastIndexOf('.')).Replace('.', Path.DirectorySeparatorChar);
                    
                    if (cfg.CheatDir != "")
                    {
                        String ignoreMarker = Path.Combine(cfg.CheatDir, Path.Combine(nsDir, claName + ".none"));
                        if (File.Exists(ignoreMarker))
                        {
                            // Don't generate this class
                            continue;
                        }
                    }
                    // Make sure parent directory exists
                    String javaFDir = Path.Combine(cfg.OutDir, nsDir);
                    String javaFName = Path.Combine(javaFDir, claName + ".java");
                    if (!Directory.Exists(javaFDir))
                    {
                        Directory.CreateDirectory(javaFDir);
                    }
                    if (cfg.CheatDir != "")
                    {
                        String cheatFile = Path.Combine(cfg.CheatDir, Path.Combine(nsDir, claName + ".java"));
                        if (File.Exists(cheatFile))
                        {
                            // the old switcheroo
                            File.Copy(cheatFile, javaFName,true);
                            continue;
                        }
                    }

                    // Translate calls to .Net to calls to Java libraries
                    CommonTreeNodeStream javaSyntaxNodes = new CommonTreeNodeStream(typeAST);            
                    if (cfg.DumpJavaSyntax && javaSyntaxNodes != null)
                    {
                        AntlrUtils.DumpNodesFlat(javaSyntaxNodes, "Java Syntax Parse Tree for " + claName);
                        javaSyntaxNodes.Reset();    
                    }
                    javaSyntaxNodes.TokenStream = csTree.TokenStream;
                    
                    NetMaker netMaker = new NetMaker(javaSyntaxNodes);
                    netMaker.Filename = fullName;
                    netMaker.TraceDestination = Console.Error;

                    netMaker.Cfg = cfg;
                    netMaker.AppEnv = AppEnv;

                    netMaker.SearchPath = javaMaker.CUMap[typeName].SearchPath;
                    netMaker.AliasKeys = javaMaker.CUMap[typeName].NameSpaceAliasKeys;
                    netMaker.AliasNamespaces = javaMaker.CUMap[typeName].NameSpaceAliasValues;

                    netMaker.IsJavaish = cfg.InternalIsJavaish;
                    netMaker.Imports = new Set<String>();
                    netMaker.AddToImports(javaMaker.Imports);

                    if (cfg.DebugLevel > 5) Console.Out.WriteLine("Translating {0} Net Calls to Java", javaFName);
                    NetMaker.compilation_unit_return javaCompilationUnit = netMaker.compilation_unit();

                    CommonTreeNodeStream javaCompilationUnitNodes = new CommonTreeNodeStream(javaCompilationUnit.Tree);            
                    javaCompilationUnitNodes.TokenStream = csTree.TokenStream;
                    
                    if (cfg.DumpJava && javaCompilationUnitNodes != null)
                    {
                        AntlrUtils.DumpNodesFlat(javaCompilationUnitNodes, "Final Java Parse Tree for " + claName);
                        javaCompilationUnitNodes.Reset();    
                    }
                    // Pretty print java parse tree as text
                    JavaPrettyPrint outputMaker = new JavaPrettyPrint(javaCompilationUnitNodes);
                    outputMaker.Filename = fullName;
                    outputMaker.TraceDestination = Console.Error;
                    outputMaker.TemplateLib = templates;

                    outputMaker.Cfg = cfg;
                    outputMaker.EmittedCommentTokenIdx = saveEmittedCommentTokenIdx;
                    outputMaker.IsLast = i == (javaMaker.CUKeys.Count - 1);
                    
                    if (cfg.DebugLevel >= 1) Console.Out.WriteLine("Writing out {0}", javaFName);
                    StreamWriter javaW = new StreamWriter(javaFName);
                    javaW.Write(limit(outputMaker.compilation_unit().ToString()));
                    javaW.Close();
                    saveEmittedCommentTokenIdx = outputMaker.EmittedCommentTokenIdx;
                }
            }

            double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
            System.Console.Out.WriteLine("Processed {0} in: {1} seconds.", fullName, elapsedTime);
            System.Console.Out.WriteLine("");
            System.Console.Out.WriteLine("");
        }
    }
}
