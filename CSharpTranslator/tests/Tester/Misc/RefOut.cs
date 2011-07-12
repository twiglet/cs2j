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
}

