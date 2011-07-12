using System;
namespace Tester.Misc
{
   public class Misc
   {
      public Misc ()
      {
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

