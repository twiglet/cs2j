using System;
namespace Tester.RefOut
{
	public class RefOutTest
	{
		public RefOutTest ()
		{
		}
		
		public void testref (ref int xarg)
		{
			int x = xarg;
			x++;
			xarg = 23;
			throw new Exception();
		}

		void FillArray(out int[] arr)
    	{
        	// Initialize the array:
        	arr = new int[5] { 1, 2, 3, 4, 5 };
    	}
		
		public void Init (string[] args)
		{
			
			int localx = 5;
			try {
                           
				if(true)
					testref (ref localx);
			} catch (Exception) {
				//
			}
			finally {
				Console.Out.WriteLine ("The x is {0}", localx);
			}

		    int[] theArray; // Initialization is not required

        	// Pass the array to the callee using out:
        	FillArray(out theArray);

        	// Display the array elements:
        	System.Console.WriteLine("Array elements are:");
        	for (int i = 0; i < theArray.Length; i++)
        	{
            	System.Console.Write(theArray[i] + " ");
        	}

		}
		    
		public static void RefOutMain (string[] args)
		{
			new RefOutTest ().Init (args);
		}
	}

	class TC {

            public TC() {}

            public bool TCtest1(out string modifiedUrlString, string urlString){
	        modifiedUrlString = urlString.ToUpper();
		return false;
	    }

            public bool TCtest2(out string user, out string passwd, string urlString){
	        user = urlString.ToUpper();
	        passwd = urlString.ToLower();
		return true;
	    }


            public void TCtest(string urlString)
            {
    
                string modifiedUrlString=null;
                string engineAuthUser=null;
                string engineAuthPassword=null;
    
                if (TCtest1(out modifiedUrlString, urlString))
                {
                    System.Console.WriteLine(modifiedUrlString);
                }
                else if (TCtest2(out engineAuthUser, out engineAuthPassword, urlString))
                {
                    if (!String.IsNullOrEmpty(engineAuthUser) && !String.IsNullOrEmpty(engineAuthPassword))
                    {
                        System.Console.WriteLine(engineAuthUser + engineAuthPassword);
                    }
                    else
                    {
                        System.Console.WriteLine("Null or Null");
                    }
                }
                else
                {
    	        System.Console.WriteLine("They really didn't like us");
                }
    	    }

            public void TCtest_workaround(string urlString)
            {
    
                string modifiedUrlString=null;
                string engineAuthUser=null;
                string engineAuthPassword=null;
    
		bool optTCTest1 = TCtest1(out modifiedUrlString, urlString);
                if (optTCTest1)
                {
                    System.Console.WriteLine(modifiedUrlString);
                }
                else {
		    bool optTCTest2 = TCtest2(out engineAuthUser, out engineAuthPassword, urlString);
		    if (optTCTest2)
                    {
			if (!String.IsNullOrEmpty(engineAuthUser) && !String.IsNullOrEmpty(engineAuthPassword))
                    	{
				System.Console.WriteLine(engineAuthUser + engineAuthPassword);
                    	}
                    	else
                    	{
				System.Console.WriteLine("Null or Null");
                    	}
		    }
                    else
                    {
    	                System.Console.WriteLine("They really didn't like us");
                    }
               }
    	    }
        }
}

