using System;
using Path = System.IO.Path;
using Antlr.Runtime;

namespace RusticiSoftware.Translator.CSharp
{
    public class Driver
    {
        public static void Main(string[] args)
        {
            if (args.Length > 0 && args[0].ToLower() == "-mindriver")
            {
                MinDriver.MinDriverMain(args);
            }
            else
            {
                CS2J.CS2JMain(args);
            }
        }
    }
}