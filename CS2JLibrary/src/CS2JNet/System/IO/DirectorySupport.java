/*
   Copyright 2007,2008,2009,2010 Rustici Software, LLC
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Author(s):

   Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

package CS2JNet.System.IO;

import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.regex.Pattern;

public class DirectorySupport {

	// Support for patterns containing ? and * characters.  . 
	private static String globToRegex(String filePattern) {
		
		StringBuilder ret = new StringBuilder();
		// remember start of current literal sequence
		int litStart = 0;
		for (int i = 0; i < filePattern.length(); i++)
		{
			char c = filePattern.charAt(i);
			if (c == '*')
			{
				if (litStart < i) {
					ret.append(Pattern.quote(filePattern.substring(litStart, i)));
				}
				litStart = i + 1;
				ret.append(".*");
			}
			else if (c == '?')
			{
				if (litStart < i) {
					ret.append(Pattern.quote(filePattern.substring(litStart, i)));
				}
				litStart = i + 1;
				ret.append('.');
			}
		}
		if (litStart < filePattern.length()) {
			ret.append(Pattern.quote(filePattern.substring(litStart, filePattern.length())));
		}
		return ret.toString();
	}

	   // This filter only returns files
    private static FilenameFilter fileFilter = new FilenameFilter() {
        public boolean accept(File dir, String file) {
            return new File(dir, file).isFile();
        }
    };	
    
	   // This filter only returns files
    private static FilenameFilter fileFilter(String filePattern) {
       	final String globPattern = globToRegex(filePattern);
    	return new FilenameFilter() {
            public boolean accept(File dir, String file) {
            	boolean isFile = new File(dir, file).isFile();
            	boolean isMatch = file.matches(globPattern);
                return isFile && isMatch;
            }
    	};
    }	
    
    // This filter only returns directories
    private static FilenameFilter dirFilter = new FilenameFilter() {
        public boolean accept(File dir, String file) {
            return new File(dir, file).isDirectory();
        }
    };
 
	   // This filter only returns files
    private static FilenameFilter dirFilter(String filePattern) {
    	final String globPattern = globToRegex(filePattern);
    	return new FilenameFilter() {
            public boolean accept(File dir, String file) {
            	boolean isDir = new File(dir, file).isDirectory();
            	boolean isMatch = file.matches(globPattern);
                return isDir && isMatch;
            }

    	};
    }	

	// Implementation of Directory.GetFiles(path)
	public static String[] getFiles(String path) throws IOException
	{
		File[] allFiles = new File(path).listFiles(DirectorySupport.fileFilter);
		
		String[] allFilePaths = new String[allFiles.length];
		
		for (int i = 0; i < allFilePaths.length; i++) {
			allFilePaths[i] = allFiles[i].getAbsolutePath();
		}
		
		return allFilePaths;
		
	}

	// Implementation of Directory.GetFiles(path,searchpattern)
	public static String[] getFiles(String path, String searchpattern) throws IOException
	{
		// In .Net Directory.GetFiles, if the searchpattern contains directory path separators
		// then it will search subdirs.
		
		ArrayList<String> allMatches = new ArrayList<String>();

		// we split on both / and \ characters
		String[] patternComponents = searchpattern.split("[/\\\\]",2); 
		
		if (patternComponents.length > 1) {
			File[] matchDirs = new File(path).listFiles(DirectorySupport.dirFilter(patternComponents[0]));
			for (File d : matchDirs)
			{
				allMatches.addAll(Arrays.asList(getFiles(d.getAbsolutePath(),patternComponents[1])));
			}
			
		}
		else
		{
			File[] allFiles = new File(path).listFiles(DirectorySupport.fileFilter(searchpattern));

			
			for (int i = 0; i < allFiles.length; i++)
			{
				allMatches.add(i,((File)allFiles[i]).getAbsolutePath());
			}
		}
		
		return allMatches.toArray(new String[allMatches.size()]);
		
	}

	// Implementation of Directory.GetDirectories()
	public static String[] getDirectories(String path) throws IOException
	{

		File[] allDirs = new File(path).listFiles(DirectorySupport.dirFilter);
		
		String[] allDirPaths = new String[allDirs.length];
		
		for (int i = 0; i < allDirPaths.length; i++) {
			allDirPaths[i] = allDirs[i].getAbsolutePath();
		}
		
		return allDirPaths;
	}

	// Implementation of Directory.Delete)
	public static void delete(String path, boolean recursive) throws IOException
	{
		File dp = new File(path);
		if (!dp.isDirectory())
			throw new IOException("Directory expected");
		
		if (recursive)
		{
			String[] children = dp.list();
            for (int i=0; i<children.length; i++) {
                File child = new File(dp, children[i]);
                if (child.isDirectory())
                	DirectorySupport.delete(child.getPath(), true);
                else
                	child.delete();
            }
		}
		else
			// Will fail if not writeable, empty
			dp.delete();
	}

	public static void main(String[] args) throws IOException
	{
//		String[] entries = getFiles("/Users/keving","Documents/?*.*");
//		for (String s : entries) {
//			System.out.println(s);
//		}
		String[] entries = {"","/Users/keving","Documents/?*.*", "{45345435}.jpg"};
		for (String s : entries) {
			System.out.println(globToRegex(s));
		}
		
	}
}
