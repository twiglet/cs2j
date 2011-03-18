/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Reflection;
using System.IO;
using System.Xml.Serialization;
using System.Xml;
using System.Text;
using NDesk.Options;
using System.Collections.Generic;
using System.Security.Cryptography;
using System.Security.Cryptography.Xml;

namespace Twiglet.CS2J.Utility
{
    public class TemplateSigner
    {
        private const string CS2JSIGNER_VERSION = "pre-release";
        private int Verbose { get; set; }
        public delegate void FileProcessor(string fName);
        private List<string> XmlDirs { get; set; }
        private List<string> ExcludeXmlDirs { get; set; }
		private String KeyFile = null;
		RSACryptoServiceProvider RsaKey { get; set; }

        public TemplateSigner()
        {
            Verbose = 0;
            XmlDirs = new List<string>();
            ExcludeXmlDirs = new List<string>();
            RsaKey = null;
        }

        private static void printUsageAndExit()
        {
            Console.Out.WriteLine("Usage: " + Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]) + " <type to dump, if not given dump all>");
            Console.Out.WriteLine(" [-version]                                            (show version information)");
            Console.Out.WriteLine(" [-help|h|?]                                           (this usage message)");
            Console.Out.WriteLine(" [-v]                                                  (be [somewhat more] verbose, repeat for more verbosity)");
            Console.Out.WriteLine(" [-privkeyfile <path to rsa private key file           (xml format)");
            Console.Out.WriteLine(" [-xmlpath <a root of xml files to be signed>]         (can be multiple directories, separated by semi-colons)");
            Console.Out.WriteLine(" [-exxmlpath <directories/files to be excluded from signing>] (can be multiple directories/files, separated by semi-colons)");
            Console.Out.WriteLine(" [<root of xml files to be signed>]                     (can be multiple directories, separated by semi-colons)");
            Environment.Exit(0);
        }

        private static void printVersion()
        {
            Console.Out.WriteLine(Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]));
            Console.WriteLine("Version: {0}", CS2JSIGNER_VERSION);
        }

        private static void addDirectories(IList<string> strs, string rawStr)
        {
            string[] argDirs = rawStr.Split(';');
            for (int i = 0; i < argDirs.Length; i++)
                strs.Add(Path.GetFullPath(argDirs[i]));
        }


        public static void Main(string[] args)
        {

            TemplateSigner templateSigner = new TemplateSigner();
            List<string> xmlDirs = new List<string>();
            List<string> excludeXmlDirs = new List<string>();
            OptionSet p = new OptionSet()
                .Add("v", v => templateSigner.Verbose++)
                .Add("version", v => printVersion())
                .Add("help|h|?", v => printUsageAndExit())
                .Add("keyfile=", fname => templateSigner.KeyFile = Path.GetFullPath(fname))
                .Add("xmlpath=", dirs => addDirectories(xmlDirs, dirs))
                .Add("exxmlpath=", dirs => addDirectories(excludeXmlDirs, dirs))
                ;
            List<string> leftovers = p.Parse(args);
            if (leftovers != null)
            {
                foreach (string d in leftovers)
                {
                    addDirectories(xmlDirs, d);
                }
            }
            templateSigner.XmlDirs = xmlDirs;
            templateSigner.ExcludeXmlDirs = excludeXmlDirs;
			if (!File.Exists(templateSigner.KeyFile)) {
				Console.Out.WriteLine("Error: RSA key at '" + templateSigner.KeyFile + "' not found, aborting.");
				Environment.Exit(1);
			}
            templateSigner.SignXmlFiles();
        }

        public void SignXmlFiles() {
            try 
            {
				XmlReader reader =  XmlReader.Create(KeyFile);
				reader.MoveToContent();

                // Create a new CspParameters object to specify
                // a key container.
                CspParameters cspParams = new CspParameters();
                cspParams.KeyContainerName = "XML_DSIG_RSA_KEY";

                // Initialise from . 
                RsaKey = new RSACryptoServiceProvider(cspParams);
				RsaKey.PersistKeyInCsp = false;
				RsaKey.FromXmlString(reader.ReadOuterXml());
				
                // Load .Net templates
                if (XmlDirs != null)
                {
                    foreach (string r in XmlDirs)
                        doFile(r, ".xml", SignNetTranslation, ExcludeXmlDirs);
                }

            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
            }
        }

        private void SignNetTranslation(string filePath)
        {
            // Create a new XML document.
            XmlDocument xmlDoc = new XmlDocument();

            // Load an XML file into the XmlDocument object.
            xmlDoc.PreserveWhitespace = true;
            xmlDoc.Load(filePath);

            // Sign the XML document. 
            SignXml(xmlDoc, RsaKey);

            Console.WriteLine("XML file signed.");

            // Save the document.
            xmlDoc.Save(filePath);

        }


        // Sign an XML file. 
        // This document cannot be verified unless the verifying 
        // code has the key with which it was signed.
        private void SignXml(XmlDocument xmlDoc, RSA Key)
        {
            // Check arguments.
            if (xmlDoc == null)
                throw new ArgumentException("xmlDoc");
            if (Key == null)
                throw new ArgumentException("Key");
			
			// Add the namespace.
			XmlNamespaceManager nsmgr = new XmlNamespaceManager(xmlDoc.NameTable);				
			nsmgr.AddNamespace("ss", "http://www.w3.org/2000/09/xmldsig#");

			// Remove any existing signature(s)
			XmlNode root = xmlDoc.DocumentElement;
			XmlNodeList nodeList = root.SelectNodes("/*/ss:Signature", nsmgr);
            for (int i = nodeList.Count - 1; i >= 0; i--)
            {
                nodeList[i].ParentNode.RemoveChild(nodeList[i]);
            }
			// Create a SignedXml object.
            SignedXml signedXml = new SignedXml(xmlDoc);
			
			
            // Add the key to the SignedXml document.
            signedXml.SigningKey = Key;

            // Create a reference to be signed.
            Reference reference = new Reference();
            reference.Uri = "";

            // Add an enveloped transformation to the reference.
            XmlDsigEnvelopedSignatureTransform env = new XmlDsigEnvelopedSignatureTransform();
            reference.AddTransform(env);

            // Add the reference to the SignedXml object.
            signedXml.AddReference(reference);

            // Compute the signature.
            signedXml.ComputeSignature();

            // Get the XML representation of the signature and save
            // it to an XmlElement object.
            XmlElement xmlDigitalSignature = signedXml.GetXml();

            // Append the element to the XML document.
            xmlDoc.DocumentElement.AppendChild(xmlDoc.ImportNode(xmlDigitalSignature, true));

        }

        // Call processFile on all files below f that have the given extension 
        private void doFile(string root, string ext, FileProcessor processFile, IList<string> excludes)
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
                    if (Verbose >= 2) Console.WriteLine("   " + canonicalPath);
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

    }
}

