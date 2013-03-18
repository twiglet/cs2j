/*
   Copyright 2010-2013 Kevin Glynn (kevin.glynn@twigletsoftware.com)
   Copyright 2007-2013 Rustici Software, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
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