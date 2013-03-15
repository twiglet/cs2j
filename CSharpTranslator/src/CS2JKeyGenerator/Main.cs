/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Reflection;
using System.IO;
using System.Text;
using NDesk.Options;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Xml;


namespace Twiglet.CS2J.Utility
{
    public class KeyGenerator
    {
        private const string CS2JKEYGEN_VERSION = "pre-release";

        private static void printUsageAndExit()
        {
            Console.Out.WriteLine("Usage: " + Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]) + " <type to dump, if not given dump all>");
            Console.Out.WriteLine(" [-version]                                            (show version information)");
            Console.Out.WriteLine(" [-help|h|?]                                           (this usage message)");
            Console.Out.WriteLine(" [-v]                                                  (be [somewhat more] verbose, repeat for more verbosity)");
            Console.Out.WriteLine(" [-keypath <directory>]                                (directory to place the key files)");
            Console.Out.WriteLine(" [-keyname <name>]                                     (name of this key pair, used to name the key files)");
            Environment.Exit(0);
        }

        private static void printVersion()
        {
            Console.Out.WriteLine(Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]));
            Console.WriteLine("Version: {0}", CS2JKEYGEN_VERSION);
        }

        public static void Main(string[] args)
        {
			int Verbose = 0;
        	RSACryptoServiceProvider RsaKey = null;
			string KeyPath = Directory.GetCurrentDirectory();
			string KeyName = "rsakey"; 
            OptionSet p = new OptionSet()
                .Add("v", v => Verbose++)
                .Add("version", v => printVersion())
                .Add("help|h|?", v => printUsageAndExit())
                .Add("keypath=", dir => KeyPath = Path.GetFullPath(dir))
                .Add("keyname=", name => KeyName = name)
                ;
 		
			p.Parse(args);

            try 
            {
                // Create a new CspParameters object to specify
                // a key container.
                CspParameters cspParams = new CspParameters();
                cspParams.KeyContainerName = "XML_DSIG_RSA_KEY";

                // Create a new RSA signing key and save it in the container. 
                RsaKey = new RSACryptoServiceProvider(cspParams);
				
				// We don't want to store the key in the csp, and also we don't want to get the same key 
				// each time. 
				RsaKey.PersistKeyInCsp = false;

                if (!Directory.Exists(KeyPath))
                {
                    Directory.CreateDirectory(KeyPath);
                }

				XmlWriterSettings set = new XmlWriterSettings();
				set.Indent = true;
				set.Encoding = Encoding.UTF8;
				
				// Write public key info
				XmlWriter xw = XmlWriter.Create(Path.Combine(KeyPath, KeyName + "_pub.xml"), set);
				
				XmlReader reader =  XmlReader.Create(new StringReader(RsaKey.ToXmlString(false)));
				
				xw.WriteNode(reader, true);
				xw.Close();

				// Write public/private key info
				xw = XmlWriter.Create(Path.Combine(KeyPath, KeyName + "_priv.xml"), set);
				
				reader =  XmlReader.Create(new StringReader(RsaKey.ToXmlString(true)));
				
				xw.WriteNode(reader, true);
				xw.Close();

				                      
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }
    }
}

