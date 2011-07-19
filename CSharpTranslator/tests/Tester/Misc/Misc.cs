using System;
using System.Collections.Generic;
namespace Tester.Misc
{
	
   public class Misc
   {
      public Misc ()
      {
      }
		
				
	  public void GroupConfiguration(IEnumerable<Misc> groups)
	  {
		 IList<Misc> Groups = new List<Misc>(groups);
	  }
		
      private int TestProperty
      {
         get;set;
      }
		    
      public void Init (string[] args)
      {
         // Test incrementing a property
         TestProperty = 0;
         TestProperty++;
      }
   }
}

