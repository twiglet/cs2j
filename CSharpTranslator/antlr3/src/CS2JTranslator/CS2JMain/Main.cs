/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using Path = System.IO.Path;
using Antlr.Runtime;

namespace Twiglet.CS2J.Translator
{
    public class Driver
    {
        public static void Main(string[] args)
        {
            if (args.Length > 0 && args[0].ToLower() == "-mindriver")
            {
                Console.Out.WriteLine("sorry, mindriver not implemented");
                //MinDriver.MinDriverMain(args);
            }
            else
            {
                CS2J.CS2JMain(args);
            }
        }
    }
}