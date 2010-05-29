namespace RusticiSoftware.Translator.CSharp
{
    using System;
    using Path = System.IO.Path;
    using Antlr.Runtime;

    public class Driver
    {
        public static void Main(string[] args)
        {
            if (args[0].ToLower() == "-mindriver")
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