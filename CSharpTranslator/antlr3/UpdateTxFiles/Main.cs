using System;
using System.Collections.Generic;
using System.IO;
using NDesk.Options;
using RusticiSoftware.Translator.CLR;
using RusticiSoftware.Translator.Utils;
using System.Xml.Serialization;
using RusticiSoftware.Translator;
using OldT = RusticiSoftware.Translator.TypeRepTemplate;
using NewT = RusticiSoftware.Translator.CLR.TypeRepTemplate;

namespace UpdateTxFiles
{
	class MainClass
	{
		
        private const string VERSION = "2010.1.1";
		private static int Verbosity = 0;
		private static DirectoryHT<OldT> oldAppEnv = new DirectoryHT<OldT>(null);
		private static DirectoryHT<OldT> newAppEnv = new DirectoryHT<OldT>(null);
		
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
            Console.Out.WriteLine(" [-inxmldir <root of old .NET Framework Class Library translations>+]              (can be multiple directories, separated by semi-colons)");
            Console.Out.WriteLine(" [-outxmkdir <root of new .NET Framework Class Library translations>+]              ");
            Environment.Exit(0);
        }
		public static void Main (string[] args)
		{
            long startTime = DateTime.Now.Ticks;
            IList<string> remArgs = new List<string>();		
			IList<string> inDirs = new List<string>();
			string outDir = "";
			
            // Use a try/catch block for parser exceptions
            try
            {
                // if we have at least one command-line argument
                if (args.Length > 0)
                {
			
                    OptionSet p = new OptionSet ()
                        .Add ("v", v => Verbosity++)
                        .Add ("version", v => showVersion())
                        .Add ("help|h|?", v => showUsage())
                        .Add ("inxmldir=", dir => inDirs.Add(Path.Combine(Directory.GetCurrentDirectory(), dir)))
                        .Add ("outxmldir=", dir => outDir = Path.Combine(Directory.GetCurrentDirectory(), dir))
                        ;

                    remArgs = p.Parse (args);
                            
                    // Load .Net templates
                    foreach (string r in inDirs)
                        doFile(r, ".xml", addOldNetTranslation, null);

					UpdateTranslationTemplate tx = new UpdateTranslationTemplate();
					
					foreach (KeyValuePair<string,OldT> de in oldAppEnv)
                    {   
						// update translation template
						NewT txTemplate = tx.upgrade(de.Value);
						
						String xmlFName = Path.Combine(outDir,
                                                           ((string)de.Key).Replace('.', Path.DirectorySeparatorChar) + ".xml");       
						String xmlFDir = Path.GetDirectoryName(xmlFName);
						Console.WriteLine (xmlFName + ": " + de.Value.Java);
						
						if (!Directory.Exists(xmlFDir))
						{
							Directory.CreateDirectory(xmlFDir);
						}
						XmlSerializer s = new XmlSerializer(txTemplate.GetType());
						TextWriter w = new StreamWriter(xmlFName);
						s.Serialize(w, txTemplate);
						w.Close();
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
            if (Verbosity >= 1)
            {
                System.Console.Out.WriteLine("Total run time was {0} seconds.", elapsedTime);
            }
        }


        // Call processFile on all files below f that have the given extension 
        public static void doFile(string root, string ext, FileProcessor processFile, IList<string> excludes)
        {
            string canonicalPath = Path.GetFullPath(root);
            // If this is a directory, walk each file/dir in that directory
            if (excludes == null || !excludes.Contains(canonicalPath.ToLower()))
            {
                if (Directory.Exists(canonicalPath))
                {
                    string[] files = Directory.GetFileSystemEntries(canonicalPath);
                    for (int i = 0; i < files.Length; i++)
                        doFile(Path.Combine(canonicalPath, files[i]), ext, processFile, excludes);
                }
                else if ((Path.GetFileName(canonicalPath).Length > ext.Length) && canonicalPath.Substring(canonicalPath.Length - ext.Length).Equals(ext))
                {
                    if (Verbosity >= 2) Console.WriteLine("   " + canonicalPath);
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

        // Here's where we do the real work...
        public static void addOldNetTranslation(string fullName)
        {
            Stream s = new FileStream(fullName, FileMode.Open, FileAccess.Read);
            OldT t = OldT.newInstance(s);
            oldAppEnv[t.TypeName] = t;
        }
	}
}

