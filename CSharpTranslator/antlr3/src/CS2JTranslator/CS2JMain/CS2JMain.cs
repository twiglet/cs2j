/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
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
using Nini.Config;

namespace Twiglet.CS2J.Translator
{
    class CS2J
    {
       private const string VERSION = "2011.3.1";
       private static DirectoryHT<TypeRepTemplate> AppEnv { get; set; }
       private static CS2JSettings cfg = new CS2JSettings();
       private static StringTemplateGroup templates = null;
       private static bool doEarlyExit = false;

       private static RSACryptoServiceProvider RsaKey = null;
       private static int badXmlTxCountTrigger = 3 + 4 - 2;
       private static int badXmlTxCount = badXmlTxCountTrigger;
		
       private static String[] newLines = new String[] { "\n", Environment.NewLine };
       private static int numLines = (10 * 10) + 50 - 30;
		
       public delegate void FileProcessor(string fName);

       private static Dictionary<string, ClassDescriptorSerialized> partialTypes = new Dictionary<string, ClassDescriptorSerialized>();

        private static void showVersion()
        {
            Console.Out.WriteLine(Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]) + ": " + VERSION);
        }

        private static void showUsage()
        {
            Console.Out.WriteLine("Usage: " + Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]));
            Console.Out.WriteLine(" [-help]                                                                     (this usage message)");
            Console.Out.WriteLine(" [-v]                                                                        (be [somewhat more] verbose, repeat for more verbosity)");
            Console.Out.WriteLine(" [-config <iniFile>]                                                        (read settings from <iniFile>, overriden from command line");
            Console.Out.WriteLine(" [-D <macroVariable>]                                                        (define C# preprocessor <macroVariable>, option can be repeated)");
            Console.Out.WriteLine(" [-show-tokens]                                                              (the lexer prints the tokenized input to the console)");
            Console.Out.WriteLine(" [-show-csharp] [-show-javasyntax] [-show-java]                              (show parse tree at various stages of the translation)");
            Console.Out.WriteLine(" [-dump-xmls] [-out-xml-dir <directory to dump xml database>]                 (dump the translation repository as xml files)");
            Console.Out.WriteLine(" [-net-templates-dir <root of Library translation templates>+]               (can be multiple directories, separated by semi-colons)");
            Console.Out.WriteLine(" [-ex-net-templates-dir <directories/files to be excluded>+]                 (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-alt-translations <template variants>+]                                    (enable these translaton template variants, can be repeated)");
            Console.Out.WriteLine(" [-app-dir <root of C# application>]                                         (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-ex-app-dir <directories/files to be excluded>+]                           (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-cs-dir <directories/files to be translated>+]                             (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-ex-cs-dir <directories/files to be excluded from translation>+]           (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [-out-java-dir <root of translated classes>]                                (write Java classes here)");
            Console.Out.WriteLine(" [-debug <level>]                                                            (set debug level, default 0)");
            Console.Out.WriteLine(" [-debug-template-extraction <true/false>]                                   (show debug messages during template extraction, default true)");
            Console.Out.WriteLine(" [-warnings <true/false>]                                                    (show warnings, default true)");
            Console.Out.WriteLine(" [-warning-resolve-failures <true/false>]                                    (show warnings for resolve failures, default true)");
            Console.Out.WriteLine(" [-keep-parens <true/false>]                                                 (keep parens from source, default true)");
            Console.Out.WriteLine(" [-make-javadoc-comments <true/false>]                                       (convert C# documentation comments to Javadoc, default true)");
            Console.Out.WriteLine(" [-make-java-naming-conventions <true/false>]                                (convert method names to follow Java conventions, default true)");
            Console.Out.WriteLine(" <directory or file name to be translated>                                   (as cs-dir option)");
        }

        private static IList<string> mkDirectories(string rawStr)
        {
            IList<string> strs = new List<string>();
            if (!String.IsNullOrEmpty(rawStr))
            {
               char splitChar = rawStr.IndexOf(';') >= 0 ? ';' : '|';
               string[] argDirs = rawStr.Split(splitChar);
               for (int i = 0; i < argDirs.Length; i++)
               {
                  string dir = Path.GetFullPath(argDirs[i]).TrimEnd(Path.DirectorySeparatorChar);
                  strs.Add(dir);
               }
            }
            return strs;
        }

        private static IList<string> mkStrings(string rawStr)
        {
            IList<string> strs = new List<string>();
            if (!String.IsNullOrEmpty(rawStr))
            {
               char splitChar = rawStr.IndexOf(';') >= 0 ? ';' : '|';
               string[] strDirs = rawStr.Split(splitChar);
               for (int i = 0; i < strDirs.Length; i++)
                  strs.Add(strDirs[i]);
            }
            return strs;
        }

        private static bool parseBoolOption(String opt)
        {
           bool ret = true;
           // counter intuitive, but captures plain -opt as opt is true
           if (!String.IsNullOrEmpty(opt))
           {
              try
              {
                 ret = Convert.ToBoolean(opt); 
              }
              catch
              {
                 // Not true/false. try as int
                 try
                 {
                    ret = Convert.ToBoolean(Int32.Parse(opt));
                 }
                 catch
                 {
                    // ok give in
                 }
              }
           }
           return ret;
        }
		
        private static void updateFromConfigFile(string inifile, CS2JSettings cfg)
        {
            try
            {
                IConfigSource source = new IniConfigSource(Path.GetFullPath(inifile));
                IConfig general = source.Configs["General"];
                
                // Debug / Verbosity
                cfg.OptVerbosity.SetIfDefault(general.GetInt("verbose", cfg.Verbosity));
                cfg.OptDebugLevel.SetIfDefault(general.GetInt("debug", cfg.DebugLevel));
                cfg.OptDebugTemplateExtraction.SetIfDefault(general.GetBoolean("debug-template-extraction", cfg.DebugTemplateExtraction));

                // Control warnings
                cfg.OptWarnings.SetIfDefault(general.GetBoolean("warnings", cfg.Warnings));
                cfg.OptWarningsFailedResolves.SetIfDefault(general.GetBoolean("warnings-resolve-failures", cfg.WarningsFailedResolves));

                // Dump internal structures
                cfg.OptDumpCSharp.SetIfDefault(general.GetBoolean("show-csharp", cfg.DumpCSharp));
                cfg.OptDumpJavaSyntax.SetIfDefault(general.GetBoolean("show-javasyntax", cfg.DumpJavaSyntax));
                cfg.OptDumpJava.SetIfDefault(general.GetBoolean("show-java", cfg.DumpJava));
                cfg.OptDisplayTokens.SetIfDefault(general.GetBoolean("show-tokens", cfg.DisplayTokens));

                // Preprocessor tokens
                cfg.OptMacroDefines.SetIfDefault(mkStrings(general.Get("define", "")));

                // Output enum list, parsed translation files
                cfg.OptDumpEnums.SetIfDefault(general.GetBoolean("dump-enums", cfg.DumpEnums));
                cfg.OptEnumDir.SetIfDefault(Path.Combine(Directory.GetCurrentDirectory(), general.Get("out-enum-dir", cfg.EnumDir)));

                cfg.OptDumpXmls.SetIfDefault(general.GetBoolean("dump-xmls", cfg.DumpXmls));
                cfg.OptXmlDir.SetIfDefault(Path.Combine(Directory.GetCurrentDirectory(), general.Get("out-xml-dir", cfg.XmlDir)));

                // Source and output for translation files and templates
                cfg.OptCheatDir.SetIfDefault(Path.Combine(Directory.GetCurrentDirectory(), general.Get("cheat-dir", cfg.CheatDir)));

                cfg.OptNetRoot.SetIfDefault(mkDirectories(general.Get("net-templates-dir", "")));
                cfg.OptExNetRoot.SetIfDefault(mkDirectories(general.Get("ex-net-templates-dir", "")));
                cfg.OptNetSchemaDir.SetIfDefault(mkDirectories(general.Get("net-schema-dir", "")));

                cfg.OptAppRoot.SetIfDefault(mkDirectories(general.Get("app-dir", "")));
                cfg.OptExAppRoot.SetIfDefault(mkDirectories(general.Get("ex-app-dir", "")));

                cfg.OptCsDir.SetIfDefault(mkDirectories(general.Get("cs-dir", "")));
                cfg.OptExCsDir.SetIfDefault(mkDirectories(general.Get("ex-cs-dir", "")));

                cfg.OptOutDir.SetIfDefault(Path.Combine(Directory.GetCurrentDirectory(), general.Get("out-java-dir", cfg.OutDir)));

                // Enable Alternate Translation Templates
                cfg.OptAltTranslations.SetIfDefault(mkStrings(general.Get("alt-translations", "")));

                // Boolean flags
                cfg.OptTranslatorKeepParens.SetIfDefault(general.GetBoolean("keep-parens", cfg.TranslatorKeepParens));
                cfg.OptTranslatorAddTimeStamp.SetIfDefault(general.GetBoolean("timestamp-files", cfg.TranslatorAddTimeStamp));
                cfg.OptTranslatorBlanketThrow.SetIfDefault(general.GetBoolean("blanket-throw", cfg.TranslatorBlanketThrow));
                cfg.OptTranslatorExceptionIsThrowable.SetIfDefault(general.GetBoolean("exception-is-throwable", cfg.TranslatorExceptionIsThrowable));
                cfg.OptTranslatorMakeJavadocComments.SetIfDefault(general.GetBoolean("make-javadoc-comments", cfg.TranslatorMakeJavadocComments));
                cfg.OptTranslatorMakeJavaNamingConventions.SetIfDefault(general.GetBoolean("make-java-naming-conventions", cfg.TranslatorMakeJavaNamingConventions));

                IConfig experimental = source.Configs["Experimental"];

                cfg.OptEnumsAsNumericConsts.SetIfDefault(experimental.GetBoolean("enums-to-numeric-consts", cfg.EnumsAsNumericConsts));
                cfg.OptUnsignedNumbersToSigned.SetIfDefault(experimental.GetBoolean("unsigned-to-signed", cfg.UnsignedNumbersToSigned));
                cfg.OptUnsignedNumbersToBiggerSignedNumbers.SetIfDefault(experimental.GetBoolean("unsigned-to-bigger-signed", cfg.UnsignedNumbersToBiggerSignedNumbers));
                cfg.OptExperimentalTransforms.SetIfDefault(experimental.GetBoolean("transforms", cfg.ExperimentalTransforms));

                IConfig internl = source.Configs["Internal"];

                cfg.OptInternalIsJavaish.SetIfDefault(internl.GetBoolean("isjavaish", cfg.InternalIsJavaish));
            }
            catch (IOException)
            {
                Console.WriteLine("ERROR: Could not read configuration file " + Path.GetFullPath(inifile));
                doEarlyExit = true;
            }
        }

        public static void CS2JMain(string[] args)
        {
            long startTime = DateTime.Now.Ticks;
            XmlTextWriter enumXmlWriter = null;			
            bool doHelp = false;

            // Use a try/catch block for parser exceptions
            try
            {
                // if we have at least one command-line argument
                if (args.Length > 0)
                {
			
                    if (cfg.Verbosity >= 2) Console.Error.WriteLine("Parsing Command Line Arguments...");

                    OptionSet p = new OptionSet ()
                        .Add ("config=", f => updateFromConfigFile(f, cfg))
                        .Add ("v", v => cfg.Verbosity = cfg.OptVerbosity.IsDefault ? 1 : cfg.Verbosity + 1)
                        .Add ("debug=", v => cfg.DebugLevel = Int32.Parse(v))
                        .Add ("debug-template-extraction:", v => cfg.DebugTemplateExtraction = parseBoolOption(v))
                        .Add ("warnings:", v => cfg.Warnings = parseBoolOption(v))
                        .Add ("warnings-resolve-failures:", v => cfg.WarningsFailedResolves = parseBoolOption(v))
                        .Add ("version:", v => { if (parseBoolOption(v)) showVersion(); })
                        .Add ("help|h|?", v => {doHelp = true; doEarlyExit = true; })
                        .Add ("show-csharp:", v => cfg.DumpCSharp = parseBoolOption(v))
                        .Add ("show-java:", v => cfg.DumpJava = parseBoolOption(v))
                        .Add ("show-javasyntax:", v => cfg.DumpJavaSyntax = parseBoolOption(v))
                        .Add ("show-tokens:", v => cfg.DisplayTokens = parseBoolOption(v))
                        .Add ("D=", def => cfg.OptMacroDefines.Add(mkStrings(def))) 							
                        .Add ("dump-enums:", v => cfg.DumpEnums = parseBoolOption(v))
                        .Add ("out-enum-dir=", dir => cfg.EnumDir = Path.Combine(Directory.GetCurrentDirectory(), dir))							
                        .Add ("dump-xmls:", v => cfg.DumpXmls = parseBoolOption(v))
                        .Add ("out-xml-dir=", dir => cfg.XmlDir = Path.Combine(Directory.GetCurrentDirectory(), dir))
                        .Add ("out-java-dir=", dir => cfg.OutDir = dir)
                        .Add ("cheat-dir=", dir => cfg.CheatDir = dir)
                        .Add ("net-templates-dir=", dirs => cfg.OptNetRoot.Add(mkDirectories(dirs)))
                        .Add ("ex-net-templates-dir=", dirs => cfg.OptExNetRoot.Add(mkDirectories(dirs)))
                        .Add ("net-schema-dir=", dirs => cfg.OptNetSchemaDir.Add(mkDirectories(dirs)))
                        .Add ("app-dir=", dirs => cfg.OptAppRoot.Add(mkDirectories(dirs)))
                        .Add ("ex-app-dir=", dirs => cfg.OptExAppRoot.Add(mkDirectories(dirs)))
                        .Add ("cs-dir=", dirs => cfg.OptCsDir.Add(mkDirectories(dirs)))
                        .Add ("ex-cs-dir=", dirs => cfg.OptExCsDir.Add(mkDirectories(dirs)))
                        .Add ("alt-translations=", alts => cfg.OptAltTranslations.Add(mkStrings(alts)))
                        .Add ("keep-parens:", v => cfg.TranslatorKeepParens = parseBoolOption(v))
                        .Add ("timestamp-files:", v => cfg.TranslatorAddTimeStamp = parseBoolOption(v))
                        .Add ("blanket-throw:", v => cfg.TranslatorBlanketThrow = parseBoolOption(v))
                        .Add ("exception-is-throwable:", v => cfg.TranslatorExceptionIsThrowable = parseBoolOption(v))
                        .Add ("make-javadoc-comments:", v => cfg.TranslatorMakeJavadocComments = parseBoolOption(v))
                        .Add ("make-java-naming-conventions:", v => cfg.TranslatorMakeJavaNamingConventions = parseBoolOption(v))
                        .Add ("experimental-enums-to-numeric-consts:", v => cfg.EnumsAsNumericConsts = parseBoolOption(v))
                        .Add ("experimental-unsigned-to-signed:", v => cfg.UnsignedNumbersToSigned = parseBoolOption(v))
                        .Add ("experimental-unsigned-to-bigger-signed:", v => cfg.UnsignedNumbersToBiggerSignedNumbers = parseBoolOption(v))
                        .Add ("experimental-transforms:", v => cfg.ExperimentalTransforms = parseBoolOption(v))
                        .Add ("internal-isjavaish:", v => cfg.InternalIsJavaish = parseBoolOption(v))
                        ;
					
                    //TODO: fix enum dump
                    // Final argument is translation target
                    foreach (string s in p.Parse (args))
                    {
                       if (s.StartsWith("-") || s.StartsWith("/"))
                       {
                          Console.WriteLine("ERROR: Unrecognized Option: " + s);
                          doEarlyExit = true;
                       }
                       else
                       {
                          cfg.OptCsDir.Add(mkDirectories(s));
                       }
                    }

                    if (cfg.Verbosity > 0) showVersion();

                    if (doHelp) showUsage();
                    if (!doEarlyExit && (cfg.CsDir == null || cfg.CsDir.Count == 0)) {
                        // No work
                       Console.WriteLine("Please specify files to translate with -cs-dir option");
                       doEarlyExit = true;
                    }

                    if (doEarlyExit)
                    {
                        Environment.Exit(0);
                    }

                    AppEnv = new DirectoryHT<TypeRepTemplate>();
                    if (cfg.TranslatorMakeJavaNamingConventions)
                    {
                       // Search lowerCamelCase
                       AppEnv.Alts.Add("LCC");                       
                    }
                    foreach (string alt in cfg.AltTranslations)
                    {
                       AppEnv.Alts.Add(alt);                       
                    }

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
                    // Do we have schemas for the templates?
                    if (cfg.NetSchemaDir.Count == 0)
                    {
                       // By default look for schemas in net dirs
                       cfg.NetSchemaDir = new List<string>(cfg.NetRoot);
                    }

                    // Comment out for now.  I don't see how to wrie an xsd file that will allow elements to appear in any order
                    // foreach (string schemadir in cfg.NetSchemaDir)
                    //   doFile(schemadir, ".xsd", addNetSchema, null);

                    foreach (string r in cfg.NetRoot)
                        doFile(r, ".xml", addNetTranslation, cfg.ExNetRoot);

                    // Load Application Class Signatures (i.e. generate templates)
                    if (cfg.AppRoot.Count == 0)
                    {
                        // By default translation target is application root
                       foreach (string s in cfg.CsDir)
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

                    foreach (string r in cfg.CsDir)
                        doFile(r, ".cs", translateFile, cfg.ExCsDir); // translate it

                    if (cfg.DebugLevel >= 1 && partialTypes.Count > 0) Console.Out.WriteLine("Writing out collected partial types");
                    foreach (KeyValuePair<string, ClassDescriptorSerialized> entry in partialTypes)
                       emitPartialType(entry.Key, entry.Value);

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
            if (excludes == null || !excludes.Contains(canonicalPath.TrimEnd(Path.DirectorySeparatorChar)))
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
        public static void addNetSchema(string fullName)
        {
           try
           {
              TypeRepTemplate.TemplateReaderSettings.Schemas.Add("urn:www.twigletsoftware.com:schemas:txtemplate:1:0", fullName);
           }
           catch (Exception e)
           {
              Console.Error.WriteLine("{0} error: {1}", fullName, e.Message);
           }
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
                   Console.Out.WriteLine("WARNING: Bad / Missing signature found for " + fullName);
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
            try {
                TypeRepTemplate t = TypeRepTemplate.newInstance(txStream);
                // Fullname has form: <path>/<key>.xml
                string txKey = t.TypeName+(t.TypeParams != null && t.TypeParams.Length > 0 ? "'" + t.TypeParams.Length.ToString() : "");
                if (!String.IsNullOrEmpty(t.Variant))
                {
                   AppEnv.Add(txKey, t, t.Variant);
                }
                else
                {
                   AppEnv.Add(txKey, t);
                }
            } catch (Exception e) {
                Console.WriteLine ("WARNING -- Could not import " + fullName + " (" + e.Message + ")");
            }
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
          lines[numLines] = Regex.Replace(lines[numLines], "\\w", "x");
          return String.Join(Environment.NewLine, lines);
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

                    string claName = typeName.Substring(typeName.LastIndexOf('.')+1); 
                    string nsDir = typeName.LastIndexOf('.') >= 0 ? typeName.Substring(0,typeName.LastIndexOf('.')).Replace('.', Path.DirectorySeparatorChar) : "";
                    
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
                    bool isPartial = javaMaker.CUMap[typeName].IsPartial;
                    if (isPartial)
                    {
                       if (!partialTypes.ContainsKey(typeName))
                       {
                          partialTypes[typeName] = new ClassDescriptorSerialized(claName);
                          partialTypes[typeName].FileName = javaFName;
                       }
                       outputMaker.PartialDescriptor = partialTypes[typeName];
                    }

                    outputMaker.IsLast = i == (javaMaker.CUKeys.Count - 1);
                    
                    if (!isPartial)
                    {
                       if (cfg.DebugLevel >= 1) Console.Out.WriteLine("Writing out {0}", javaFName);
                       StreamWriter javaW = new StreamWriter(javaFName);
                       javaW.Write(limit(outputMaker.compilation_unit().ToString()));
                       javaW.Close();
                    }
                    else
                    {
                       // fill out partialTypes[typeName]
                       outputMaker.compilation_unit();
                    }
                    saveEmittedCommentTokenIdx = outputMaker.EmittedCommentTokenIdx;
                }
            }

            double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
            System.Console.Out.WriteLine("Processed {0} in: {1} seconds.", fullName, elapsedTime);
            System.Console.Out.WriteLine("");
            System.Console.Out.WriteLine("");
        }

       public static void emitPartialType(string name, ClassDescriptorSerialized serTy)
       {
          JavaPrettyPrint outputMaker = new JavaPrettyPrint(null);
          outputMaker.Filename = serTy.FileName;
          outputMaker.TraceDestination = Console.Error;
          outputMaker.TemplateLib = templates;
          outputMaker.Cfg = cfg;

          StringTemplate pkgST = outputMaker.emitPackage(serTy);

          if (cfg.DebugLevel >= 1) Console.Out.WriteLine("Writing out {0}", serTy.FileName);
          StreamWriter javaW = new StreamWriter(serTy.FileName);
          javaW.Write(limit(pkgST.ToString()));
          javaW.Close();
       }
    }
}
