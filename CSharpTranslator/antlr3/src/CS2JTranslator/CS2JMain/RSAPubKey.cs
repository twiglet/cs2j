/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;

namespace Twiglet.CS2J.Translator
{
    public class RSAPubKey
    {

        private static string _key = @"
<RSAKeyValue>
  <Modulus>iTXgwMVVIk25/pstsBVNNsONs5Q4haeikef5YcRBuTh6slndGs5cj7h0LSHRqPNesp3EwVmwJYY11bDkutN1+rzs9EH3X4vJI6SKgKEHDi5ZV1kfZ8eA3xos8TKNvE4WK33+0ZmZJYkL0sknFyEOIGVek/OiAlsriNZ7NmerWuU=</Modulus>
  <Exponent>EQ==</Exponent>
</RSAKeyValue>
";

	public static string PubKey { get
                { return _key; }
        }
    }
}
