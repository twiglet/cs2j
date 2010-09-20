/*
[The "BSD licence"]
Copyright (c) 2002-2005 Kunle Odutola
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


// bug(?) in DotGNU 0.6 - "using antlr" will workaround the problem.
#if __CSCC__
using antlr;
#endif

namespace RusticiSoftware.Translator
{
	using System;
    using System.Collections;
    using System.Xml;
    using System.Xml.Serialization;

	using FileInfo						= System.IO.FileInfo;
	using Directory						= System.IO.Directory;
	using FileStream					= System.IO.FileStream;
	using FileMode						= System.IO.FileMode;
	using FileAccess					= System.IO.FileAccess;
	using Stream						= System.IO.Stream;
	using StreamReader					= System.IO.StreamReader;
    using StringWriter                  = System.IO.StringWriter;
    using StreamWriter                  = System.IO.StreamWriter;
    using Path                          = System.IO.Path;
    using DirectoryInfo                 = System.IO.DirectoryInfo;
    using TextWriter                    = System.IO.TextWriter;
    using File                          = System.IO.File;
    using XmlTextWriter                 = System.Xml.XmlTextWriter;

	using BaseAST						= antlr.BaseAST;
	using CommonAST						= antlr.CommonAST;
	using ASTFactory					= antlr.ASTFactory;
	using RecognitionException			= antlr.RecognitionException;
	using AST							= antlr.collections.AST;
	using ASTFrame						= antlr.debug.misc.ASTFrame;
	using IToken						= antlr.IToken;
	using TokenStream					= antlr.TokenStream;
	using TokenStreamSelector			= antlr.TokenStreamSelector;
	using TokenStreamHiddenTokenFilter	= antlr.TokenStreamHiddenTokenFilter;

    using IEnumerator = System.Collections.IEnumerator;
    using System.Reflection;
	
	class AppMain
	{
        private const string VERSION = "2008.1.0.6617";

        public delegate void FileProcessor(string fName, Stream s);

        internal static bool showTree = false;
        internal static bool showCSharp = false;
        internal static bool showJavaSyntax = false;
        internal static bool showJava = false;
        // keving:  We don't use the flex scanner (at least for now) and we don't pretty print CSharp
//		internal static bool printTree = false;
//		internal static bool useFlexLexer = false;
		internal static bool displayTokens = false;
        internal static bool dumpXMLs = false;
        internal static string outDir = ".";
        internal static string cheatDir = "";
        internal static ArrayList netRoot = new ArrayList();
        internal static ArrayList exNetRoot = new ArrayList();
        internal static ArrayList appRoot = new ArrayList();
        internal static ArrayList exAppRoot = new ArrayList();
        internal static ArrayList exclude = new ArrayList();
        internal static DirectoryHT appEnv = new DirectoryHT(null);
        internal static XmlTextWriter enumXmlWriter;
        internal static string xmldumpDir = Path.Combine(".", "tmpXMLs");
        internal static Boolean emitTranslationDate = true;
        
        internal static int verbosity = 0;


        internal static TokenStreamHiddenTokenFilter filter;


        internal static int numFilesSuccessfullyProcessed = 0;
        internal static int numFilesProcessed = 0;

        private static void showVersion()
        {
            Console.Out.WriteLine(Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]) + ": " + VERSION);
        }

        private static void showUsage()
        {
            Console.Out.WriteLine("Usage: " + Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]));
            Console.Out.WriteLine(" [-help]                                                                     (this usage message)");
            Console.Out.WriteLine(" [-v]                                                                        (be [somewhat more] verbose, repeat for more verbosity)");
            Console.Out.WriteLine(" [-markDate <true|false>]                                                    (emit date of Translation into Java Source, default:true)");
            Console.Out.WriteLine(" [-showtokens]                                                               (the lexer prints the tokenized input to the console)");
            Console.Out.WriteLine(" [-showtree][-showcsharp] [-showjavasyntax] [-showjava]                      (show parse tree at various stages of the translation)");
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

        public static void Main(string[] args)
		{
			long startTime = DateTime.Now.Ticks;
			// Use a try/catch block for parser exceptions
			try
			{
				// if we have at least one command-line argument
				if (args.Length > 0)
				{
					if (verbosity >= 2) Console.Error.WriteLine("Parsing...");				
					// for each directory/file specified on the command line
					for (int i = 0; i < args.Length; i++)
					{
                        if (args[i].ToLower().Equals("-showtree"))
                        {
                            showTree = true;
                        }
                        else if (args[i].ToLower().Equals("-showcsharp"))
                        {
                            showCSharp = true;
                        }
                        else if (args[i].ToLower().Equals("-showjava"))
                        {
                            showJava = true;
                        }
                        else if (args[i].ToLower().Equals("-showjavasyntax"))
                        {
                            showJavaSyntax = true;
                        }
                        else if (args[i].ToLower().Equals("-tokens"))
                        {
                            displayTokens = true;
                        }
                        else if (args[i].ToLower().Equals("-dumpxml"))
                        {
                            dumpXMLs = true;
                        }
                        else if (args[i].ToLower().Equals("-v"))
                        {
                            verbosity++;

                            // in verbose mode, echo back the command line (so if command line is generated by another tool that does not
                            // echo it, it can still be seen in the logs.
                            Console.Write(Assembly.GetExecutingAssembly().Location + " ");
                            foreach (string arg in args)
                            {
                                Console.Write(arg + " ");
                            }
                            Console.WriteLine(System.Environment.NewLine);

                        }
                        else if (args[i].ToLower().Equals("-help"))
                        {
                            showUsage();
                        }
                        else if (args[i].ToLower().Equals("-version"))
                        {
                            showVersion();
                        }
                        else if (args[i].ToLower().Equals("-odir") && i < (args.Length - 1))
                        {
                            i++;
                            outDir = args[i];
                        }
                        else if (args[i].ToLower().Equals("-markdate") && i < (args.Length - 1))
                        {
                            i++;
                            emitTranslationDate = !(args[i].ToLower().Equals("false"));
                        }
                        else if (args[i].ToLower().Equals("-dumpenums") && i < (args.Length - 1))
                        {
                            i++;
                            enumXmlWriter = new XmlTextWriter(args[i], System.Text.Encoding.UTF8);
                            enumXmlWriter.WriteStartElement("enums");
                        }
                        else if (args[i].ToLower().Equals("-cheatdir") && i < (args.Length - 1))
                        {
                            i++;
                            cheatDir = args[i];
                        }
                        else if (args[i].ToLower().Equals("-netdir") && i < (args.Length - 1))
                        {
                            i++;
                            string[] argDirs = args[i].Split(';');
                            for (int j = 0; j < argDirs.Length; j++)
                                argDirs[j] = Path.GetFullPath(argDirs[j]).ToLower();
                            netRoot.AddRange(argDirs);
                        }
                        else if (args[i].ToLower().Equals("-exnetdir") && i < (args.Length - 1))
                        {
                            i++;
                            string[] argDirs = args[i].Split(';');
                            for (int j = 0; j < argDirs.Length; j++)
                                argDirs[j] = Path.GetFullPath(argDirs[j]).ToLower();
                            exNetRoot.AddRange(argDirs);
                        }
                        else if (args[i].ToLower().Equals("-appdir") && i < (args.Length - 1))
                        {
                            i++;
                            string[] argDirs = args[i].Split(';');
                            for (int j = 0; j < argDirs.Length; j++)
                                argDirs[j] = Path.GetFullPath(argDirs[j]).ToLower();
                            appRoot.AddRange(argDirs);
                        }
                        else if (args[i].ToLower().Equals("-exappdir") && i < (args.Length - 1))
                        {
                            i++;
                            string[] argDirs = args[i].Split(';');
                            for (int j = 0; j < argDirs.Length; j++)
                                argDirs[j] = Path.GetFullPath(argDirs[j]).ToLower();
                            exAppRoot.AddRange(argDirs);
                        }
                        else if (args[i].ToLower().Equals("-exclude") && i < (args.Length - 1))
                        {
                            i++;
                            string[] argDirs = args[i].Split(';');
                            for (int j = 0; j < argDirs.Length; j++)
                                argDirs[j] = Path.GetFullPath(argDirs[j]).ToLower();
                            exclude.AddRange(argDirs);
                        }
                        else if (args[i].ToLower().Equals("-xmldir") && i < (args.Length - 1))
                        {
                            i++;
                            xmldumpDir = args[i];
                        }
                        else
						{
                            // Final argument is translation target

                            // Load .Net templates
                            numFilesSuccessfullyProcessed = 0;
                            numFilesProcessed = 0;

                            foreach (string r in netRoot)
                                doFile(new FileInfo(r), ".xml", addNetTranslation, exNetRoot);

                            Console.Out.WriteLine(String.Format("\nFound {0} .Net template files ({1} processed successfully)\n", numFilesProcessed, numFilesSuccessfullyProcessed)); 

                            // Load Application Class Signatures (i.e. generate templates)
                            if (appRoot.Count == 0)
                                // By default translation target is application root
                                appRoot.Add(args[i]);

                            numFilesSuccessfullyProcessed = 0;
                            numFilesProcessed = 0;

                            foreach (string r in appRoot)
                               doFile(new FileInfo(r), ".cs", addAppSigTranslation, exAppRoot); // parse it

                            Console.Out.WriteLine(String.Format("\nFound {0} cs files in the application ({1} processed successfully)\n", numFilesProcessed, numFilesSuccessfullyProcessed)); 

                            if (dumpXMLs)
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
                            numFilesSuccessfullyProcessed = 0;
                            numFilesProcessed = 0;

                            doFile(new FileInfo(args[i]), ".cs", translateFile, exclude); // parse it

                            if (numFilesProcessed == 0) {
                                Console.Out.WriteLine("\nWARNING: Did not find any cs files to translate\n");
                            }
                            else {
                                Console.Out.WriteLine(String.Format("\nTranslated {0} cs files ({1} processed somewhat successfully)\n", numFilesProcessed, numFilesSuccessfullyProcessed)); 
                            }
                            if (enumXmlWriter != null)
                            {
                                enumXmlWriter.WriteEndElement();
                                enumXmlWriter.Close();
                            }
						}
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
		public static void  doFile(FileInfo f, string ext, FileProcessor processFile, ArrayList excludes)
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
                        fs = new FileStream(f.FullName, FileMode.Open, FileAccess.Read);
                        processFile(f.FullName, fs);
                        numFilesSuccessfullyProcessed++;
                    }
                    catch (Exception e) 
                    {
                        Console.Error.WriteLine("\nCannot process file: " + f.FullName);
                        Console.Error.WriteLine("exception: " + e);
                    }
                    finally
                    {
                        if (fs != null) fs.Close();
                        numFilesProcessed++;
                    }
                }
            }
		}

        public static ASTNode parseFile(string f, Stream s)
        {
            ASTNode ret = null;
            try
            {
                // Define a selector that can switch from the C# codelexer to the C# preprocessor lexer
                TokenStreamSelector selector = new TokenStreamSelector();

                TokenStream lexer;
                CSharpLexer antlrLexer = new CSharpLexer(new StreamReader(s));

                antlrLexer.Selector = selector;
                antlrLexer.setFilename(f);
                CSharpPreprocessorLexer preproLexer = new CSharpPreprocessorLexer(antlrLexer.getInputState());
                preproLexer.Selector = selector;
                CSharpPreprocessorHooverLexer hooverLexer = new CSharpPreprocessorHooverLexer(antlrLexer.getInputState());
                hooverLexer.Selector = selector;

                // use the special token object class
                antlrLexer.setTokenCreator(new CustomHiddenStreamToken.CustomHiddenStreamTokenCreator());
                antlrLexer.setTabSize(1);
                preproLexer.setTokenCreator(new CustomHiddenStreamToken.CustomHiddenStreamTokenCreator());
                preproLexer.setTabSize(1);
                hooverLexer.setTokenCreator(new CustomHiddenStreamToken.CustomHiddenStreamTokenCreator());
                hooverLexer.setTabSize(1);

                // notify selector about various lexers; name them for convenient reference later
                selector.addInputStream(antlrLexer, "codeLexer");
                selector.addInputStream(preproLexer, "directivesLexer");
                selector.addInputStream(hooverLexer, "hooverLexer");
                selector.select("codeLexer"); // start with main the CSharp code lexer
                lexer = selector;

                // create the stream filter; hide WS and SL_COMMENT
                if (displayTokens)
                    filter = new TokenStreamHiddenTokenFilter(new LoggingTokenStream(lexer));
                else
                    filter = new TokenStreamHiddenTokenFilter(lexer);

                filter.hide(CSharpJavaTokenTypes.WHITESPACE);
                filter.hide(CSharpJavaTokenTypes.NEWLINE);
                filter.hide(CSharpJavaTokenTypes.ML_COMMENT);
                filter.hide(CSharpJavaTokenTypes.SL_COMMENT);

                // Create a parser that reads from the scanner
                CSharpParser parser = new CSharpParser(filter);

                // create trees that copy hidden tokens into tree also
                parser.setASTNodeClass(typeof(ASTNode).FullName);
                parser.setASTFactory(new ASTNodeFactory());
                CSharpParser.initializeASTFactory(parser.getASTFactory());
                parser.setFilename(f);
                //parser.getASTFactory().setASTNodeCreator(new ASTNode.ASTNodeCreator());

                // start parsing at the compilationUnit rule
                long startTime = DateTime.Now.Ticks;
                parser.compilationUnit();
                double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
                if (verbosity >= 2) System.Console.Out.WriteLine("Parsed {0} in: {1} seconds.", f, elapsedTime);

                BaseAST.setVerboseStringConversion(true, parser.getTokenNames());
                ret = (ASTNode)parser.getAST();
            }
            catch (System.Exception e)
            {
                Console.Error.WriteLine("parser exception: " + e);
                Console.Error.WriteLine(e.StackTrace); // so we can get stack trace		
            }
            return ret;
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
            string f = Path.GetFileName(fullName);

            ASTNode t = parseFile(f, s);
            if (t != null)
            {
                // A prescan of all files to build an environment mapping qualified name to typereptemplate
                CSharpEnvBuilder envBuilder = new CSharpEnvBuilder();
                envBuilder.compilationUnit(t, null, appEnv);
            }
        }

        // Here's where we do the real work...		
		public static void translateFile(string fullName, Stream s)
		{
            string f = Path.GetFileName(fullName);

            ASTNode t = parseFile(f, s);
            if (t != null)
            {
                if (showTree)
                {
                    ASTNode r = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
                    r.setFirstChild(t);
                    ASTFrame frame = new ASTFrame("C# AST for file [" + f + "]", r);
                    frame.ShowDialog();
                    //frame.Visible = true;
                    // System.out.println(t.toStringList());
                }
                ASTNode r1 = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
                r1.setFirstChild(t);
                ASTFrame frame1 = new ASTFrame("C# AST for file [" + f + "]", r1);
                if (showCSharp)
                    frame1.ShowDialog();

                CSharpTranslator transformer = new CSharpTranslator();
                transformer.setASTNodeClass(typeof(ASTNode).FullName);
                transformer.setASTFactory(new ASTNodeFactory());
                CSharpTranslator.initializeASTFactory(transformer.getASTFactory());

                long startTime = DateTime.Now.Ticks;
                transformer.compilationUnit(t, null);

                //BaseAST.setVerboseStringConversion(true, tokenNames);
                ASTNode r2 = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
                r2.setFirstChild(transformer.getAST());
                ASTFrame frame2 = new ASTFrame("Java syntax AST for file [" + f + "]", r2);
                if (showJavaSyntax)
                    frame2.ShowDialog();

                // Take each java compilation unit (each class defn) and write it to the appropriate file 
                IEnumerator enumCU = transformer.getAST().findAllPartial((ASTNode)transformer.getASTFactory().create(CSharpParser.COMPILATION_UNIT));
                while (enumCU.MoveNext())
                {
                    ASTNode javaCU = (ASTNode)enumCU.Current;

                    // Extract class/interface name
                    String claName = JavaTreeParser.getClassName(javaCU);
                    
                    // Get package name and convert to directory name
                    String nsDir = "";
                    foreach (String nsc in JavaTreeParser.getPackageName(javaCU))
                    {
                        nsDir = Path.Combine(nsDir, nsc);
                    }

                    // Build destination filename for this class
                    String fName = Path.Combine(Path.Combine(outDir, nsDir), claName + ".java");

                    if (cheatDir != "")
                    {
                        String cheatFile = Path.Combine(cheatDir, Path.Combine(nsDir, claName + ".java"));
                        if (File.Exists(cheatFile))
                        {
                            // the old switcheroo
                            File.Copy(cheatFile, fName,true);
                            continue;
                        }

                        String ignoreMarker = Path.Combine(cheatDir, Path.Combine(nsDir, claName + ".none"));
                        if (File.Exists(ignoreMarker))
                        {
                            // Don't generate this class
                            continue;
                        }
                    }
                    
                    NetTranslator netTx = new NetTranslator();
                    netTx.setASTNodeClass(typeof(ASTNode).FullName);
                    netTx.setASTFactory(new ASTNodeFactory());
                    NetTranslator.initializeASTFactory(netTx.getASTFactory());
                    netTx.compilationUnit(javaCU, null, appEnv);

                    //BaseAST.setVerboseStringConversion(true, tokenNames);
                    ASTNode r3 = (ASTNode)new ASTNodeFactory().create(0, "AST ROOT");
                    r3.setFirstChild(netTx.getAST());
                    ASTFrame frame3 = new ASTFrame("Java AST for file [" + f + "]", r3);
                    if (showJava)
                        frame3.ShowDialog();
                    
                    Console.WriteLine(fName);

                    String fDir = Path.GetDirectoryName(fName);
                    if (!Directory.Exists(fDir))
                    {
                        Directory.CreateDirectory(fDir);
                    }
                    FileInfo outF = new FileInfo(fName);
                    StreamWriter w = new StreamWriter(outF.Create());
                    JavaPrettyPrinter writer = new JavaPrettyPrinter();
                    writer.compilationUnit(netTx.getAST(), w, enumXmlWriter, filter, emitTranslationDate);
                    w.Close();

                }

                double elapsedTime = ((DateTime.Now.Ticks - startTime) / TimeSpan.TicksPerMillisecond) / 1000.0;
                //System.Console.Out.WriteLine(writer.ToString());
                System.Console.Out.WriteLine("");
                System.Console.Out.WriteLine("");
                System.Console.Out.WriteLine("Pretty-printed {0} in: {1} seconds.", f, elapsedTime);
            }
		}
	}

	class LoggingTokenStream : TokenStream
	{
		TokenStream source;

		public LoggingTokenStream(TokenStream source)
		{
			this.source = source;
		}

		public IToken nextToken()
		{
			IToken tok = source.nextToken();
			if (tok != null)
				Console.Out.WriteLine(tok.ToString());

			return tok;
		}
	}
}
