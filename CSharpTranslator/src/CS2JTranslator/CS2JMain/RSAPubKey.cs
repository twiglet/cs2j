/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Text;

namespace Twiglet.CS2J.Translator
{
    public class RSAPubKey
    {

        private static string _key = @"
<RSAKeyValue>
  <Modulus>iTXgwMVsIk25/pstsBVNNVONs5Q4haeikef5YcRBuTh6slndGs5cj7h0LSHRqPNesp3EwVmwJYY11bDkutN1+rzs9EH3X4vJI6SKgKEHDi5ZV1kfZ8eA3xos8TKNvE4WK33+0ZmZJYkL0sknFyEOIGVmk/OiAlsriNZ7NeerWuU=</Modulus>
  <Exponent>EQ==</Exponent>
</RSAKeyValue>
";

	public static string PubKey { 
			get    
			{ 	
				string[] xx = _key.Split(new Char[] { '<','>' });
                if (xx.Length != 13)
                   throw new ArgumentException("Signing Key is malformed");
				xx[4] = new RSAPubKey().furl(xx[4].ToCharArray());
				StringBuilder yy = new StringBuilder(xx[0]);
				for (int i = 1; i < xx.Length; i+=2) {
					yy.Append("<");
					yy.Append(xx[i]);
					yy.Append(">");
					yy.Append(xx[i+1]);
				}
				return yy.ToString();
			}
        }

       private string
		furl(Char[] key)
       {
		  Char zz = key[7];
		  key[7] = key[21];
		  key[21] = zz;
		  zz = key[key.Length - 7];
		  key[key.Length - 7] = key[key.Length - 21];
		  key[key.Length - 21] = zz;
		  
          return new String(key);
          
       }
    }
}
